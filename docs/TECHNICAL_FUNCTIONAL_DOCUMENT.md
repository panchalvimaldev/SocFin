# SocietyFin - Technical Functional Document
## Society Financial Management SaaS Platform

| Field | Value |
|-------|-------|
| **Version** | 1.0.0 |
| **Date** | February 2026 |
| **Status** | MVP Complete |
| **Platforms** | Web (React) + iOS/Android (Flutter) |

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Architecture & Tech Stack](#2-architecture--tech-stack)
3. [Database Design](#3-database-design)
4. [Authentication & Authorization](#4-authentication--authorization)
5. [API Reference](#5-api-reference)
6. [Business Logic & Workflows](#6-business-logic--workflows)
7. [Frontend - React Web App](#7-frontend---react-web-app)
8. [Mobile - Flutter App](#8-mobile---flutter-app)
9. [Seed Data & Demo Setup](#9-seed-data--demo-setup)
10. [Deployment & Configuration](#10-deployment--configuration)
11. [Future Roadmap](#11-future-roadmap)

---

## 1. System Overview

### 1.1 Purpose

SocietyFin is a multi-tenant SaaS platform for Indian housing societies to manage their complete financial lifecycle - from maintenance billing and transaction recording to expense approvals, reporting, and member management.

### 1.2 Key Business Requirements

| Requirement | Description |
|-------------|-------------|
| Multi-Society | One user can belong to multiple societies with different roles |
| Multi-Member Flats | Each flat can have multiple linked members (Owner, Family, Tenant, Partner) |
| Role-Based Access | Manager, Member, Committee, Auditor - society-specific roles |
| Transaction Management | Record inward (income) and outward (expense) transactions |
| Maintenance Billing | Generate flat-wise monthly bills, track payments, late fees |
| Expense Approval | Configurable threshold triggers committee approval workflow |
| Financial Reports | Monthly/annual summaries, category breakdowns, PDF/Excel export |
| Notifications | In-app notifications for bills, approvals, and system events |

### 1.3 User Personas

| Role | Permissions | Use Cases |
|------|------------|-----------|
| **Manager** | Full CRUD on transactions, bills, members | Daily financial recording, bill generation, member management |
| **Member** | Read-only on transactions, own bills | View society finances, check pending dues, download receipts |
| **Committee** | Read + Approve/Reject expenses | Review and approve high-value expenses |
| **Auditor** | Read-only full access | Financial audit, compliance review |

### 1.4 Scale Parameters

- Designed for 440+ flats per society
- Supports unlimited societies per deployment
- Transaction pagination (20 per page default, max 100)
- Bill generation for up to 1000 flats per batch

---

## 2. Architecture & Tech Stack

### 2.1 System Architecture

```
+------------------+     +------------------+     +------------------+
|                  |     |                  |     |                  |
|  React Web App   |---->|  FastAPI Backend  |---->|    MongoDB       |
|  (Port 3000)     |     |  (Port 8001)     |     |                  |
|                  |     |                  |     |                  |
+------------------+     +------------------+     +------------------+
        |                        |
        |                +------------------+
        |                |  Local File      |
+------------------+     |  Storage         |
|  Flutter App     |---->|  (/uploads)      |
|  (iOS/Android)   |     +------------------+
+------------------+
```

### 2.2 Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| **Backend** | Python + FastAPI | Python 3.11, FastAPI 0.115 |
| **Database** | MongoDB (via Motor async driver) | Motor 3.6 |
| **Auth** | JWT (python-jose) + bcrypt | HS256 algorithm |
| **Web Frontend** | React + Tailwind CSS + Shadcn UI | React 18, Tailwind 3.4 |
| **Mobile** | Flutter + Riverpod | Flutter 3.2+, Riverpod 2.5 |
| **Charts** | Recharts (web), fl_chart (mobile) | Latest |
| **Reports** | ReportLab (PDF), openpyxl (Excel) | Server-side generation |
| **File Storage** | Local filesystem | /app/backend/uploads/ |

### 2.3 Backend File Structure

```
/app/backend/
├── server.py                 # Main FastAPI app, middleware, seed endpoint
├── database.py               # MongoDB connection (Motor async client)
├── auth_utils.py             # JWT creation/verification, password hashing
├── models.py                 # All Pydantic request/response schemas
├── .env                      # Environment variables
├── requirements.txt          # Python dependencies
├── uploads/                  # Invoice/receipt file storage
└── routes/
    ├── __init__.py
    ├── auth.py               # POST /register, /login, GET /me
    ├── societies.py          # Society CRUD, flats, memberships, dashboard
    ├── transactions.py       # Transaction CRUD, categories, file upload
    ├── maintenance.py        # Bill generation, payments, ledger
    ├── approvals.py          # Approval list, approve, reject
    ├── reports.py            # Summary, categories, dues, PDF/Excel export
    └── notifications.py      # List, mark read, mark all read
```

### 2.4 Web Frontend File Structure

```
/app/frontend/src/
├── App.js                    # Router + AuthProvider + SocietyProvider
├── index.css                 # Dark theme CSS variables, animations
├── lib/
│   └── api.js                # Axios instance with auth interceptor
├── contexts/
│   ├── AuthContext.js         # Login/register/logout state
│   └── SocietyContext.js      # Society selection + role context
├── components/
│   ├── Layout.js              # Sidebar + Topbar shell
│   └── ui/                    # Shadcn UI components
└── pages/
    ├── Login.js               # Auth - login form
    ├── Register.js            # Auth - registration form
    ├── SocietySwitch.js       # Multi-society selector
    ├── Dashboard.js           # Stats + chart + recent transactions
    ├── Transactions.js        # Filtered + paginated list
    ├── AddTransaction.js      # Inward/outward creation form
    ├── Maintenance.js         # Bills table + generate + pay dialogs
    ├── Approvals.js           # Pending approvals + history
    ├── Reports.js             # Charts + tables + export
    ├── Notifications.js       # Notification center
    └── Members.js             # Member + flat management
```

### 2.5 Flutter App File Structure

```
/app/flutter_app/lib/
├── main.dart                              # Entry + ProviderScope
├── config/
│   ├── api_config.dart                   # API endpoint URLs
│   ├── app_theme.dart                    # Dark theme definition
│   └── routes.dart                       # Named routes + transitions
├── core/
│   └── constants.dart                    # Format helpers
├── models/                               # 7 data model files
├── services/
│   ├── api_service.dart                  # Dio + auth interceptor
│   └── storage_service.dart              # FlutterSecureStorage
├── providers/                            # 8 Riverpod providers
├── screens/                              # 11 screens in feature folders
└── widgets/                              # Reusable components
```

---

## 3. Database Design

### 3.1 MongoDB Collections

All collections use UUID strings as `id` fields (not ObjectId). All queries exclude `_id` from projections to ensure JSON serialization.

#### 3.1.1 `users`

| Field | Type | Description |
|-------|------|-------------|
| `id` | string (UUID) | Primary key |
| `name` | string | Full name |
| `email` | string | Unique email address |
| `phone` | string | Phone number |
| `password_hash` | string | bcrypt hashed password |
| `created_at` | string (ISO 8601) | Registration timestamp |

**Indexes**: `email` (unique), `id` (unique)

#### 3.1.2 `societies`

| Field | Type | Description |
|-------|------|-------------|
| `id` | string (UUID) | Primary key |
| `name` | string | Society name |
| `address` | string | Full address |
| `total_flats` | int | Total number of flats |
| `description` | string | Optional description |
| `approval_threshold` | float | Amount above which committee approval is required (default: 50000) |
| `created_at` | string (ISO 8601) | Creation timestamp |
| `created_by` | string (UUID) | User ID of creator |

**Indexes**: `id` (unique)

#### 3.1.3 `memberships` (User-Society Mapping)

| Field | Type | Description |
|-------|------|-------------|
| `id` | string (UUID) | Primary key |
| `user_id` | string (UUID) | References users.id |
| `society_id` | string (UUID) | References societies.id |
| `role` | string | `manager` / `member` / `committee` / `auditor` |
| `status` | string | `active` / `inactive` |
| `created_at` | string (ISO 8601) | Timestamp |

**Indexes**: Compound `(user_id, society_id)`
**Constraint**: One user can have one membership per society

#### 3.1.4 `flats`

| Field | Type | Description |
|-------|------|-------------|
| `id` | string (UUID) | Primary key |
| `society_id` | string (UUID) | References societies.id |
| `flat_number` | string | e.g., "A-101" |
| `floor` | int | Floor number |
| `wing` | string | Wing identifier |
| `area_sqft` | float | Area in square feet |
| `flat_type` | string | "1BHK" / "2BHK" / "3BHK" |

**Indexes**: `society_id`

#### 3.1.5 `flat_members` (Flat-User Mapping)

| Field | Type | Description |
|-------|------|-------------|
| `id` | string (UUID) | Primary key |
| `flat_id` | string (UUID) | References flats.id |
| `user_id` | string (UUID) | References users.id |
| `society_id` | string (UUID) | References societies.id |
| `relation_type` | string | `Owner` / `Family` / `Tenant` / `Partner` |
| `is_primary` | boolean | If true, receives maintenance bill responsibility |

**Indexes**: Compound `(flat_id, society_id)`
**Rule**: Only `is_primary=true` member gets billed

#### 3.1.6 `transactions`

| Field | Type | Description |
|-------|------|-------------|
| `id` | string (UUID) | Primary key |
| `society_id` | string (UUID) | References societies.id |
| `type` | string | `inward` / `outward` |
| `category` | string | Transaction category |
| `amount` | float | Transaction amount |
| `description` | string | Notes |
| `vendor_name` | string | Vendor/payee (outward only) |
| `payment_mode` | string | `cash` / `upi` / `bank` |
| `invoice_path` | string | Path to uploaded invoice |
| `date` | string | Transaction date (YYYY-MM-DD) |
| `created_by` | string (UUID) | Manager who created |
| `created_at` | string (ISO 8601) | Creation timestamp |
| `approval_status` | string | `approved` / `pending` / `rejected` |

**Indexes**: Compound `(society_id, created_at DESC)`

**Inward Categories**: Maintenance Payment, Donation, Interest Income, Parking Charges, Penalty/Fine, Other Income

**Outward Categories**: Security Salary, Lift AMC, Repairs & Maintenance, Electricity Bill, Water Bill, Vendor Payment, Garden Maintenance, Insurance, Legal Fees, Cleaning, Other Expense

#### 3.1.7 `maintenance_bills`

| Field | Type | Description |
|-------|------|-------------|
| `id` | string (UUID) | Primary key |
| `society_id` | string (UUID) | References societies.id |
| `flat_id` | string (UUID) | References flats.id |
| `flat_number` | string | Denormalized flat number |
| `member_id` | string (UUID) | Primary member's user ID |
| `month` | int | Bill month (1-12) |
| `year` | int | Bill year |
| `amount` | float | Bill amount |
| `due_date` | string | Due date (YYYY-MM-DD) |
| `late_fee` | float | Late fee amount |
| `status` | string | `pending` / `paid` / `overdue` / `partial` |
| `paid_amount` | float | Amount paid so far |
| `created_at` | string (ISO 8601) | Generation timestamp |

**Indexes**: Compound `(society_id, month, year)`

#### 3.1.8 `approvals`

| Field | Type | Description |
|-------|------|-------------|
| `id` | string (UUID) | Primary key |
| `transaction_id` | string (UUID) | References transactions.id |
| `society_id` | string (UUID) | References societies.id |
| `requested_by` | string (UUID) | Manager who created the transaction |
| `status` | string | `pending` / `approved` / `rejected` |
| `approved_by` | string (UUID) | Committee member who acted |
| `comments` | string | Approval/rejection comments |
| `created_at` | string (ISO 8601) | Request timestamp |

**Indexes**: Compound `(society_id, status)`

#### 3.1.9 `notifications`

| Field | Type | Description |
|-------|------|-------------|
| `id` | string (UUID) | Primary key |
| `society_id` | string (UUID) | References societies.id |
| `user_id` | string (UUID) | Target user |
| `title` | string | Notification title |
| `message` | string | Notification body |
| `type` | string | `system` / `billing` / `approval` |
| `read` | boolean | Read status |
| `created_at` | string (ISO 8601) | Timestamp |

**Indexes**: Compound `(user_id, read)`

### 3.2 Entity Relationship Diagram

```
users ─────────< memberships >───────── societies
  |                                         |
  |                                         |
  └──< flat_members >──── flats ────────────┘
                                            |
                          transactions ─────┘
                               |
                          approvals
                               
                     maintenance_bills ──── flats
                     
                     notifications ──────── users
```

---

## 4. Authentication & Authorization

### 4.1 Authentication Flow

```
┌─────────┐     POST /api/auth/login     ┌─────────┐
│ Client   │ ──────────────────────────> │ Backend  │
│          │ {email, password}            │          │
│          │                              │ 1. Find user by email
│          │                              │ 2. bcrypt.verify(pass)
│          │     {access_token, user}     │ 3. Create JWT
│          │ <────────────────────────── │          │
│          │                              └─────────┘
│          │
│          │  All subsequent requests:
│          │  Authorization: Bearer <token>
└─────────┘
```

### 4.2 JWT Token Structure

```json
{
  "sub": "user-uuid",
  "email": "user@example.com",
  "name": "User Name",
  "exp": 1740000000
}
```

| Parameter | Value |
|-----------|-------|
| Algorithm | HS256 |
| Expiry | 24 hours (1440 minutes) |
| Secret | `JWT_SECRET` environment variable |

### 4.3 Role-Based Authorization Matrix

| Endpoint | Manager | Member | Committee | Auditor |
|----------|---------|--------|-----------|---------|
| View Dashboard | Yes | Yes | Yes | Yes |
| View Transactions | Yes | Yes | Yes | Yes |
| Create Transaction | **Yes** | No | No | No |
| Generate Bills | **Yes** | No | No | No |
| Record Payment | **Yes** | No | No | No |
| Approve Expense | **Yes** | No | **Yes** | No |
| Reject Expense | **Yes** | No | **Yes** | No |
| View Reports | Yes | Yes | Yes | Yes |
| Export PDF/Excel | Yes | Yes | Yes | Yes |
| Add Member | **Yes** | No | No | No |
| Change Roles | **Yes** | No | No | No |
| View Notifications | Yes | Yes | Yes | Yes |
| View Own Bills Only | No | **Yes** | No | No |
| View All Bills | Yes | No | Yes | Yes |

### 4.4 Society Context Authorization

Every society-scoped endpoint verifies:
1. User is authenticated (valid JWT)
2. User has an **active** membership in the target society
3. User's role in that society permits the action

```python
async def verify_membership(user_id, society_id, required_roles=None):
    membership = await db.memberships.find_one({
        "user_id": user_id,
        "society_id": society_id,
        "status": "active"
    })
    if not membership:
        raise HTTPException(403, "Not a member of this society")
    if required_roles and membership["role"] not in required_roles:
        raise HTTPException(403, "Insufficient permissions")
    return membership
```

---

## 5. API Reference

**Base URL**: `{BACKEND_URL}/api`

All endpoints return JSON. Authentication required unless noted.

### 5.1 Auth Endpoints

#### `POST /api/auth/register`
Create new user account.

**Request Body:**
```json
{
  "name": "Vikram Sharma",
  "email": "vikram@example.com",
  "phone": "9876543210",
  "password": "securepass123"
}
```

**Response (200):**
```json
{
  "access_token": "eyJhbGciOiJI...",
  "token_type": "bearer",
  "user": {
    "id": "uuid",
    "name": "Vikram Sharma",
    "email": "vikram@example.com",
    "phone": "9876543210"
  }
}
```

**Errors:** `400` Email already registered

---

#### `POST /api/auth/login`
Authenticate existing user.

**Request Body:**
```json
{
  "email": "vikram@example.com",
  "password": "securepass123"
}
```

**Response (200):** Same as register response.

**Errors:** `401` Invalid credentials

---

#### `GET /api/auth/me`
Get current user profile. Requires auth header.

**Response (200):**
```json
{
  "id": "uuid",
  "name": "Vikram Sharma",
  "email": "vikram@example.com",
  "phone": "9876543210"
}
```

---

### 5.2 Society Endpoints

#### `GET /api/societies/`
List all societies the current user belongs to (with role info).

**Response (200):**
```json
[
  {
    "id": "uuid",
    "name": "Sunrise Apartments",
    "address": "Sector 42, Gurugram",
    "total_flats": 440,
    "description": "Premium residential society",
    "role": "manager",
    "membership_id": "uuid"
  }
]
```

---

#### `POST /api/societies/`
Create a new society. Creator automatically becomes Manager.

**Request Body:**
```json
{
  "name": "Sunrise Apartments",
  "address": "Sector 42, Gurugram",
  "total_flats": 440,
  "description": "Optional description",
  "approval_threshold": 50000
}
```

---

#### `GET /api/societies/{society_id}`
Get society details. Requires membership.

---

#### `GET /api/societies/{society_id}/dashboard`
Get dashboard data for the society.

**Response (200):**
```json
{
  "society_balance": 1250000,
  "total_inward": 3500000,
  "total_outward": 2250000,
  "pending_dues": 15,
  "pending_approvals": 3,
  "recent_transactions": [...],
  "monthly_trend": [
    {"month": "2026-01", "inward": 500000, "outward": 350000}
  ],
  "member_count": 10,
  "flat_count": 20
}
```

---

#### `GET /api/societies/{society_id}/flats`
List all flats in the society.

#### `POST /api/societies/{society_id}/flats`
Create a flat. **Manager only**.

**Request Body:**
```json
{
  "flat_number": "A-101",
  "floor": 1,
  "wing": "A",
  "area_sqft": 1050,
  "flat_type": "2BHK"
}
```

---

#### `GET /api/societies/{society_id}/members`
List all society members with user details and roles.

#### `POST /api/societies/{society_id}/members`
Add existing user to society. **Manager only**.

**Request Body:**
```json
{
  "email": "user@example.com",
  "role": "member"
}
```

**Errors:** `404` User not found, `400` Already a member

---

#### `PUT /api/societies/{society_id}/members/{membership_id}?role=committee`
Update member role. **Manager only**.

---

#### `GET /api/societies/{society_id}/flats/{flat_id}/members`
List members linked to a specific flat.

#### `POST /api/societies/{society_id}/flats/{flat_id}/members`
Link a user to a flat. **Manager only**.

**Request Body:**
```json
{
  "user_id": "uuid",
  "relation_type": "Owner",
  "is_primary": true
}
```

---

### 5.3 Transaction Endpoints

#### `GET /api/societies/{society_id}/transactions/categories`
Get available transaction categories (no auth required within society).

**Response:**
```json
{
  "inward": ["Maintenance Payment", "Donation", "Interest Income", ...],
  "outward": ["Security Salary", "Lift AMC", "Repairs & Maintenance", ...]
}
```

---

#### `GET /api/societies/{society_id}/transactions/?type=outward&category=&page=1&limit=20`
List transactions with optional filters and pagination.

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `type` | string | null | Filter: `inward` or `outward` |
| `category` | string | null | Filter by category name |
| `page` | int | 1 | Page number (1-based) |
| `limit` | int | 20 | Items per page (max 100) |

**Response (200):** Array of TransactionResponse objects.

---

#### `GET /api/societies/{society_id}/transactions/count?type=&category=`
Get total count for pagination.

**Response:** `{"count": 63}`

---

#### `POST /api/societies/{society_id}/transactions/`
Create a new transaction. **Manager only**.

**Request Body:**
```json
{
  "type": "outward",
  "category": "Repairs & Maintenance",
  "amount": 75000,
  "description": "Lift repair work",
  "vendor_name": "ABC Services",
  "payment_mode": "bank",
  "date": "2026-02-15"
}
```

**Business Logic:**
- If `type == "outward"` AND `amount >= society.approval_threshold`:
  - `approval_status` is set to `"pending"` (not `"approved"`)
  - An approval record is auto-created
  - Committee members receive notifications

**Response (200):** TransactionResponse with `approval_status` field.

---

#### `GET /api/societies/{society_id}/transactions/{txn_id}`
Get single transaction detail.

---

#### `POST /api/societies/{society_id}/transactions/upload`
Upload invoice/receipt file. **Manager only**.

**Request:** Multipart form data with `file` field.

**Response:** `{"filename": "uuid.pdf", "path": "/api/uploads/uuid.pdf"}`

---

### 5.4 Maintenance Endpoints

#### `POST /api/societies/{society_id}/maintenance/generate`
Generate monthly bills for all flats. **Manager only**.

**Request Body:**
```json
{
  "month": 3,
  "year": 2026,
  "amount_per_flat": 5000,
  "due_date": "2026-03-10",
  "late_fee": 500
}
```

**Business Logic:**
1. Checks if bills already exist for this month/year (prevents duplicates)
2. Creates one bill per flat in the society
3. Assigns `member_id` from the flat's primary member (`is_primary=true`)
4. Sends notification to each billed member

**Response:** `{"status": "success", "bills_created": 20}`

**Errors:** `400` Bills already generated for this month

---

#### `GET /api/societies/{society_id}/maintenance/bills?month=&year=&status=&flat_id=&page=1&limit=50`
List maintenance bills.

**Access Control:**
- **Members** can only see their own bills (`member_id` filter auto-applied)
- **Managers/Committee/Auditors** see all bills

---

#### `POST /api/societies/{society_id}/maintenance/pay`
Record a payment against a bill. **Manager only**.

**Request Body:**
```json
{
  "bill_id": "uuid",
  "amount_paid": 5000,
  "payment_mode": "upi"
}
```

**Business Logic:**
1. Adds `amount_paid` to existing `paid_amount`
2. Updates status: `paid` if fully paid, `partial` otherwise
3. Creates an inward transaction of category "Maintenance Payment"

---

#### `GET /api/societies/{society_id}/maintenance/ledger/{flat_id}`
Get payment history for a specific flat.

---

### 5.5 Approval Endpoints

#### `GET /api/societies/{society_id}/approvals/?status=pending`
List approval requests (all or filtered by status).

**Response includes** full transaction details nested in each approval.

---

#### `POST /api/societies/{society_id}/approvals/{approval_id}/approve`
Approve a pending expense. **Committee or Manager only**.

**Request Body:**
```json
{"comments": "Approved for lift repair"}
```

**Business Logic:**
1. Sets approval status to `"approved"`
2. Updates linked transaction's `approval_status` to `"approved"`
3. Sends notification to the requesting manager

---

#### `POST /api/societies/{society_id}/approvals/{approval_id}/reject`
Reject a pending expense. **Committee or Manager only**.

**Business Logic:**
1. Sets approval status to `"rejected"`
2. Updates linked transaction's `approval_status` to `"rejected"`
3. Sends notification with rejection reason

---

### 5.6 Report Endpoints

#### `GET /api/societies/{society_id}/reports/monthly-summary?year=2026`
Returns 12-month breakdown for the year.

**Response:** Array of 12 MonthlySummary objects with `total_inward`, `total_outward`, `net`, `transaction_count`.

---

#### `GET /api/societies/{society_id}/reports/category-spending?year=2026&month=`
Expense breakdown by category.

**Response:**
```json
[
  {"category": "Security Salary", "total": 120000, "count": 6, "percentage": 35.2},
  {"category": "Lift AMC", "total": 80000, "count": 2, "percentage": 23.5}
]
```

---

#### `GET /api/societies/{society_id}/reports/outstanding-dues`
All unpaid/partial maintenance bills.

---

#### `GET /api/societies/{society_id}/reports/annual-summary?year=2026`

**Response:**
```json
{
  "year": 2026,
  "total_income": 3500000,
  "total_expense": 2250000,
  "net_balance": 1250000,
  "total_billed": 500000,
  "total_collected": 350000,
  "collection_rate": 70.0,
  "transaction_count": 63
}
```

---

#### `GET /api/societies/{society_id}/reports/export/excel?year=2026`
Download Excel file with all transactions for the year.

**Response:** `.xlsx` file download.

---

#### `GET /api/societies/{society_id}/reports/export/pdf?year=2026`
Download PDF report with summary and transaction table.

**Response:** `.pdf` file download.

---

### 5.7 Notification Endpoints

#### `GET /api/notifications/?society_id=uuid`
List user's notifications (optionally filtered by society).

---

#### `GET /api/notifications/unread-count?society_id=uuid`
Get unread notification count.

**Response:** `{"count": 3}`

---

#### `PUT /api/notifications/{notification_id}/read`
Mark a single notification as read.

---

#### `POST /api/notifications/mark-all-read?society_id=uuid`
Mark all notifications as read.

**Response:** `{"marked": 5}`

---

### 5.8 Utility Endpoints

#### `GET /api/`
Health check.

**Response:** `{"message": "Society Financial Manager API", "version": "1.0.0"}`

---

#### `POST /api/seed`
Seed demo data (clears existing data first).

**Response:** Demo credentials and data summary.

---

#### `GET /api/uploads/{filename}`
Serve uploaded invoice/receipt files.

---

## 6. Business Logic & Workflows

### 6.1 Expense Approval Workflow

```
Manager creates outward transaction
         |
         v
  amount >= threshold? ──── No ──── Status: "approved" (done)
         |
        Yes
         |
         v
  Status: "pending"
  Auto-create approval record
  Notify committee members
         |
         v
  Committee reviews ──── Approve ──── Transaction status: "approved"
         |                              Notify manager
        Reject
         |
         v
  Transaction status: "rejected"
  Notify manager with reason
```

### 6.2 Maintenance Billing Workflow

```
Manager triggers "Generate Bills"
(month, year, amount_per_flat, due_date, late_fee)
         |
         v
  For each flat in society:
    1. Find primary flat member (is_primary=true)
    2. Create bill record (status: "pending")
    3. Send notification to primary member
         |
         v
  Manager records payment:
    1. Update bill's paid_amount
    2. Status = "paid" if fully paid, "partial" otherwise
    3. Auto-create inward transaction (category: "Maintenance Payment")
```

### 6.3 Multi-Society Role Resolution

```
User logs in
    |
    v
GET /api/societies/ ──── Returns all societies with role per society
    |
    v
User selects society ──── Role is set for this session
    |
    v
All UI elements adapt to the role:
  - Manager: Full CRUD, sidebar shows all options
  - Member: Read-only, sidebar shows limited options
  - Committee: Read + approve/reject
  - Auditor: Read-only, sees all data
    |
    v
User can switch society at any time ──── Role changes accordingly
```

### 6.4 Notification Triggers

| Event | Recipient(s) | Type |
|-------|-------------|------|
| Maintenance bill generated | Billed member (primary) | `billing` |
| High-value expense created | All committee members | `approval` |
| Expense approved | Requesting manager | `approval` |
| Expense rejected | Requesting manager (with reason) | `approval` |

---

## 7. Frontend - React Web App

### 7.1 State Management

| Context | Purpose | Stored In |
|---------|---------|-----------|
| `AuthContext` | User info, token, login/register/logout | `localStorage` (sfm_token, sfm_user) |
| `SocietyContext` | Current society, role, society list | `localStorage` (sfm_society) |

### 7.2 Route Map

| Path | Component | Auth | Society | Role Access |
|------|-----------|------|---------|-------------|
| `/login` | Login | No | No | All |
| `/register` | Register | No | No | All |
| `/switch-society` | SocietySwitch | Yes | No | All |
| `/` | Dashboard | Yes | Yes | All |
| `/transactions` | Transactions | Yes | Yes | All |
| `/transactions/add` | AddTransaction | Yes | Yes | Manager |
| `/maintenance` | Maintenance | Yes | Yes | All |
| `/approvals` | Approvals | Yes | Yes | All |
| `/reports` | Reports | Yes | Yes | All |
| `/notifications` | Notifications | Yes | Yes | All |
| `/members` | Members | Yes | Yes | All (Manager for CRUD) |

### 7.3 Design System

| Element | Value |
|---------|-------|
| Theme | Midnight Ledger (dark) |
| Background | `#0B0C10` |
| Card | `#15171E` |
| Primary | `#3B82F6` (Blue) |
| Success | `#10B981` (Green) |
| Warning | `#F59E0B` (Amber) |
| Danger | `#EF4444` (Red) |
| Heading Font | Manrope (600-800) |
| Financial Font | JetBrains Mono |
| Components | Shadcn UI (Card, Button, Input, Select, Dialog, Tabs, Badge, DropdownMenu) |
| Charts | Recharts (BarChart, PieChart) |
| Toast | Sonner |

### 7.4 Component Architecture

```
App.js
├── AuthProvider
│   └── SocietyProvider
│       └── BrowserRouter
│           ├── /login ──── Login (standalone)
│           ├── /register ──── Register (standalone)
│           ├── /switch-society ──── SocietySwitch (standalone)
│           └── Layout (sidebar + topbar)
│               ├── / ──── Dashboard
│               ├── /transactions ──── Transactions
│               ├── /transactions/add ──── AddTransaction
│               ├── /maintenance ──── Maintenance
│               ├── /approvals ──── Approvals
│               ├── /reports ──── Reports
│               ├── /notifications ──── Notifications
│               └── /members ──── Members
```

### 7.5 Key UI Features

| Feature | Implementation |
|---------|---------------|
| Society Switcher | Dropdown in topbar with role badges |
| Role-based Navigation | Different sidebar items per role |
| Financial Data Display | JetBrains Mono font, color-coded (+green / -red) |
| Pagination | Page controls on transactions list |
| Inline Filters | Select dropdowns for type/category filtering |
| Modal Dialogs | Generate bills, record payment, approve/reject |
| Responsive | Mobile sidebar with hamburger menu |
| Animations | Staggered fade-in-up on card grids |
| Glass Effect | Topbar with backdrop-filter blur |

---

## 8. Mobile - Flutter App

### 8.1 State Management (Riverpod)

| Provider | Type | Purpose |
|----------|------|---------|
| `authProvider` | `StateNotifierProvider<AuthNotifier, AuthState>` | Login, register, logout, token management |
| `societyProvider` | `StateNotifierProvider<SocietyNotifier, SocietyState>` | Society list, current selection, role |
| `dashboardProvider` | `FutureProvider.family<DashboardModel, String>` | Dashboard data per society |
| `transactionListProvider` | `StateNotifierProvider.family<..., String>` | Paginated transactions with filters |
| `transactionCategoriesProvider` | `FutureProvider.family<TransactionCategories, String>` | Category lists |
| `maintenanceBillsProvider` | `FutureProvider.family<List<MaintenanceBillModel>, String>` | Bills per society |
| `approvalsProvider` | `FutureProvider.family<List<ApprovalModel>, String>` | Approvals per society |
| `monthlySummaryProvider` | `FutureProvider.family<List<MonthlySummary>, (societyId, year)>` | Monthly report |
| `categorySpendingProvider` | `FutureProvider.family<List<CategorySpendingModel>, (societyId, year)>` | Category breakdown |
| `outstandingDuesProvider` | `FutureProvider.family<List<Map>, String>` | Unpaid bills |
| `annualSummaryProvider` | `FutureProvider.family<Map, (societyId, year)>` | Annual summary |
| `notificationProvider` | `StateNotifierProvider<NotificationNotifier, NotificationState>` | Notifications + unread count |
| `membersProvider` | `FutureProvider.family<List<MembershipModel>, String>` | Society members |
| `flatsProvider` | `FutureProvider.family<List<FlatModel>, String>` | Society flats |

### 8.2 Screen Map

| Screen | File | Features |
|--------|------|----------|
| Login | `screens/auth/login_screen.dart` | Email/password, demo credential taps, error display |
| Register | `screens/auth/register_screen.dart` | Name, email, phone, password/confirm |
| Society Switch | `screens/society/society_switch_screen.dart` | Animated society cards with role badges |
| Dashboard | `screens/dashboard/dashboard_screen.dart` | Stats grid, fl_chart bar chart, recent transactions |
| Transactions | `screens/transactions/transactions_screen.dart` | Filtered list, pagination, type filter bottom sheet |
| Add Transaction | `screens/transactions/add_transaction_screen.dart` | Tab bar (inward/outward), category dropdown, date picker |
| Maintenance | `screens/maintenance/maintenance_screen.dart` | Summary tiles, bills list, generate/pay dialogs |
| Approvals | `screens/approvals/approvals_screen.dart` | Pending cards with approve/reject, history list |
| Reports | `screens/reports/reports_screen.dart` | Tab bar (Monthly/Categories/Dues), bar chart, pie chart |
| Notifications | `screens/notifications/notifications_screen.dart` | Type-colored icons, mark read, unread indicator |
| Members | `screens/members/members_screen.dart` | Tab bar (Members/Flats), add member dialog |

### 8.3 Navigation Pattern

- **Drawer Navigation**: Role-based items
- **Named Routes**: All routes defined in `config/routes.dart`
- **Transitions**: FadeTransition for main routes, SlideTransition for sub-routes
- **Society Context**: Persisted in FlutterSecureStorage, loaded on app start

### 8.4 Key Flutter Packages

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management with providers |
| `dio` | HTTP client with interceptors |
| `flutter_secure_storage` | Encrypted token/user storage |
| `fl_chart` | Bar and pie charts |
| `google_fonts` | Manrope font family |
| `intl` | Number/date formatting (Indian locale) |

---

## 9. Seed Data & Demo Setup

### 9.1 Demo Users

| Name | Email | Password | Roles |
|------|-------|----------|-------|
| Vikram Sharma | vikram@demo.com | password123 | Manager (Sunrise), Member (Green Valley) |
| Priya Patel | priya@demo.com | password123 | Member (Sunrise), Manager (Green Valley) |
| Rajesh Kumar | rajesh@demo.com | password123 | Committee (Sunrise) |
| Anita Desai | anita@demo.com | password123 | Auditor (Sunrise) |
| Suresh Gupta | suresh@demo.com | password123 | Member (Sunrise) |
| Meera Joshi | meera@demo.com | password123 | Member (Sunrise) |
| Amit Singh | amit@demo.com | password123 | Member (Sunrise) |
| Kavita Reddy | kavita@demo.com | password123 | Member (Green Valley) |

### 9.2 Demo Societies

| Society | Flats | Threshold |
|---------|-------|-----------|
| Sunrise Apartments (Gurugram) | 440 (20 seeded) | Rs.50,000 |
| Green Valley Residency (Bangalore) | 220 (10 seeded) | Rs.25,000 |

### 9.3 Demo Data Volume

| Collection | Count |
|------------|-------|
| Users | 8 |
| Societies | 2 |
| Flats | 30 |
| Flat Members | 8 |
| Memberships | 10 |
| Transactions | 63 (60 approved + 3 pending) |
| Maintenance Bills | 10 |
| Approvals | 3 (pending) |
| Notifications | 4 |

---

## 10. Deployment & Configuration

### 10.1 Environment Variables

**Backend (`/app/backend/.env`):**

| Variable | Required | Description |
|----------|----------|-------------|
| `MONGO_URL` | Yes | MongoDB connection string |
| `DB_NAME` | Yes | Database name |
| `CORS_ORIGINS` | Yes | Allowed origins (comma-separated, or `*`) |
| `JWT_SECRET` | Yes | Secret key for JWT signing |
| `APPROVAL_THRESHOLD` | No | Global default (overridden per society) |
| `FIREBASE_SERVER_KEY` | No | Firebase push notification key |

**Frontend (`/app/frontend/.env`):**

| Variable | Required | Description |
|----------|----------|-------------|
| `REACT_APP_BACKEND_URL` | Yes | Full backend URL (with protocol) |

**Flutter (`lib/config/api_config.dart`):**

| Constant | Description |
|----------|-------------|
| `baseUrl` | Backend API base URL (update before build) |

### 10.2 Running the System

```bash
# Backend (FastAPI on port 8001)
cd /app/backend
pip install -r requirements.txt
uvicorn server:app --host 0.0.0.0 --port 8001

# Frontend (React on port 3000)
cd /app/frontend
yarn install
yarn start

# Flutter (iOS/Android)
cd /app/flutter_app
flutter pub get
flutter run

# Seed Demo Data
curl -X POST https://YOUR_URL/api/seed
```

### 10.3 MongoDB Indexes (Auto-created on seed)

```
users: email (unique), id (unique)
societies: id (unique)
memberships: (user_id, society_id) compound
flats: society_id
flat_members: (flat_id, society_id) compound
transactions: (society_id, created_at DESC) compound
maintenance_bills: (society_id, month, year) compound
approvals: (society_id, status) compound
notifications: (user_id, read) compound
```

---

## 11. Future Roadmap

### P1 - Next Phase
- Invoice/receipt file upload with attachment to transactions
- Firebase push notifications integration
- Flat-member assignment UI (web + mobile)
- Society creation from UI
- Member ledger detail view per flat

### P2 - Enhancement Phase
- Advanced full-text search across transactions
- Bulk bill generation with variable amounts per flat
- Email notifications for dues (SendGrid/SMTP)
- Audit trail / activity log for all financial actions
- Society settings page (threshold, name, address)
- Payment gateway integration (UPI/Razorpay) for member self-service
- Multi-tenant whitelabeling

### P3 - Scale Phase
- Admin super-panel for SaaS operator
- Subscription/billing for society onboarding
- Analytics dashboard with trend predictions
- OCR for invoice auto-extraction
- Bulk data import (CSV) for migration from other systems

---

*Document generated: February 2026 | SocietyFin v1.0.0*
