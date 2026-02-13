from dotenv import load_dotenv
from pathlib import Path
import os

ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

from fastapi import FastAPI, APIRouter
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from starlette.middleware.cors import CORSMiddleware
from database import db, client
from auth_utils import hash_password
import logging
import uuid
from datetime import datetime, timezone, timedelta
import random

app = FastAPI(title="Society Financial Manager API")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=os.environ.get('CORS_ORIGINS', '*').split(','),
    allow_methods=["*"],
    allow_headers=["*"],
)

# Logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Import and register route modules
from routes.auth import router as auth_router
from routes.societies import router as societies_router
from routes.transactions import router as transactions_router
from routes.maintenance import router as maintenance_router
from routes.approvals import router as approvals_router
from routes.reports import router as reports_router
from routes.notifications import router as notifications_router

app.include_router(auth_router)
app.include_router(societies_router)
app.include_router(transactions_router)
app.include_router(maintenance_router)
app.include_router(approvals_router)
app.include_router(reports_router)
app.include_router(notifications_router)

# Static file serving for uploads
UPLOAD_DIR = ROOT_DIR / "uploads"
UPLOAD_DIR.mkdir(exist_ok=True)


@app.get("/api/uploads/{filename}")
async def serve_upload(filename: str):
    filepath = UPLOAD_DIR / filename
    if not filepath.exists():
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="File not found")
    return FileResponse(str(filepath))


@app.get("/api/")
async def root():
    return {"message": "Society Financial Manager API", "version": "1.0.0"}


# ─── Seed Demo Data ──────────────────────────────────
@app.post("/api/seed")
async def seed_demo_data():
    # Clear existing data
    for col in ["users", "societies", "memberships", "flats", "flat_members",
                "transactions", "maintenance_bills", "maintenance_bills_v2", 
                "maintenance_settings", "discount_schemes", "maintenance_payments",
                "member_ledger", "approvals", "notifications"]:
        await db[col].delete_many({})

    now = datetime.now(timezone.utc)

    # ─── Users ───────────────────────────────────────
    users = [
        {"id": str(uuid.uuid4()), "name": "Vikram Sharma", "email": "vikram@demo.com",
         "phone": "9876543210", "password_hash": hash_password("password123"), "created_at": now.isoformat()},
        {"id": str(uuid.uuid4()), "name": "Priya Patel", "email": "priya@demo.com",
         "phone": "9876543211", "password_hash": hash_password("password123"), "created_at": now.isoformat()},
        {"id": str(uuid.uuid4()), "name": "Rajesh Kumar", "email": "rajesh@demo.com",
         "phone": "9876543212", "password_hash": hash_password("password123"), "created_at": now.isoformat()},
        {"id": str(uuid.uuid4()), "name": "Anita Desai", "email": "anita@demo.com",
         "phone": "9876543213", "password_hash": hash_password("password123"), "created_at": now.isoformat()},
        {"id": str(uuid.uuid4()), "name": "Suresh Gupta", "email": "suresh@demo.com",
         "phone": "9876543214", "password_hash": hash_password("password123"), "created_at": now.isoformat()},
        {"id": str(uuid.uuid4()), "name": "Meera Joshi", "email": "meera@demo.com",
         "phone": "9876543215", "password_hash": hash_password("password123"), "created_at": now.isoformat()},
        {"id": str(uuid.uuid4()), "name": "Amit Singh", "email": "amit@demo.com",
         "phone": "9876543216", "password_hash": hash_password("password123"), "created_at": now.isoformat()},
        {"id": str(uuid.uuid4()), "name": "Kavita Reddy", "email": "kavita@demo.com",
         "phone": "9876543217", "password_hash": hash_password("password123"), "created_at": now.isoformat()},
    ]
    await db.users.insert_many(users)
    logger.info(f"Seeded {len(users)} users")

    # ─── Societies ───────────────────────────────────
    soc1_id = str(uuid.uuid4())
    soc2_id = str(uuid.uuid4())
    societies = [
        {"id": soc1_id, "name": "Sunrise Apartments", "address": "Sector 42, Gurugram, Haryana",
         "total_flats": 440, "description": "Premium residential society with modern amenities",
         "approval_threshold": 50000, "created_at": now.isoformat(), "created_by": users[0]["id"]},
        {"id": soc2_id, "name": "Green Valley Residency", "address": "Whitefield, Bangalore, Karnataka",
         "total_flats": 220, "description": "Eco-friendly gated community",
         "approval_threshold": 25000, "created_at": now.isoformat(), "created_by": users[1]["id"]},
    ]
    await db.societies.insert_many(societies)

    # ─── Memberships ─────────────────────────────────
    # Vikram: Manager in Soc1, Member in Soc2
    # Priya: Manager in Soc2, Member in Soc1
    # Rajesh: Committee in Soc1
    # Anita: Auditor in Soc1
    # Others: Members
    memberships = [
        {"id": str(uuid.uuid4()), "user_id": users[0]["id"], "society_id": soc1_id, "role": "manager", "status": "active", "created_at": now.isoformat()},
        {"id": str(uuid.uuid4()), "user_id": users[0]["id"], "society_id": soc2_id, "role": "member", "status": "active", "created_at": now.isoformat()},
        {"id": str(uuid.uuid4()), "user_id": users[1]["id"], "society_id": soc1_id, "role": "member", "status": "active", "created_at": now.isoformat()},
        {"id": str(uuid.uuid4()), "user_id": users[1]["id"], "society_id": soc2_id, "role": "manager", "status": "active", "created_at": now.isoformat()},
        {"id": str(uuid.uuid4()), "user_id": users[2]["id"], "society_id": soc1_id, "role": "committee", "status": "active", "created_at": now.isoformat()},
        {"id": str(uuid.uuid4()), "user_id": users[3]["id"], "society_id": soc1_id, "role": "auditor", "status": "active", "created_at": now.isoformat()},
        {"id": str(uuid.uuid4()), "user_id": users[4]["id"], "society_id": soc1_id, "role": "member", "status": "active", "created_at": now.isoformat()},
        {"id": str(uuid.uuid4()), "user_id": users[5]["id"], "society_id": soc1_id, "role": "member", "status": "active", "created_at": now.isoformat()},
        {"id": str(uuid.uuid4()), "user_id": users[6]["id"], "society_id": soc1_id, "role": "member", "status": "active", "created_at": now.isoformat()},
        {"id": str(uuid.uuid4()), "user_id": users[7]["id"], "society_id": soc2_id, "role": "member", "status": "active", "created_at": now.isoformat()},
    ]
    await db.memberships.insert_many(memberships)

    # ─── Flats (20 per society for demo) ─────────────
    wings = ["A", "B", "C", "D"]
    flats_s1 = []
    for i in range(20):
        wing = wings[i % 4]
        floor = (i // 4) + 1
        flat_num = f"{wing}-{floor}{(i % 4) + 1:02d}"
        flats_s1.append({
            "id": str(uuid.uuid4()), "society_id": soc1_id,
            "flat_number": flat_num, "floor": floor, "wing": wing,
            "area_sqft": random.choice([850, 1050, 1250, 1500]),
            "flat_type": random.choice(["1BHK", "2BHK", "3BHK"]),
        })
    await db.flats.insert_many(flats_s1)

    flats_s2 = []
    for i in range(10):
        flat_num = f"T{i + 1}-{(i % 5) + 1}{(i % 3) + 1:02d}"
        flats_s2.append({
            "id": str(uuid.uuid4()), "society_id": soc2_id,
            "flat_number": flat_num, "floor": (i % 5) + 1, "wing": f"T{i // 5 + 1}",
            "area_sqft": random.choice([900, 1100, 1300]),
            "flat_type": random.choice(["2BHK", "3BHK"]),
        })
    await db.flats.insert_many(flats_s2)

    # ─── Flat Members (assign users to flats) ────────
    flat_members = [
        {"id": str(uuid.uuid4()), "flat_id": flats_s1[0]["id"], "user_id": users[0]["id"],
         "society_id": soc1_id, "relation_type": "Owner", "is_primary": True},
        {"id": str(uuid.uuid4()), "flat_id": flats_s1[1]["id"], "user_id": users[1]["id"],
         "society_id": soc1_id, "relation_type": "Owner", "is_primary": True},
        {"id": str(uuid.uuid4()), "flat_id": flats_s1[2]["id"], "user_id": users[4]["id"],
         "society_id": soc1_id, "relation_type": "Owner", "is_primary": True},
        {"id": str(uuid.uuid4()), "flat_id": flats_s1[3]["id"], "user_id": users[5]["id"],
         "society_id": soc1_id, "relation_type": "Owner", "is_primary": True},
        {"id": str(uuid.uuid4()), "flat_id": flats_s1[4]["id"], "user_id": users[6]["id"],
         "society_id": soc1_id, "relation_type": "Owner", "is_primary": True},
        # Family member
        {"id": str(uuid.uuid4()), "flat_id": flats_s1[0]["id"], "user_id": users[5]["id"],
         "society_id": soc1_id, "relation_type": "Family", "is_primary": False},
        # Society 2
        {"id": str(uuid.uuid4()), "flat_id": flats_s2[0]["id"], "user_id": users[0]["id"],
         "society_id": soc2_id, "relation_type": "Owner", "is_primary": True},
        {"id": str(uuid.uuid4()), "flat_id": flats_s2[1]["id"], "user_id": users[7]["id"],
         "society_id": soc2_id, "relation_type": "Owner", "is_primary": True},
    ]
    await db.flat_members.insert_many(flat_members)

    # ─── Transactions ────────────────────────────────
    inward_cats = ["Maintenance Payment", "Donation", "Interest Income", "Parking Charges"]
    outward_cats = ["Security Salary", "Lift AMC", "Repairs & Maintenance", "Electricity Bill",
                    "Water Bill", "Garden Maintenance", "Cleaning"]
    payment_modes = ["cash", "upi", "bank"]

    transactions = []
    for i in range(60):
        is_inward = random.random() > 0.4
        days_ago = random.randint(0, 180)
        txn_date = (now - timedelta(days=days_ago))
        date_str = txn_date.strftime("%Y-%m-%d")
        cat = random.choice(inward_cats if is_inward else outward_cats)
        amt = random.choice([3500, 5000, 7500, 10000, 15000, 25000, 35000, 45000, 60000, 80000])

        txn = {
            "id": str(uuid.uuid4()),
            "society_id": soc1_id,
            "type": "inward" if is_inward else "outward",
            "category": cat,
            "amount": amt,
            "description": f"Demo {cat.lower()} transaction",
            "vendor_name": random.choice(["ABC Services", "XYZ Corp", "Local Vendor", ""]) if not is_inward else "",
            "payment_mode": random.choice(payment_modes),
            "invoice_path": "",
            "date": date_str,
            "created_by": users[0]["id"],
            "created_at": txn_date.isoformat(),
            "approval_status": "approved",
        }
        transactions.append(txn)

    # Add some pending approval transactions
    for i in range(3):
        txn = {
            "id": str(uuid.uuid4()),
            "society_id": soc1_id,
            "type": "outward",
            "category": random.choice(outward_cats),
            "amount": random.choice([55000, 75000, 120000]),
            "description": f"Large expense requiring approval",
            "vendor_name": "Premium Services Ltd",
            "payment_mode": "bank",
            "invoice_path": "",
            "date": now.strftime("%Y-%m-%d"),
            "created_by": users[0]["id"],
            "created_at": now.isoformat(),
            "approval_status": "pending",
        }
        transactions.append(txn)

    await db.transactions.insert_many(transactions)

    # ─── Approvals for pending transactions ──────────
    pending_txns = [t for t in transactions if t["approval_status"] == "pending"]
    approvals = []
    for t in pending_txns:
        approvals.append({
            "id": str(uuid.uuid4()),
            "transaction_id": t["id"],
            "society_id": soc1_id,
            "requested_by": users[0]["id"],
            "status": "pending",
            "approved_by": "",
            "comments": "",
            "created_at": now.isoformat(),
        })
    if approvals:
        await db.approvals.insert_many(approvals)

    # ─── Maintenance Bills ───────────────────────────
    bills = []
    for flat in flats_s1[:5]:
        primary = next((fm for fm in flat_members if fm["flat_id"] == flat["id"] and fm["is_primary"]), None)
        for m in [1, 2]:
            bill_status = "paid" if m == 1 else "pending"
            bills.append({
                "id": str(uuid.uuid4()),
                "society_id": soc1_id,
                "flat_id": flat["id"],
                "flat_number": flat["flat_number"],
                "member_id": primary["user_id"] if primary else "",
                "month": m,
                "year": 2026,
                "amount": 5000,
                "due_date": f"2026-{m:02d}-10",
                "late_fee": 500,
                "status": bill_status,
                "paid_amount": 5000 if bill_status == "paid" else 0,
                "created_at": now.isoformat(),
            })
    if bills:
        await db.maintenance_bills.insert_many(bills)

    # ─── Notifications ───────────────────────────────
    notifications = [
        {"id": str(uuid.uuid4()), "society_id": soc1_id, "user_id": users[0]["id"],
         "title": "Welcome to Sunrise Apartments", "message": "Your society account has been set up successfully.",
         "type": "system", "read": True, "created_at": (now - timedelta(days=30)).isoformat()},
        {"id": str(uuid.uuid4()), "society_id": soc1_id, "user_id": users[0]["id"],
         "title": "Maintenance Bill Generated", "message": "February 2026 maintenance bill of Rs.5,000 has been generated.",
         "type": "billing", "read": False, "created_at": (now - timedelta(days=5)).isoformat()},
        {"id": str(uuid.uuid4()), "society_id": soc1_id, "user_id": users[0]["id"],
         "title": "Expense Approval Pending", "message": "3 expense requests are waiting for committee approval.",
         "type": "approval", "read": False, "created_at": (now - timedelta(hours=2)).isoformat()},
        {"id": str(uuid.uuid4()), "society_id": soc1_id, "user_id": users[2]["id"],
         "title": "Approval Required", "message": "New high-value expense needs your approval.",
         "type": "approval", "read": False, "created_at": now.isoformat()},
    ]
    await db.notifications.insert_many(notifications)

    # Create indexes
    await db.users.create_index("email", unique=True)
    await db.users.create_index("id", unique=True)
    await db.societies.create_index("id", unique=True)
    await db.memberships.create_index([("user_id", 1), ("society_id", 1)])
    await db.flats.create_index([("society_id", 1)])
    await db.flat_members.create_index([("flat_id", 1), ("society_id", 1)])
    await db.transactions.create_index([("society_id", 1), ("created_at", -1)])
    await db.maintenance_bills.create_index([("society_id", 1), ("month", 1), ("year", 1)])
    await db.approvals.create_index([("society_id", 1), ("status", 1)])
    await db.notifications.create_index([("user_id", 1), ("read", 1)])

    return {
        "status": "success",
        "message": "Demo data seeded successfully",
        "data": {
            "users": len(users),
            "societies": len(societies),
            "flats": len(flats_s1) + len(flats_s2),
            "transactions": len(transactions),
            "bills": len(bills),
            "demo_credentials": [
                {"email": "vikram@demo.com", "password": "password123", "roles": "Manager(Sunrise), Member(Green Valley)"},
                {"email": "priya@demo.com", "password": "password123", "roles": "Member(Sunrise), Manager(Green Valley)"},
                {"email": "rajesh@demo.com", "password": "password123", "roles": "Committee(Sunrise)"},
                {"email": "anita@demo.com", "password": "password123", "roles": "Auditor(Sunrise)"},
            ],
        },
    }


@app.on_event("shutdown")
async def shutdown_db_client():
    client.close()
