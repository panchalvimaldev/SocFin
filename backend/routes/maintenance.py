from fastapi import APIRouter, HTTPException, Depends, Query
from fastapi.responses import StreamingResponse
from database import db
from auth_utils import get_current_user
from models import (
    MaintenanceSettingsCreate, MaintenanceSettingsResponse,
    DiscountSchemeCreate, DiscountSchemeResponse,
    GenerateBillsRequest, MaintenanceBillResponse, BillPreviewResponse,
    RecordPaymentRequest, PaymentResponse, ReceiptResponse,
    LedgerEntryResponse, LedgerSummaryResponse,
    AnnualPaymentPreviewRequest, AnnualPaymentPreviewResponse,
    CollectionDashboardResponse,
)
import uuid
from datetime import datetime, timezone, timedelta
from typing import Optional
import io

router = APIRouter(prefix="/api/societies/{society_id}/maintenance", tags=["Maintenance"])


# ═══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

async def _verify(user_id: str, society_id: str, roles: list = None):
    """Verify user membership and optionally check role."""
    q = {"user_id": user_id, "society_id": society_id, "status": "active"}
    m = await db.memberships.find_one(q, {"_id": 0})
    if not m:
        raise HTTPException(status_code=403, detail="Not a member of this society")
    if roles and m["role"] not in roles:
        raise HTTPException(status_code=403, detail="Insufficient permissions")
    return m


async def _get_or_create_settings(society_id: str) -> dict:
    """Get society maintenance settings, create default if not exists."""
    settings = await db.maintenance_settings.find_one({"society_id": society_id}, {"_id": 0})
    if not settings:
        settings = {
            "id": str(uuid.uuid4()),
            "society_id": society_id,
            "default_rate_per_sqft": 5.0,
            "billing_cycle": "monthly",
            "due_date_day": 10,
            "late_fee_amount": 0,
            "late_fee_type": "flat",
            "is_discount_scheme_enabled": True,
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }
        await db.maintenance_settings.insert_one(settings)
    return settings


async def _get_primary_member(flat_id: str, society_id: str) -> dict:
    """Get primary member of a flat."""
    fm = await db.flat_members.find_one(
        {"flat_id": flat_id, "society_id": society_id, "is_primary": True}, {"_id": 0}
    )
    if fm:
        user = await db.users.find_one({"id": fm["user_id"]}, {"_id": 0})
        return {"user_id": fm["user_id"], "user_name": user["name"] if user else ""}
    return {"user_id": "", "user_name": ""}


async def _calculate_bill_amount(area_sqft: float, rate_per_sqft: float, months: int = 1) -> float:
    """Calculate maintenance amount based on area."""
    return round(area_sqft * rate_per_sqft * months, 2)


async def _apply_discount(total_amount: float, scheme: dict) -> tuple[float, float]:
    """Apply discount scheme and return (discount_amount, final_amount)."""
    if not scheme or not scheme.get("is_active"):
        return 0, total_amount
    
    discount_type = scheme.get("discount_type", "free_months")
    
    if discount_type == "free_months":
        monthly = total_amount / scheme.get("eligible_months", 12)
        discount = monthly * scheme.get("free_months", 1)
    elif discount_type == "percentage":
        discount = total_amount * (scheme.get("discount_value", 0) / 100)
    else:  # flat
        discount = scheme.get("discount_value", 0)
    
    discount = round(discount, 2)
    final = round(total_amount - discount, 2)
    return discount, final


async def _create_ledger_entry(
    society_id: str, flat_id: str, user_id: str,
    entry_type: str, reference_id: str, reference_type: str,
    debit: float = 0, credit: float = 0, notes: str = ""
):
    """Create a ledger entry and calculate running balance."""
    # Get current balance
    last_entry = await db.member_ledger.find_one(
        {"society_id": society_id, "flat_id": flat_id},
        {"_id": 0}
    )
    if last_entry:
        entries = await db.member_ledger.find(
            {"society_id": society_id, "flat_id": flat_id}, {"_id": 0}
        ).sort("entry_date", -1).to_list(1)
        current_balance = entries[0]["balance_after_entry"] if entries else 0
    else:
        current_balance = 0
    
    new_balance = round(current_balance + debit - credit, 2)
    
    entry = {
        "id": str(uuid.uuid4()),
        "society_id": society_id,
        "flat_id": flat_id,
        "user_id": user_id,
        "entry_date": datetime.now(timezone.utc).isoformat(),
        "entry_type": entry_type,
        "reference_id": reference_id,
        "reference_type": reference_type,
        "debit_amount": debit,
        "credit_amount": credit,
        "balance_after_entry": new_balance,
        "notes": notes,
    }
    await db.member_ledger.insert_one(entry)
    return entry


async def _generate_receipt_number(society_id: str) -> str:
    """Generate unique receipt number."""
    count = await db.maintenance_payments.count_documents({"society_id": society_id})
    year = datetime.now(timezone.utc).year
    return f"RCP-{year}-{count + 1:05d}"


# ═══════════════════════════════════════════════════════════════════════════════
# MAINTENANCE SETTINGS
# ═══════════════════════════════════════════════════════════════════════════════

@router.get("/settings", response_model=MaintenanceSettingsResponse)
async def get_maintenance_settings(society_id: str, current_user: dict = Depends(get_current_user)):
    """Get society maintenance settings."""
    await _verify(current_user["sub"], society_id)
    settings = await _get_or_create_settings(society_id)
    return MaintenanceSettingsResponse(**settings)


@router.put("/settings", response_model=MaintenanceSettingsResponse)
async def update_maintenance_settings(
    society_id: str, data: MaintenanceSettingsCreate,
    current_user: dict = Depends(get_current_user)
):
    """Update society maintenance settings (Manager only)."""
    await _verify(current_user["sub"], society_id, ["manager"])
    
    settings = await _get_or_create_settings(society_id)
    
    update_data = {
        "default_rate_per_sqft": data.default_rate_per_sqft,
        "billing_cycle": data.billing_cycle,
        "due_date_day": data.due_date_day,
        "late_fee_amount": data.late_fee_amount,
        "late_fee_type": data.late_fee_type,
        "is_discount_scheme_enabled": data.is_discount_scheme_enabled,
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }
    
    await db.maintenance_settings.update_one(
        {"society_id": society_id}, {"$set": update_data}
    )
    
    settings.update(update_data)
    return MaintenanceSettingsResponse(**settings)


# ═══════════════════════════════════════════════════════════════════════════════
# DISCOUNT SCHEMES
# ═══════════════════════════════════════════════════════════════════════════════

@router.get("/discount-schemes", response_model=list[DiscountSchemeResponse])
async def list_discount_schemes(society_id: str, current_user: dict = Depends(get_current_user)):
    """List all discount schemes for a society."""
    await _verify(current_user["sub"], society_id)
    schemes = await db.discount_schemes.find({"society_id": society_id}, {"_id": 0}).to_list(100)
    return [DiscountSchemeResponse(**s) for s in schemes]


@router.post("/discount-schemes", response_model=DiscountSchemeResponse)
async def create_discount_scheme(
    society_id: str, data: DiscountSchemeCreate,
    current_user: dict = Depends(get_current_user)
):
    """Create a new discount scheme (Manager only)."""
    await _verify(current_user["sub"], society_id, ["manager"])
    
    scheme = {
        "id": str(uuid.uuid4()),
        "society_id": society_id,
        "scheme_name": data.scheme_name,
        "eligible_months": data.eligible_months,
        "free_months": data.free_months,
        "discount_type": data.discount_type,
        "discount_value": data.discount_value,
        "is_active": data.is_active,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    await db.discount_schemes.insert_one(scheme)
    return DiscountSchemeResponse(**scheme)


@router.put("/discount-schemes/{scheme_id}", response_model=DiscountSchemeResponse)
async def update_discount_scheme(
    society_id: str, scheme_id: str, data: DiscountSchemeCreate,
    current_user: dict = Depends(get_current_user)
):
    """Update a discount scheme (Manager only)."""
    await _verify(current_user["sub"], society_id, ["manager"])
    
    scheme = await db.discount_schemes.find_one({"id": scheme_id, "society_id": society_id}, {"_id": 0})
    if not scheme:
        raise HTTPException(status_code=404, detail="Discount scheme not found")
    
    update_data = {
        "scheme_name": data.scheme_name,
        "eligible_months": data.eligible_months,
        "free_months": data.free_months,
        "discount_type": data.discount_type,
        "discount_value": data.discount_value,
        "is_active": data.is_active,
    }
    
    await db.discount_schemes.update_one({"id": scheme_id}, {"$set": update_data})
    scheme.update(update_data)
    return DiscountSchemeResponse(**scheme)


@router.delete("/discount-schemes/{scheme_id}")
async def delete_discount_scheme(
    society_id: str, scheme_id: str,
    current_user: dict = Depends(get_current_user)
):
    """Delete a discount scheme (Manager only)."""
    await _verify(current_user["sub"], society_id, ["manager"])
    
    result = await db.discount_schemes.delete_one({"id": scheme_id, "society_id": society_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Discount scheme not found")
    
    return {"status": "deleted"}


# ═══════════════════════════════════════════════════════════════════════════════
# BILL GENERATION
# ═══════════════════════════════════════════════════════════════════════════════

@router.post("/bills/preview", response_model=BillPreviewResponse)
async def preview_bills(
    society_id: str, data: GenerateBillsRequest,
    current_user: dict = Depends(get_current_user)
):
    """Preview bills before generation (Manager only)."""
    await _verify(current_user["sub"], society_id, ["manager"])
    
    settings = await _get_or_create_settings(society_id)
    flats = await db.flats.find({"society_id": society_id}, {"_id": 0}).to_list(1000)
    
    # Get discount scheme if applicable
    scheme = None
    if data.apply_discount_scheme and data.discount_scheme_id:
        scheme = await db.discount_schemes.find_one(
            {"id": data.discount_scheme_id, "society_id": society_id, "is_active": True}, {"_id": 0}
        )
    
    total_area = sum(f.get("area_sqft", 0) for f in flats)
    rate = settings["default_rate_per_sqft"]
    months = 12 if data.bill_period_type == "yearly" else 1
    
    total_before_discount = 0
    total_discount = 0
    bills_preview = []
    
    for flat in flats:
        area = flat.get("area_sqft", 0)
        amount = await _calculate_bill_amount(area, rate, months)
        discount, final = await _apply_discount(amount, scheme) if scheme else (0, amount)
        
        total_before_discount += amount
        total_discount += discount
        
        primary = await _get_primary_member(flat["id"], society_id)
        
        bills_preview.append({
            "flat_id": flat["id"],
            "flat_number": flat["flat_number"],
            "wing": flat.get("wing", ""),
            "area_sqft": area,
            "rate_per_sqft": rate,
            "amount_before_discount": amount,
            "discount": discount,
            "final_amount": final,
            "primary_user": primary["user_name"],
        })
    
    return BillPreviewResponse(
        total_flats=len(flats),
        total_area_sqft=total_area,
        rate_per_sqft=rate,
        total_collection_before_discount=round(total_before_discount, 2),
        estimated_discount=round(total_discount, 2),
        total_collection_after_discount=round(total_before_discount - total_discount, 2),
        bills_preview=bills_preview,
    )


@router.post("/bills/generate")
async def generate_bills(
    society_id: str, data: GenerateBillsRequest,
    current_user: dict = Depends(get_current_user)
):
    """Generate maintenance bills for all flats (Manager only)."""
    await _verify(current_user["sub"], society_id, ["manager"])
    
    # Validate request
    if data.bill_period_type == "monthly" and data.month is None:
        raise HTTPException(status_code=400, detail="Month is required for monthly bills")
    
    # Check for duplicate bills
    query = {"society_id": society_id, "year": data.year, "bill_period_type": data.bill_period_type}
    if data.bill_period_type == "monthly":
        query["month"] = data.month
    
    existing = await db.maintenance_bills_v2.find_one(query, {"_id": 0})
    if existing:
        period = f"{data.month}/{data.year}" if data.bill_period_type == "monthly" else str(data.year)
        raise HTTPException(status_code=400, detail=f"Bills already generated for {period}")
    
    settings = await _get_or_create_settings(society_id)
    society = await db.societies.find_one({"id": society_id}, {"_id": 0})
    flats = await db.flats.find({"society_id": society_id}, {"_id": 0}).to_list(1000)
    
    # Get discount scheme
    scheme = None
    if data.apply_discount_scheme and data.discount_scheme_id:
        scheme = await db.discount_schemes.find_one(
            {"id": data.discount_scheme_id, "society_id": society_id, "is_active": True}, {"_id": 0}
        )
    
    now = datetime.now(timezone.utc)
    rate = settings["default_rate_per_sqft"]
    months = 12 if data.bill_period_type == "yearly" else 1
    
    # Calculate due date
    due_day = settings["due_date_day"]
    if data.bill_period_type == "monthly":
        due_date = datetime(data.year, data.month, min(due_day, 28))
    else:
        due_date = datetime(data.year, 12, 31)
    
    bills_created = 0
    total_amount = 0
    
    for flat in flats:
        area = flat.get("area_sqft", 0)
        if area <= 0:
            continue
        
        amount_before = await _calculate_bill_amount(area, rate, months)
        discount, final_amount = await _apply_discount(amount_before, scheme) if scheme else (0, amount_before)
        
        primary = await _get_primary_member(flat["id"], society_id)
        
        bill_id = str(uuid.uuid4())
        bill = {
            "id": bill_id,
            "society_id": society_id,
            "flat_id": flat["id"],
            "flat_number": flat["flat_number"],
            "wing": flat.get("wing", ""),
            "primary_user_id": primary["user_id"],
            "bill_period_type": data.bill_period_type,
            "month": data.month if data.bill_period_type == "monthly" else None,
            "year": data.year,
            "area_sqft": area,
            "rate_per_sqft": rate,
            "total_before_discount": amount_before,
            "discount_applied": discount,
            "discount_scheme_id": data.discount_scheme_id if scheme else None,
            "final_payable_amount": final_amount,
            "late_fee": 0,
            "due_date": due_date.strftime("%Y-%m-%d"),
            "status": "pending",
            "paid_amount": 0,
            "created_at": now.isoformat(),
        }
        await db.maintenance_bills_v2.insert_one(bill)
        bills_created += 1
        total_amount += final_amount
        
        # Create ledger entry (debit)
        period = f"{data.month}/{data.year}" if data.bill_period_type == "monthly" else f"Year {data.year}"
        await _create_ledger_entry(
            society_id, flat["id"], primary["user_id"],
            "bill_generated", bill_id, "bill",
            debit=final_amount, notes=f"Maintenance bill for {period}"
        )
        
        # If discount applied, create separate ledger entry
        if discount > 0:
            await _create_ledger_entry(
                society_id, flat["id"], primary["user_id"],
                "discount_applied", bill_id, "bill",
                credit=discount, notes=f"Discount: {scheme['scheme_name'] if scheme else ''}"
            )
        
        # Send notification to primary member
        if primary["user_id"]:
            await db.notifications.insert_one({
                "id": str(uuid.uuid4()),
                "society_id": society_id,
                "user_id": primary["user_id"],
                "title": "Maintenance Bill Generated",
                "message": f"Your maintenance bill of ₹{final_amount:,.0f} for {period} is due on {due_date.strftime('%d %b %Y')}",
                "type": "billing",
                "read": False,
                "created_at": now.isoformat(),
            })
    
    return {
        "status": "success",
        "bills_created": bills_created,
        "total_amount": round(total_amount, 2),
        "period": f"{data.month}/{data.year}" if data.bill_period_type == "monthly" else str(data.year),
    }


# ═══════════════════════════════════════════════════════════════════════════════
# BILLS LISTING
# ═══════════════════════════════════════════════════════════════════════════════

@router.get("/bills", response_model=list[MaintenanceBillResponse])
async def list_bills(
    society_id: str,
    bill_period_type: str = None,
    month: int = None,
    year: int = None,
    status: str = None,
    flat_id: str = None,
    page: int = Query(1, ge=1),
    limit: int = Query(50, ge=1, le=200),
    current_user: dict = Depends(get_current_user),
):
    """List maintenance bills with filters."""
    membership = await _verify(current_user["sub"], society_id)
    
    query = {"society_id": society_id}
    
    # Members can only see their own bills (linked flats)
    if membership["role"] == "member":
        user_flats = await db.flat_members.find(
            {"society_id": society_id, "user_id": current_user["sub"]}, {"_id": 0}
        ).to_list(100)
        flat_ids = [f["flat_id"] for f in user_flats]
        if flat_ids:
            query["flat_id"] = {"$in": flat_ids}
        else:
            return []
    
    if bill_period_type:
        query["bill_period_type"] = bill_period_type
    if month:
        query["month"] = month
    if year:
        query["year"] = year
    if status:
        query["status"] = status
    if flat_id:
        query["flat_id"] = flat_id
    
    skip = (page - 1) * limit
    bills = await db.maintenance_bills_v2.find(query, {"_id": 0}).sort("created_at", -1).skip(skip).to_list(limit)
    
    result = []
    for b in bills:
        # Get user name
        user_name = ""
        if b.get("primary_user_id"):
            user = await db.users.find_one({"id": b["primary_user_id"]}, {"_id": 0})
            user_name = user["name"] if user else ""
        
        # Get discount scheme name
        scheme_name = ""
        if b.get("discount_scheme_id"):
            scheme = await db.discount_schemes.find_one({"id": b["discount_scheme_id"]}, {"_id": 0})
            scheme_name = scheme["scheme_name"] if scheme else ""
        
        result.append(MaintenanceBillResponse(
            **b,
            primary_user_name=user_name,
            discount_scheme_name=scheme_name,
        ))
    
    return result


@router.get("/bills/{bill_id}", response_model=MaintenanceBillResponse)
async def get_bill(
    society_id: str, bill_id: str,
    current_user: dict = Depends(get_current_user)
):
    """Get a specific bill."""
    await _verify(current_user["sub"], society_id)
    
    bill = await db.maintenance_bills_v2.find_one({"id": bill_id, "society_id": society_id}, {"_id": 0})
    if not bill:
        raise HTTPException(status_code=404, detail="Bill not found")
    
    user_name = ""
    if bill.get("primary_user_id"):
        user = await db.users.find_one({"id": bill["primary_user_id"]}, {"_id": 0})
        user_name = user["name"] if user else ""
    
    scheme_name = ""
    if bill.get("discount_scheme_id"):
        scheme = await db.discount_schemes.find_one({"id": bill["discount_scheme_id"]}, {"_id": 0})
        scheme_name = scheme["scheme_name"] if scheme else ""
    
    return MaintenanceBillResponse(**bill, primary_user_name=user_name, discount_scheme_name=scheme_name)


# ═══════════════════════════════════════════════════════════════════════════════
# PAYMENTS
# ═══════════════════════════════════════════════════════════════════════════════

@router.post("/payments", response_model=PaymentResponse)
async def record_payment(
    society_id: str, data: RecordPaymentRequest,
    current_user: dict = Depends(get_current_user)
):
    """Record a maintenance payment (Manager only)."""
    await _verify(current_user["sub"], society_id, ["manager"])
    
    flat = await db.flats.find_one({"id": data.flat_id, "society_id": society_id}, {"_id": 0})
    if not flat:
        raise HTTPException(status_code=404, detail="Flat not found")
    
    primary = await _get_primary_member(data.flat_id, society_id)
    now = datetime.now(timezone.utc)
    payment_date = data.payment_date or now.strftime("%Y-%m-%d")
    
    # Generate receipt number
    receipt_number = await _generate_receipt_number(society_id)
    
    # Get discount for annual payment
    discount_applied = 0
    if data.is_annual_payment and data.discount_scheme_id:
        scheme = await db.discount_schemes.find_one(
            {"id": data.discount_scheme_id, "is_active": True}, {"_id": 0}
        )
        if scheme:
            # Calculate what the discount should be
            settings = await _get_or_create_settings(society_id)
            monthly = flat.get("area_sqft", 0) * settings["default_rate_per_sqft"]
            total = monthly * scheme.get("eligible_months", 12)
            discount_applied, _ = await _apply_discount(total, scheme)
    
    # Create payment record
    payment_id = str(uuid.uuid4())
    payment = {
        "id": payment_id,
        "society_id": society_id,
        "flat_id": data.flat_id,
        "flat_number": flat["flat_number"],
        "bill_ids": data.bill_ids,
        "paid_by_user_id": primary["user_id"],
        "amount_paid": data.amount_paid,
        "discount_applied": discount_applied,
        "payment_mode": data.payment_mode,
        "payment_date": payment_date,
        "receipt_number": receipt_number,
        "transaction_reference": data.transaction_reference,
        "remarks": data.remarks,
        "created_at": now.isoformat(),
        "created_by": current_user["sub"],
    }
    await db.maintenance_payments.insert_one(payment)
    
    # Update bill statuses
    remaining = data.amount_paid
    for bill_id in data.bill_ids:
        if remaining <= 0:
            break
        
        bill = await db.maintenance_bills_v2.find_one({"id": bill_id}, {"_id": 0})
        if bill:
            due = bill["final_payable_amount"] - bill.get("paid_amount", 0)
            pay_now = min(remaining, due)
            new_paid = bill.get("paid_amount", 0) + pay_now
            new_status = "paid" if new_paid >= bill["final_payable_amount"] else "partial"
            
            await db.maintenance_bills_v2.update_one(
                {"id": bill_id},
                {"$set": {"paid_amount": new_paid, "status": new_status}}
            )
            remaining -= pay_now
    
    # Create ledger entry (credit)
    await _create_ledger_entry(
        society_id, data.flat_id, primary["user_id"],
        "payment_received", payment_id, "payment",
        credit=data.amount_paid, notes=f"Payment via {data.payment_mode} - {receipt_number}"
    )
    
    # Create inward transaction
    period_desc = "Annual" if data.is_annual_payment else "Monthly"
    txn_id = str(uuid.uuid4())
    await db.transactions.insert_one({
        "id": txn_id,
        "society_id": society_id,
        "type": "inward",
        "category": "Maintenance Payment",
        "amount": data.amount_paid,
        "description": f"{period_desc} maintenance from {flat['flat_number']}",
        "vendor_name": "",
        "payment_mode": data.payment_mode,
        "invoice_path": "",
        "date": payment_date,
        "created_by": current_user["sub"],
        "created_at": now.isoformat(),
        "approval_status": "approved",
    })
    
    # Notify member
    if primary["user_id"]:
        await db.notifications.insert_one({
            "id": str(uuid.uuid4()),
            "society_id": society_id,
            "user_id": primary["user_id"],
            "title": "Payment Received",
            "message": f"Your payment of ₹{data.amount_paid:,.0f} has been recorded. Receipt: {receipt_number}",
            "type": "payment",
            "read": False,
            "created_at": now.isoformat(),
        })
    
    return PaymentResponse(
        **payment,
        paid_by_user_name=primary["user_name"],
    )


@router.get("/payments", response_model=list[PaymentResponse])
async def list_payments(
    society_id: str,
    flat_id: str = None,
    page: int = Query(1, ge=1),
    limit: int = Query(50, ge=1, le=200),
    current_user: dict = Depends(get_current_user),
):
    """List maintenance payments."""
    membership = await _verify(current_user["sub"], society_id)
    
    query = {"society_id": society_id}
    
    if membership["role"] == "member":
        user_flats = await db.flat_members.find(
            {"society_id": society_id, "user_id": current_user["sub"]}, {"_id": 0}
        ).to_list(100)
        flat_ids = [f["flat_id"] for f in user_flats]
        if flat_ids:
            query["flat_id"] = {"$in": flat_ids}
        else:
            return []
    elif flat_id:
        query["flat_id"] = flat_id
    
    skip = (page - 1) * limit
    payments = await db.maintenance_payments.find(query, {"_id": 0}).sort("created_at", -1).skip(skip).to_list(limit)
    
    result = []
    for p in payments:
        user_name = ""
        if p.get("paid_by_user_id"):
            user = await db.users.find_one({"id": p["paid_by_user_id"]}, {"_id": 0})
            user_name = user["name"] if user else ""
        result.append(PaymentResponse(**p, paid_by_user_name=user_name))
    
    return result


# ═══════════════════════════════════════════════════════════════════════════════
# ANNUAL PAYMENT
# ═══════════════════════════════════════════════════════════════════════════════

@router.post("/annual-payment/preview", response_model=AnnualPaymentPreviewResponse)
async def preview_annual_payment(
    society_id: str, data: AnnualPaymentPreviewRequest,
    current_user: dict = Depends(get_current_user)
):
    """Preview annual payment with discount calculation."""
    await _verify(current_user["sub"], society_id)
    
    flat = await db.flats.find_one({"id": data.flat_id, "society_id": society_id}, {"_id": 0})
    if not flat:
        raise HTTPException(status_code=404, detail="Flat not found")
    
    settings = await _get_or_create_settings(society_id)
    
    area = flat.get("area_sqft", 0)
    rate = settings["default_rate_per_sqft"]
    monthly = area * rate
    
    # Get discount scheme
    scheme = None
    scheme_name = ""
    free_months = 0
    discount = 0
    
    if data.discount_scheme_id:
        scheme = await db.discount_schemes.find_one(
            {"id": data.discount_scheme_id, "is_active": True}, {"_id": 0}
        )
        if scheme:
            scheme_name = scheme["scheme_name"]
            free_months = scheme.get("free_months", 0)
            total = monthly * scheme.get("eligible_months", 12)
            discount, final = await _apply_discount(total, scheme)
    
    # Check which months are already paid
    existing_bills = await db.maintenance_bills_v2.find({
        "society_id": society_id, "flat_id": data.flat_id, "year": data.year
    }, {"_id": 0}).to_list(12)
    
    already_paid = [b["month"] for b in existing_bills if b.get("status") == "paid" and b.get("month")]
    pending = [m for m in range(1, 13) if m not in already_paid]
    
    total_months = 12
    total_before = monthly * total_months
    final_payable = total_before - discount
    
    return AnnualPaymentPreviewResponse(
        flat_id=data.flat_id,
        flat_number=flat["flat_number"],
        area_sqft=area,
        rate_per_sqft=rate,
        monthly_amount=round(monthly, 2),
        total_months=total_months,
        total_before_discount=round(total_before, 2),
        discount_scheme_name=scheme_name,
        free_months=free_months,
        discount_amount=round(discount, 2),
        final_payable=round(final_payable, 2),
        pending_months=pending,
        already_paid_months=already_paid,
    )


# ═══════════════════════════════════════════════════════════════════════════════
# LEDGER
# ═══════════════════════════════════════════════════════════════════════════════

@router.get("/ledger/{flat_id}", response_model=LedgerSummaryResponse)
async def get_flat_ledger(
    society_id: str, flat_id: str,
    current_user: dict = Depends(get_current_user)
):
    """Get complete ledger for a flat."""
    membership = await _verify(current_user["sub"], society_id)
    
    # Members can only view their own flats
    if membership["role"] == "member":
        is_member = await db.flat_members.find_one(
            {"flat_id": flat_id, "user_id": current_user["sub"]}, {"_id": 0}
        )
        if not is_member:
            raise HTTPException(status_code=403, detail="Not authorized to view this ledger")
    
    flat = await db.flats.find_one({"id": flat_id, "society_id": society_id}, {"_id": 0})
    if not flat:
        raise HTTPException(status_code=404, detail="Flat not found")
    
    primary = await _get_primary_member(flat_id, society_id)
    
    # Get ledger entries
    entries = await db.member_ledger.find(
        {"society_id": society_id, "flat_id": flat_id}, {"_id": 0}
    ).sort("entry_date", -1).to_list(500)
    
    # Calculate totals
    total_billed = sum(e.get("debit_amount", 0) for e in entries if e["entry_type"] == "bill_generated")
    total_paid = sum(e.get("credit_amount", 0) for e in entries if e["entry_type"] == "payment_received")
    total_discount = sum(e.get("credit_amount", 0) for e in entries if e["entry_type"] == "discount_applied")
    
    # Get last payment date
    last_payment = await db.maintenance_payments.find_one(
        {"society_id": society_id, "flat_id": flat_id}, {"_id": 0}
    )
    last_payment_date = last_payment["payment_date"] if last_payment else None
    
    # Current balance
    outstanding = entries[0]["balance_after_entry"] if entries else 0
    
    # Format entries
    entry_responses = []
    for e in entries:
        user_name = ""
        if e.get("user_id"):
            user = await db.users.find_one({"id": e["user_id"]}, {"_id": 0})
            user_name = user["name"] if user else ""
        
        entry_responses.append(LedgerEntryResponse(
            **e,
            flat_number=flat["flat_number"],
            user_name=user_name,
        ))
    
    return LedgerSummaryResponse(
        flat_id=flat_id,
        flat_number=flat["flat_number"],
        primary_user_name=primary["user_name"],
        total_billed=round(total_billed, 2),
        total_paid=round(total_paid, 2),
        total_discount=round(total_discount, 2),
        outstanding_balance=round(outstanding, 2),
        last_payment_date=last_payment_date,
        entries=entry_responses,
    )


# ═══════════════════════════════════════════════════════════════════════════════
# RECEIPTS
# ═══════════════════════════════════════════════════════════════════════════════

@router.get("/receipts/{payment_id}", response_model=ReceiptResponse)
async def get_receipt(
    society_id: str, payment_id: str,
    current_user: dict = Depends(get_current_user)
):
    """Get receipt details for a payment."""
    await _verify(current_user["sub"], society_id)
    
    payment = await db.maintenance_payments.find_one({"id": payment_id, "society_id": society_id}, {"_id": 0})
    if not payment:
        raise HTTPException(status_code=404, detail="Payment not found")
    
    society = await db.societies.find_one({"id": society_id}, {"_id": 0})
    flat = await db.flats.find_one({"id": payment["flat_id"]}, {"_id": 0})
    primary = await _get_primary_member(payment["flat_id"], society_id)
    
    # Determine period covered
    if payment.get("bill_ids"):
        bills = await db.maintenance_bills_v2.find({"id": {"$in": payment["bill_ids"]}}, {"_id": 0}).to_list(20)
        if bills:
            periods = []
            for b in bills:
                if b.get("bill_period_type") == "yearly":
                    periods.append(f"Year {b['year']}")
                else:
                    periods.append(f"{b.get('month', '')}/{b['year']}")
            period_covered = ", ".join(periods)
        else:
            period_covered = "Various"
    else:
        period_covered = "Annual Payment"
    
    return ReceiptResponse(
        receipt_number=payment["receipt_number"],
        society_name=society["name"] if society else "",
        society_address=society["address"] if society else "",
        flat_number=flat["flat_number"] if flat else "",
        owner_name=primary["user_name"],
        period_covered=period_covered,
        amount_before_discount=payment["amount_paid"] + payment.get("discount_applied", 0),
        discount_applied=payment.get("discount_applied", 0),
        late_fee=0,
        final_paid_amount=payment["amount_paid"],
        payment_mode=payment["payment_mode"],
        payment_date=payment["payment_date"],
        transaction_reference=payment.get("transaction_reference", ""),
        generated_at=datetime.now(timezone.utc).isoformat(),
    )


@router.get("/receipts/{payment_id}/pdf")
async def download_receipt_pdf(
    society_id: str, payment_id: str,
    current_user: dict = Depends(get_current_user)
):
    """Download receipt as PDF."""
    await _verify(current_user["sub"], society_id)
    
    payment = await db.maintenance_payments.find_one({"id": payment_id, "society_id": society_id}, {"_id": 0})
    if not payment:
        raise HTTPException(status_code=404, detail="Payment not found")
    
    society = await db.societies.find_one({"id": society_id}, {"_id": 0})
    flat = await db.flats.find_one({"id": payment["flat_id"]}, {"_id": 0})
    primary = await _get_primary_member(payment["flat_id"], society_id)
    
    # Generate simple HTML receipt
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body {{ font-family: Arial, sans-serif; padding: 40px; max-width: 600px; margin: 0 auto; }}
            .header {{ text-align: center; border-bottom: 2px solid #333; padding-bottom: 20px; }}
            .header h1 {{ margin: 0; color: #1a1a2e; }}
            .header p {{ margin: 5px 0; color: #666; }}
            .receipt-no {{ background: #f0f0f0; padding: 10px; text-align: center; margin: 20px 0; }}
            .details {{ margin: 20px 0; }}
            .row {{ display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #eee; }}
            .row.total {{ font-weight: bold; font-size: 1.2em; border-top: 2px solid #333; margin-top: 10px; }}
            .footer {{ text-align: center; margin-top: 40px; color: #666; font-size: 0.9em; }}
        </style>
    </head>
    <body>
        <div class="header">
            <h1>{society['name'] if society else 'Society'}</h1>
            <p>{society['address'] if society else ''}</p>
            <p>MAINTENANCE PAYMENT RECEIPT</p>
        </div>
        
        <div class="receipt-no">
            <strong>Receipt No:</strong> {payment['receipt_number']}
        </div>
        
        <div class="details">
            <div class="row"><span>Flat Number:</span><span>{flat['flat_number'] if flat else ''}</span></div>
            <div class="row"><span>Owner:</span><span>{primary['user_name']}</span></div>
            <div class="row"><span>Payment Date:</span><span>{payment['payment_date']}</span></div>
            <div class="row"><span>Payment Mode:</span><span>{payment['payment_mode'].upper()}</span></div>
            <div class="row"><span>Transaction Ref:</span><span>{payment.get('transaction_reference', 'N/A')}</span></div>
            <div class="row"><span>Amount:</span><span>₹{payment['amount_paid']:,.2f}</span></div>
            {f'<div class="row"><span>Discount Applied:</span><span>₹{payment.get("discount_applied", 0):,.2f}</span></div>' if payment.get('discount_applied') else ''}
            <div class="row total"><span>Total Paid:</span><span>₹{payment['amount_paid']:,.2f}</span></div>
        </div>
        
        <div class="footer">
            <p>This is a computer-generated receipt and does not require signature.</p>
            <p>Thank you for your payment!</p>
        </div>
    </body>
    </html>
    """
    
    # Return HTML as downloadable file (PDF generation would require additional library)
    return StreamingResponse(
        io.BytesIO(html_content.encode()),
        media_type="text/html",
        headers={"Content-Disposition": f"attachment; filename=receipt_{payment['receipt_number']}.html"}
    )


# ═══════════════════════════════════════════════════════════════════════════════
# COLLECTION DASHBOARD
# ═══════════════════════════════════════════════════════════════════════════════

@router.get("/collection-dashboard", response_model=CollectionDashboardResponse)
async def get_collection_dashboard(
    society_id: str,
    year: int = None,
    month: int = None,
    current_user: dict = Depends(get_current_user)
):
    """Get maintenance collection dashboard (Manager only)."""
    await _verify(current_user["sub"], society_id, ["manager", "committee", "auditor"])
    
    now = datetime.now(timezone.utc)
    if not year:
        year = now.year
    if not month:
        month = now.month
    
    # Total flats
    total_flats = await db.flats.count_documents({"society_id": society_id})
    
    # Bills for the period
    bills = await db.maintenance_bills_v2.find({
        "society_id": society_id, "year": year
    }, {"_id": 0}).to_list(1000)
    
    # If checking specific month, filter
    if month:
        monthly_bills = [b for b in bills if b.get("month") == month or b.get("bill_period_type") == "yearly"]
    else:
        monthly_bills = bills
    
    paid_flats = len([b for b in monthly_bills if b.get("status") == "paid"])
    pending_flats = len([b for b in monthly_bills if b.get("status") in ["pending", "partial"]])
    overdue_flats = len([b for b in monthly_bills if b.get("status") == "overdue"])
    
    total_billed = sum(b.get("final_payable_amount", 0) for b in monthly_bills)
    total_collected = sum(b.get("paid_amount", 0) for b in monthly_bills)
    total_outstanding = total_billed - total_collected
    
    collection_pct = (total_collected / total_billed * 100) if total_billed > 0 else 0
    
    # Month-wise collection for the year
    month_wise = []
    for m in range(1, 13):
        m_bills = [b for b in bills if b.get("month") == m]
        m_billed = sum(b.get("final_payable_amount", 0) for b in m_bills)
        m_collected = sum(b.get("paid_amount", 0) for b in m_bills)
        month_wise.append({
            "month": m,
            "billed": round(m_billed, 2),
            "collected": round(m_collected, 2),
            "pending": round(m_billed - m_collected, 2),
        })
    
    # Recent payments
    recent = await db.maintenance_payments.find(
        {"society_id": society_id}, {"_id": 0}
    ).sort("created_at", -1).to_list(10)
    
    recent_payments = []
    for p in recent:
        flat = await db.flats.find_one({"id": p["flat_id"]}, {"_id": 0})
        recent_payments.append({
            "receipt_number": p["receipt_number"],
            "flat_number": flat["flat_number"] if flat else "",
            "amount": p["amount_paid"],
            "date": p["payment_date"],
            "mode": p["payment_mode"],
        })
    
    return CollectionDashboardResponse(
        total_flats=total_flats,
        paid_flats=paid_flats,
        pending_flats=pending_flats,
        overdue_flats=overdue_flats,
        total_billed=round(total_billed, 2),
        total_collected=round(total_collected, 2),
        total_outstanding=round(total_outstanding, 2),
        collection_percentage=round(collection_pct, 1),
        month_wise_collection=month_wise,
        recent_payments=recent_payments,
    )


# ═══════════════════════════════════════════════════════════════════════════════
# OVERDUE PROCESSING
# ═══════════════════════════════════════════════════════════════════════════════

@router.post("/process-overdue")
async def process_overdue_bills(
    society_id: str,
    current_user: dict = Depends(get_current_user)
):
    """Mark overdue bills and apply late fees (Manager only)."""
    await _verify(current_user["sub"], society_id, ["manager"])
    
    settings = await _get_or_create_settings(society_id)
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    
    # Find pending bills past due date
    overdue_bills = await db.maintenance_bills_v2.find({
        "society_id": society_id,
        "status": {"$in": ["pending", "partial"]},
        "due_date": {"$lt": today}
    }, {"_id": 0}).to_list(1000)
    
    updated_count = 0
    late_fee_amount = settings.get("late_fee_amount", 0)
    
    for bill in overdue_bills:
        update_data = {"status": "overdue"}
        
        # Apply late fee if not already applied
        if late_fee_amount > 0 and bill.get("late_fee", 0) == 0:
            if settings.get("late_fee_type") == "percentage":
                fee = bill["final_payable_amount"] * (late_fee_amount / 100)
            else:
                fee = late_fee_amount
            
            update_data["late_fee"] = round(fee, 2)
            update_data["final_payable_amount"] = round(bill["final_payable_amount"] + fee, 2)
            
            # Create ledger entry for late fee
            await _create_ledger_entry(
                society_id, bill["flat_id"], bill.get("primary_user_id", ""),
                "late_fee", bill["id"], "bill",
                debit=fee, notes="Late fee applied"
            )
        
        await db.maintenance_bills_v2.update_one({"id": bill["id"]}, {"$set": update_data})
        updated_count += 1
    
    return {"status": "success", "overdue_bills_processed": updated_count}


# ═══════════════════════════════════════════════════════════════════════════════
# BACKWARD COMPATIBILITY - OLD ENDPOINTS
# ═══════════════════════════════════════════════════════════════════════════════

@router.post("/generate")
async def generate_bills_legacy(
    society_id: str,
    month: int,
    year: int,
    amount_per_flat: float,
    due_date: str,
    late_fee: float = 0,
    current_user: dict = Depends(get_current_user)
):
    """Legacy bill generation endpoint for backward compatibility."""
    await _verify(current_user["sub"], society_id, ["manager"])
    
    # Redirect to new endpoint
    data = GenerateBillsRequest(
        bill_period_type="monthly",
        month=month,
        year=year,
        apply_discount_scheme=False,
    )
    return await generate_bills(society_id, data, current_user)


@router.post("/pay")
async def record_payment_legacy(
    society_id: str,
    bill_id: str,
    amount_paid: float,
    payment_mode: str = "bank",
    current_user: dict = Depends(get_current_user)
):
    """Legacy payment endpoint for backward compatibility."""
    bill = await db.maintenance_bills_v2.find_one({"id": bill_id}, {"_id": 0})
    if not bill:
        # Try old collection
        bill = await db.maintenance_bills.find_one({"id": bill_id}, {"_id": 0})
    
    if not bill:
        raise HTTPException(status_code=404, detail="Bill not found")
    
    data = RecordPaymentRequest(
        flat_id=bill["flat_id"],
        bill_ids=[bill_id],
        amount_paid=amount_paid,
        payment_mode=payment_mode,
    )
    return await record_payment(society_id, data, current_user)
