from fastapi import APIRouter, HTTPException, Depends
from database import db
from auth_utils import get_current_user
from models import (
    SocietyCreate, SocietyResponse, SocietyWithRole, SocietyUpdate,
    FlatCreate, FlatResponse,
    MembershipCreate, MembershipResponse,
    FlatMemberCreate, FlatMemberResponse,
    DashboardData,
)
import uuid
from datetime import datetime, timezone

router = APIRouter(prefix="/api/societies", tags=["Societies"])


# ─── Helper: verify user belongs to society ──────────
async def verify_membership(user_id: str, society_id: str, roles: list = None):
    query = {"user_id": user_id, "society_id": society_id, "status": "active"}
    m = await db.memberships.find_one(query, {"_id": 0})
    if not m:
        raise HTTPException(status_code=403, detail="Not a member of this society")
    if roles and m["role"] not in roles:
        raise HTTPException(status_code=403, detail="Insufficient permissions")
    return m


# ─── Society CRUD ────────────────────────────────────
@router.get("/", response_model=list[SocietyWithRole])
async def list_my_societies(current_user: dict = Depends(get_current_user)):
    user_id = current_user["sub"]
    memberships = await db.memberships.find(
        {"user_id": user_id, "status": "active"}, {"_id": 0}
    ).to_list(100)

    result = []
    for m in memberships:
        soc = await db.societies.find_one({"id": m["society_id"]}, {"_id": 0})
        if soc:
            result.append(SocietyWithRole(
                id=soc["id"], name=soc["name"], address=soc["address"],
                total_flats=soc["total_flats"], description=soc.get("description", ""),
                role=m["role"], membership_id=m["id"],
            ))
    return result


@router.post("/", response_model=SocietyResponse)
async def create_society(data: SocietyCreate, current_user: dict = Depends(get_current_user)):
    soc_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()
    soc_doc = {
        "id": soc_id,
        "name": data.name,
        "address": data.address,
        "total_flats": data.total_flats,
        "description": data.description,
        "approval_threshold": data.approval_threshold,
        "created_at": now,
        "created_by": current_user["sub"],
    }
    await db.societies.insert_one(soc_doc)

    mem_id = str(uuid.uuid4())
    await db.memberships.insert_one({
        "id": mem_id,
        "user_id": current_user["sub"],
        "society_id": soc_id,
        "role": "manager",
        "status": "active",
        "created_at": now,
    })

    return SocietyResponse(**{k: v for k, v in soc_doc.items() if k != "_id"})


@router.get("/{society_id}")
async def get_society(society_id: str, current_user: dict = Depends(get_current_user)):
    await verify_membership(current_user["sub"], society_id)
    soc = await db.societies.find_one({"id": society_id}, {"_id": 0})
    if not soc:
        raise HTTPException(status_code=404, detail="Society not found")
    return soc


@router.put("/{society_id}")
async def update_society(society_id: str, data: SocietyUpdate, current_user: dict = Depends(get_current_user)):
    await verify_membership(current_user["sub"], society_id, ["manager"])
    update = {}
    if data.name is not None:
        update["name"] = data.name
    if data.address is not None:
        update["address"] = data.address
    if data.total_flats is not None:
        update["total_flats"] = data.total_flats
    if data.description is not None:
        update["description"] = data.description
    if data.approval_threshold is not None:
        update["approval_threshold"] = data.approval_threshold
    if not update:
        raise HTTPException(status_code=400, detail="Nothing to update")
    await db.societies.update_one({"id": society_id}, {"$set": update})
    soc = await db.societies.find_one({"id": society_id}, {"_id": 0})
    return soc


# ─── Flats ───────────────────────────────────────────
@router.get("/{society_id}/flats", response_model=list[FlatResponse])
async def list_flats(society_id: str, current_user: dict = Depends(get_current_user)):
    await verify_membership(current_user["sub"], society_id)
    flats = await db.flats.find({"society_id": society_id}, {"_id": 0}).to_list(1000)
    return [FlatResponse(**f) for f in flats]


@router.post("/{society_id}/flats", response_model=FlatResponse)
async def create_flat(society_id: str, data: FlatCreate, current_user: dict = Depends(get_current_user)):
    await verify_membership(current_user["sub"], society_id, ["manager"])
    flat_id = str(uuid.uuid4())
    flat_doc = {
        "id": flat_id,
        "society_id": society_id,
        "flat_number": data.flat_number,
        "floor": data.floor,
        "wing": data.wing,
        "area_sqft": data.area_sqft,
        "flat_type": data.flat_type,
    }
    await db.flats.insert_one(flat_doc)
    return FlatResponse(**flat_doc)


# ─── Members / Memberships ──────────────────────────
@router.get("/{society_id}/members", response_model=list[MembershipResponse])
async def list_members(society_id: str, current_user: dict = Depends(get_current_user)):
    await verify_membership(current_user["sub"], society_id)
    mems = await db.memberships.find({"society_id": society_id}, {"_id": 0}).to_list(1000)
    result = []
    for m in mems:
        user = await db.users.find_one({"id": m["user_id"]}, {"_id": 0})
        result.append(MembershipResponse(
            id=m["id"], user_id=m["user_id"], society_id=m["society_id"],
            role=m["role"], status=m["status"],
            user_name=user["name"] if user else "", user_email=user.get("email", "") if user else "",
        ))
    return result


@router.post("/{society_id}/members", response_model=MembershipResponse)
async def add_member(society_id: str, data: MembershipCreate, current_user: dict = Depends(get_current_user)):
    await verify_membership(current_user["sub"], society_id, ["manager"])
    user = await db.users.find_one({"email": data.email}, {"_id": 0})
    if not user:
        raise HTTPException(status_code=404, detail="User not found with that email")

    existing = await db.memberships.find_one(
        {"user_id": user["id"], "society_id": society_id}, {"_id": 0}
    )
    if existing:
        raise HTTPException(status_code=400, detail="User already a member")

    mem_id = str(uuid.uuid4())
    mem_doc = {
        "id": mem_id,
        "user_id": user["id"],
        "society_id": society_id,
        "role": data.role,
        "status": "active",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    await db.memberships.insert_one(mem_doc)
    return MembershipResponse(
        id=mem_id, user_id=user["id"], society_id=society_id,
        role=data.role, status="active",
        user_name=user["name"], user_email=user.get("email", ""),
    )


@router.put("/{society_id}/members/{membership_id}")
async def update_membership(society_id: str, membership_id: str, role: str = None, status: str = None,
                            current_user: dict = Depends(get_current_user)):
    await verify_membership(current_user["sub"], society_id, ["manager"])
    update = {}
    if role:
        update["role"] = role
    if status:
        update["status"] = status
    if not update:
        raise HTTPException(status_code=400, detail="Nothing to update")
    await db.memberships.update_one({"id": membership_id}, {"$set": update})
    return {"status": "updated"}


# ─── Flat Members ────────────────────────────────────
@router.get("/{society_id}/flats/{flat_id}/members", response_model=list[FlatMemberResponse])
async def list_flat_members(society_id: str, flat_id: str, current_user: dict = Depends(get_current_user)):
    await verify_membership(current_user["sub"], society_id)
    fms = await db.flat_members.find({"flat_id": flat_id, "society_id": society_id}, {"_id": 0}).to_list(100)
    result = []
    for fm in fms:
        user = await db.users.find_one({"id": fm["user_id"]}, {"_id": 0})
        result.append(FlatMemberResponse(
            id=fm["id"], flat_id=fm["flat_id"], user_id=fm["user_id"],
            society_id=fm["society_id"], relation_type=fm["relation_type"],
            is_primary=fm["is_primary"],
            user_name=user["name"] if user else "", user_email=user.get("email", "") if user else "",
        ))
    return result


@router.post("/{society_id}/flats/{flat_id}/members", response_model=FlatMemberResponse)
async def add_flat_member(society_id: str, flat_id: str, data: FlatMemberCreate,
                          current_user: dict = Depends(get_current_user)):
    await verify_membership(current_user["sub"], society_id, ["manager"])
    fm_id = str(uuid.uuid4())
    fm_doc = {
        "id": fm_id,
        "flat_id": flat_id,
        "user_id": data.user_id,
        "society_id": society_id,
        "relation_type": data.relation_type,
        "is_primary": data.is_primary,
    }
    await db.flat_members.insert_one(fm_doc)
    user = await db.users.find_one({"id": data.user_id}, {"_id": 0})
    return FlatMemberResponse(
        **fm_doc,
        user_name=user["name"] if user else "",
        user_email=user.get("email", "") if user else "",
    )


@router.delete("/{society_id}/flats/{flat_id}/members/{fm_id}")
async def remove_flat_member(society_id: str, flat_id: str, fm_id: str,
                             current_user: dict = Depends(get_current_user)):
    await verify_membership(current_user["sub"], society_id, ["manager"])
    result = await db.flat_members.delete_one({"id": fm_id, "society_id": society_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Flat member not found")
    return {"status": "removed"}


# ─── Dashboard ───────────────────────────────────────
@router.get("/{society_id}/dashboard", response_model=DashboardData)
async def get_dashboard(society_id: str, current_user: dict = Depends(get_current_user)):
    membership = await verify_membership(current_user["sub"], society_id)

    # Aggregate totals
    inward_txns = await db.transactions.find(
        {"society_id": society_id, "type": "inward", "approval_status": "approved"}, {"_id": 0}
    ).to_list(10000)
    outward_txns = await db.transactions.find(
        {"society_id": society_id, "type": "outward", "approval_status": "approved"}, {"_id": 0}
    ).to_list(10000)

    total_inward = sum(t["amount"] for t in inward_txns)
    total_outward = sum(t["amount"] for t in outward_txns)

    # Recent transactions
    recent = await db.transactions.find(
        {"society_id": society_id}, {"_id": 0}
    ).sort("created_at", -1).to_list(10)

    # Pending dues
    pending_bills = await db.maintenance_bills.count_documents(
        {"society_id": society_id, "status": {"$in": ["pending", "overdue"]}}
    )

    # Pending approvals
    pending_approvals = await db.approvals.count_documents(
        {"society_id": society_id, "status": "pending"}
    )

    # Member & flat count
    member_count = await db.memberships.count_documents({"society_id": society_id, "status": "active"})
    flat_count = await db.flats.count_documents({"society_id": society_id})

    # Monthly trend (last 6 months)
    from datetime import timedelta
    now = datetime.now(timezone.utc)
    monthly_trend = []
    for i in range(5, -1, -1):
        d = now - timedelta(days=30 * i)
        m, y = d.month, d.year
        m_in = sum(
            t["amount"] for t in inward_txns
            if t.get("date", t.get("created_at", ""))[:7] == f"{y}-{m:02d}"
        )
        m_out = sum(
            t["amount"] for t in outward_txns
            if t.get("date", t.get("created_at", ""))[:7] == f"{y}-{m:02d}"
        )
        monthly_trend.append({"month": f"{y}-{m:02d}", "inward": m_in, "outward": m_out})

    return DashboardData(
        society_balance=total_inward - total_outward,
        total_inward=total_inward,
        total_outward=total_outward,
        pending_dues=pending_bills,
        pending_approvals=pending_approvals,
        recent_transactions=recent,
        monthly_trend=monthly_trend,
        member_count=member_count,
        flat_count=flat_count,
    )
