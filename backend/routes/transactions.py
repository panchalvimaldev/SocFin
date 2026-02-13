from fastapi import APIRouter, HTTPException, Depends, UploadFile, File, Query
from database import db
from auth_utils import get_current_user
from models import TransactionCreate, TransactionResponse
import uuid
from datetime import datetime, timezone
import os
import shutil

router = APIRouter(prefix="/api/societies/{society_id}/transactions", tags=["Transactions"])

UPLOAD_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)

INWARD_CATEGORIES = [
    "Maintenance Payment", "Donation", "Interest Income",
    "Parking Charges", "Penalty/Fine", "Other Income",
]
OUTWARD_CATEGORIES = [
    "Security Salary", "Lift AMC", "Repairs & Maintenance",
    "Electricity Bill", "Water Bill", "Vendor Payment",
    "Garden Maintenance", "Insurance", "Legal Fees",
    "Cleaning", "Other Expense",
]


async def _verify_membership(user_id, society_id, roles=None):
    q = {"user_id": user_id, "society_id": society_id, "status": "active"}
    m = await db.memberships.find_one(q, {"_id": 0})
    if not m:
        raise HTTPException(status_code=403, detail="Not a member of this society")
    if roles and m["role"] not in roles:
        raise HTTPException(status_code=403, detail="Insufficient permissions")
    return m


@router.get("/categories")
async def get_categories():
    return {"inward": INWARD_CATEGORIES, "outward": OUTWARD_CATEGORIES}


@router.get("/", response_model=list[TransactionResponse])
async def list_transactions(
    society_id: str,
    type: str = None,
    category: str = None,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    current_user: dict = Depends(get_current_user),
):
    await _verify_membership(current_user["sub"], society_id)
    query = {"society_id": society_id}
    if type:
        query["type"] = type
    if category:
        query["category"] = category

    skip = (page - 1) * limit
    txns = await db.transactions.find(query, {"_id": 0}).sort("created_at", -1).skip(skip).to_list(limit)

    result = []
    for t in txns:
        user = await db.users.find_one({"id": t["created_by"]}, {"_id": 0})
        result.append(TransactionResponse(
            **t,
            created_by_name=user["name"] if user else "",
        ))
    return result


@router.get("/count")
async def count_transactions(
    society_id: str,
    type: str = None,
    category: str = None,
    current_user: dict = Depends(get_current_user),
):
    await _verify_membership(current_user["sub"], society_id)
    query = {"society_id": society_id}
    if type:
        query["type"] = type
    if category:
        query["category"] = category
    count = await db.transactions.count_documents(query)
    return {"count": count}


@router.post("/", response_model=TransactionResponse)
async def create_transaction(
    society_id: str,
    data: TransactionCreate,
    current_user: dict = Depends(get_current_user),
):
    await _verify_membership(current_user["sub"], society_id, ["manager"])
    now = datetime.now(timezone.utc).isoformat()
    txn_id = str(uuid.uuid4())

    # Check approval threshold for outward
    approval_status = "approved"
    if data.type == "outward":
        soc = await db.societies.find_one({"id": society_id}, {"_id": 0})
        threshold = soc.get("approval_threshold", 50000) if soc else 50000
        if data.amount >= threshold:
            approval_status = "pending"

    txn_doc = {
        "id": txn_id,
        "society_id": society_id,
        "type": data.type,
        "category": data.category,
        "amount": data.amount,
        "description": data.description,
        "vendor_name": data.vendor_name,
        "payment_mode": data.payment_mode,
        "invoice_path": data.invoice_path,
        "date": data.date or now[:10],
        "created_by": current_user["sub"],
        "created_at": now,
        "approval_status": approval_status,
    }
    await db.transactions.insert_one(txn_doc)

    # Create approval request if pending
    if approval_status == "pending":
        appr_id = str(uuid.uuid4())
        await db.approvals.insert_one({
            "id": appr_id,
            "transaction_id": txn_id,
            "society_id": society_id,
            "requested_by": current_user["sub"],
            "status": "pending",
            "approved_by": "",
            "comments": "",
            "created_at": now,
        })
        # Notify committee members
        committee = await db.memberships.find(
            {"society_id": society_id, "role": "committee", "status": "active"}, {"_id": 0}
        ).to_list(100)
        for cm in committee:
            await db.notifications.insert_one({
                "id": str(uuid.uuid4()),
                "society_id": society_id,
                "user_id": cm["user_id"],
                "title": "Expense Approval Required",
                "message": f"New expense of Rs.{data.amount:,.0f} for {data.category} needs approval",
                "type": "approval",
                "read": False,
                "created_at": now,
            })

    return TransactionResponse(
        **{k: v for k, v in txn_doc.items() if k != "_id"},
        created_by_name=current_user.get("name", ""),
    )


@router.get("/{txn_id}", response_model=TransactionResponse)
async def get_transaction(society_id: str, txn_id: str, current_user: dict = Depends(get_current_user)):
    await _verify_membership(current_user["sub"], society_id)
    txn = await db.transactions.find_one({"id": txn_id, "society_id": society_id}, {"_id": 0})
    if not txn:
        raise HTTPException(status_code=404, detail="Transaction not found")
    user = await db.users.find_one({"id": txn["created_by"]}, {"_id": 0})
    return TransactionResponse(**txn, created_by_name=user["name"] if user else "")


# ─── File Upload ─────────────────────────────────────
@router.post("/upload")
async def upload_invoice(society_id: str, file: UploadFile = File(...),
                         current_user: dict = Depends(get_current_user)):
    await _verify_membership(current_user["sub"], society_id, ["manager"])
    ext = os.path.splitext(file.filename)[1]
    filename = f"{uuid.uuid4()}{ext}"
    filepath = os.path.join(UPLOAD_DIR, filename)
    with open(filepath, "wb") as f:
        shutil.copyfileobj(file.file, f)
    return {"filename": filename, "path": f"/api/uploads/{filename}"}
