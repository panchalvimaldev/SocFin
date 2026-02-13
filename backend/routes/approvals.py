from fastapi import APIRouter, HTTPException, Depends
from database import db
from auth_utils import get_current_user
from models import ApprovalResponse, ApprovalAction
import uuid
from datetime import datetime, timezone

router = APIRouter(prefix="/api/societies/{society_id}/approvals", tags=["Approvals"])


async def _verify(user_id, society_id, roles=None):
    q = {"user_id": user_id, "society_id": society_id, "status": "active"}
    m = await db.memberships.find_one(q, {"_id": 0})
    if not m:
        raise HTTPException(status_code=403, detail="Not a member")
    if roles and m["role"] not in roles:
        raise HTTPException(status_code=403, detail="Insufficient permissions")
    return m


@router.get("/", response_model=list[ApprovalResponse])
async def list_approvals(society_id: str, status: str = None,
                         current_user: dict = Depends(get_current_user)):
    await _verify(current_user["sub"], society_id)
    query = {"society_id": society_id}
    if status:
        query["status"] = status
    approvals = await db.approvals.find(query, {"_id": 0}).sort("created_at", -1).to_list(100)

    result = []
    for a in approvals:
        txn = await db.transactions.find_one({"id": a["transaction_id"]}, {"_id": 0})
        requester = await db.users.find_one({"id": a["requested_by"]}, {"_id": 0})
        approver_name = ""
        if a.get("approved_by"):
            approver = await db.users.find_one({"id": a["approved_by"]}, {"_id": 0})
            approver_name = approver["name"] if approver else ""
        result.append(ApprovalResponse(
            id=a["id"],
            transaction_id=a["transaction_id"],
            transaction=txn or {},
            requested_by=a["requested_by"],
            requested_by_name=requester["name"] if requester else "",
            status=a["status"],
            approved_by=a.get("approved_by", ""),
            approved_by_name=approver_name,
            comments=a.get("comments", ""),
            created_at=a["created_at"],
        ))
    return result


@router.post("/{approval_id}/approve")
async def approve_expense(society_id: str, approval_id: str, data: ApprovalAction,
                          current_user: dict = Depends(get_current_user)):
    await _verify(current_user["sub"], society_id, ["committee", "manager"])

    appr = await db.approvals.find_one({"id": approval_id, "society_id": society_id}, {"_id": 0})
    if not appr:
        raise HTTPException(status_code=404, detail="Approval not found")
    if appr["status"] != "pending":
        raise HTTPException(status_code=400, detail="Already processed")

    now = datetime.now(timezone.utc).isoformat()
    await db.approvals.update_one(
        {"id": approval_id},
        {"$set": {"status": "approved", "approved_by": current_user["sub"], "comments": data.comments}},
    )
    await db.transactions.update_one(
        {"id": appr["transaction_id"]},
        {"$set": {"approval_status": "approved"}},
    )

    # Notify requester
    await db.notifications.insert_one({
        "id": str(uuid.uuid4()),
        "society_id": society_id,
        "user_id": appr["requested_by"],
        "title": "Expense Approved",
        "message": f"Your expense request has been approved by committee",
        "type": "approval",
        "read": False,
        "created_at": now,
    })

    return {"status": "approved"}


@router.post("/{approval_id}/reject")
async def reject_expense(society_id: str, approval_id: str, data: ApprovalAction,
                         current_user: dict = Depends(get_current_user)):
    await _verify(current_user["sub"], society_id, ["committee", "manager"])

    appr = await db.approvals.find_one({"id": approval_id, "society_id": society_id}, {"_id": 0})
    if not appr:
        raise HTTPException(status_code=404, detail="Approval not found")
    if appr["status"] != "pending":
        raise HTTPException(status_code=400, detail="Already processed")

    await db.approvals.update_one(
        {"id": approval_id},
        {"$set": {"status": "rejected", "approved_by": current_user["sub"], "comments": data.comments}},
    )
    await db.transactions.update_one(
        {"id": appr["transaction_id"]},
        {"$set": {"approval_status": "rejected"}},
    )

    await db.notifications.insert_one({
        "id": str(uuid.uuid4()),
        "society_id": society_id,
        "user_id": appr["requested_by"],
        "title": "Expense Rejected",
        "message": f"Your expense request was rejected. Reason: {data.comments or 'No reason given'}",
        "type": "approval",
        "read": False,
        "created_at": datetime.now(timezone.utc).isoformat(),
    })

    return {"status": "rejected"}
