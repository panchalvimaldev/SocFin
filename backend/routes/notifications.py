from fastapi import APIRouter, HTTPException, Depends
from database import db
from auth_utils import get_current_user
from models import NotificationResponse
from datetime import datetime, timezone

router = APIRouter(prefix="/api/notifications", tags=["Notifications"])


@router.get("/", response_model=list[NotificationResponse])
async def list_notifications(society_id: str = None, current_user: dict = Depends(get_current_user)):
    query = {"user_id": current_user["sub"]}
    if society_id:
        query["society_id"] = society_id
    notifs = await db.notifications.find(query, {"_id": 0}).sort("created_at", -1).to_list(100)
    return [NotificationResponse(**n) for n in notifs]


@router.get("/unread-count")
async def unread_count(society_id: str = None, current_user: dict = Depends(get_current_user)):
    query = {"user_id": current_user["sub"], "read": False}
    if society_id:
        query["society_id"] = society_id
    count = await db.notifications.count_documents(query)
    return {"count": count}


@router.put("/{notification_id}/read")
async def mark_read(notification_id: str, current_user: dict = Depends(get_current_user)):
    result = await db.notifications.update_one(
        {"id": notification_id, "user_id": current_user["sub"]},
        {"$set": {"read": True}},
    )
    if result.modified_count == 0:
        raise HTTPException(status_code=404, detail="Notification not found")
    return {"status": "read"}


@router.post("/mark-all-read")
async def mark_all_read(society_id: str = None, current_user: dict = Depends(get_current_user)):
    query = {"user_id": current_user["sub"], "read": False}
    if society_id:
        query["society_id"] = society_id
    result = await db.notifications.update_many(query, {"$set": {"read": True}})
    return {"marked": result.modified_count}
