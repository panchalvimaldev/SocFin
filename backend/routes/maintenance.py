from fastapi import APIRouter, HTTPException, Depends, Query
from database import db
from auth_utils import get_current_user
from models import GenerateBillsRequest, MaintenanceBillResponse, RecordPaymentRequest
import uuid
from datetime import datetime, timezone

router = APIRouter(prefix="/api/societies/{society_id}/maintenance", tags=["Maintenance"])


async def _verify(user_id, society_id, roles=None):
    q = {"user_id": user_id, "society_id": society_id, "status": "active"}
    m = await db.memberships.find_one(q, {"_id": 0})
    if not m:
        raise HTTPException(status_code=403, detail="Not a member")
    if roles and m["role"] not in roles:
        raise HTTPException(status_code=403, detail="Insufficient permissions")
    return m


@router.post("/generate")
async def generate_bills(society_id: str, data: GenerateBillsRequest,
                         current_user: dict = Depends(get_current_user)):
    await _verify(current_user["sub"], society_id, ["manager"])

    # Check if bills already generated for this month
    existing = await db.maintenance_bills.find_one(
        {"society_id": society_id, "month": data.month, "year": data.year}, {"_id": 0}
    )
    if existing:
        raise HTTPException(status_code=400, detail="Bills already generated for this month")

    flats = await db.flats.find({"society_id": society_id}, {"_id": 0}).to_list(1000)
    now = datetime.now(timezone.utc).isoformat()
    bills_created = 0

    for flat in flats:
        # Find primary member
        primary = await db.flat_members.find_one(
            {"flat_id": flat["id"], "society_id": society_id, "is_primary": True}, {"_id": 0}
        )
        member_id = primary["user_id"] if primary else ""

        bill_id = str(uuid.uuid4())
        bill_doc = {
            "id": bill_id,
            "society_id": society_id,
            "flat_id": flat["id"],
            "flat_number": flat["flat_number"],
            "member_id": member_id,
            "month": data.month,
            "year": data.year,
            "amount": data.amount_per_flat,
            "due_date": data.due_date,
            "late_fee": data.late_fee,
            "status": "pending",
            "paid_amount": 0,
            "created_at": now,
        }
        await db.maintenance_bills.insert_one(bill_doc)
        bills_created += 1

        # Notify the member
        if member_id:
            await db.notifications.insert_one({
                "id": str(uuid.uuid4()),
                "society_id": society_id,
                "user_id": member_id,
                "title": "Maintenance Bill Generated",
                "message": f"Your maintenance bill of Rs.{data.amount_per_flat:,.0f} for {data.month}/{data.year} is due on {data.due_date}",
                "type": "billing",
                "read": False,
                "created_at": now,
            })

    return {"status": "success", "bills_created": bills_created}


@router.get("/bills", response_model=list[MaintenanceBillResponse])
async def list_bills(
    society_id: str,
    month: int = None,
    year: int = None,
    status: str = None,
    flat_id: str = None,
    page: int = Query(1, ge=1),
    limit: int = Query(50, ge=1, le=200),
    current_user: dict = Depends(get_current_user),
):
    membership = await _verify(current_user["sub"], society_id)
    query = {"society_id": society_id}

    # Members can only see their own bills
    if membership["role"] == "member":
        query["member_id"] = current_user["sub"]

    if month:
        query["month"] = month
    if year:
        query["year"] = year
    if status:
        query["status"] = status
    if flat_id:
        query["flat_id"] = flat_id

    skip = (page - 1) * limit
    bills = await db.maintenance_bills.find(query, {"_id": 0}).sort("created_at", -1).skip(skip).to_list(limit)

    result = []
    for b in bills:
        member_name = ""
        if b.get("member_id"):
            user = await db.users.find_one({"id": b["member_id"]}, {"_id": 0})
            member_name = user["name"] if user else ""
        result.append(MaintenanceBillResponse(**b, member_name=member_name))
    return result


@router.post("/pay")
async def record_payment(society_id: str, data: RecordPaymentRequest,
                         current_user: dict = Depends(get_current_user)):
    await _verify(current_user["sub"], society_id, ["manager"])

    bill = await db.maintenance_bills.find_one({"id": data.bill_id}, {"_id": 0})
    if not bill:
        raise HTTPException(status_code=404, detail="Bill not found")

    new_paid = bill.get("paid_amount", 0) + data.amount_paid
    new_status = "paid" if new_paid >= bill["amount"] else "partial"

    await db.maintenance_bills.update_one(
        {"id": data.bill_id},
        {"$set": {"paid_amount": new_paid, "status": new_status}},
    )

    # Create inward transaction
    now = datetime.now(timezone.utc).isoformat()
    txn_id = str(uuid.uuid4())
    await db.transactions.insert_one({
        "id": txn_id,
        "society_id": society_id,
        "type": "inward",
        "category": "Maintenance Payment",
        "amount": data.amount_paid,
        "description": f"Maintenance payment for flat {bill.get('flat_number', '')} - {bill['month']}/{bill['year']}",
        "vendor_name": "",
        "payment_mode": data.payment_mode,
        "invoice_path": "",
        "date": now[:10],
        "created_by": current_user["sub"],
        "created_at": now,
        "approval_status": "approved",
    })

    return {"status": new_status, "paid_amount": new_paid, "transaction_id": txn_id}


@router.get("/ledger/{flat_id}")
async def get_flat_ledger(society_id: str, flat_id: str, current_user: dict = Depends(get_current_user)):
    await _verify(current_user["sub"], society_id)
    bills = await db.maintenance_bills.find(
        {"society_id": society_id, "flat_id": flat_id}, {"_id": 0}
    ).sort("year", -1).sort("month", -1).to_list(100)
    return bills
