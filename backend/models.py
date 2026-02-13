from pydantic import BaseModel, Field
from typing import Optional, List


# ─── Auth ────────────────────────────────────────────
class UserCreate(BaseModel):
    name: str
    email: str
    phone: str = ""
    password: str


class UserLogin(BaseModel):
    email: str
    password: str


class UserResponse(BaseModel):
    id: str
    name: str
    email: str
    phone: str = ""


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


# ─── Society ─────────────────────────────────────────
class SocietyCreate(BaseModel):
    name: str
    address: str
    total_flats: int = 0
    description: str = ""
    approval_threshold: float = 50000


class SocietyResponse(BaseModel):
    id: str
    name: str
    address: str
    total_flats: int
    description: str
    approval_threshold: float = 50000
    created_at: str
    created_by: str


class SocietyWithRole(BaseModel):
    id: str
    name: str
    address: str
    total_flats: int
    description: str
    role: str
    membership_id: str


# ─── Membership ──────────────────────────────────────
class MembershipCreate(BaseModel):
    email: str
    role: str = "member"


class MembershipResponse(BaseModel):
    id: str
    user_id: str
    society_id: str
    role: str
    status: str
    user_name: str = ""
    user_email: str = ""


# ─── Flat ────────────────────────────────────────────
class FlatCreate(BaseModel):
    flat_number: str
    floor: int = 0
    wing: str = ""
    area_sqft: float = 0
    flat_type: str = ""


class FlatResponse(BaseModel):
    id: str
    society_id: str
    flat_number: str
    floor: int = 0
    wing: str = ""
    area_sqft: float = 0
    flat_type: str = ""


# ─── Flat Member ─────────────────────────────────────
class FlatMemberCreate(BaseModel):
    user_id: str
    relation_type: str = "Owner"
    is_primary: bool = False


class FlatMemberResponse(BaseModel):
    id: str
    flat_id: str
    user_id: str
    society_id: str
    relation_type: str
    is_primary: bool
    user_name: str = ""
    user_email: str = ""


# ─── Transaction ─────────────────────────────────────
class TransactionCreate(BaseModel):
    type: str
    category: str
    amount: float
    description: str = ""
    vendor_name: str = ""
    payment_mode: str = "bank"
    invoice_path: str = ""
    date: str = ""


class TransactionResponse(BaseModel):
    id: str
    society_id: str
    type: str
    category: str
    amount: float
    description: str
    vendor_name: str
    payment_mode: str
    invoice_path: str
    created_by: str
    created_by_name: str = ""
    date: str = ""
    created_at: str
    approval_status: str = "approved"


# ─── Maintenance ─────────────────────────────────────
class GenerateBillsRequest(BaseModel):
    month: int
    year: int
    amount_per_flat: float
    due_date: str
    late_fee: float = 0


class MaintenanceBillResponse(BaseModel):
    id: str
    society_id: str
    flat_id: str
    flat_number: str = ""
    member_id: str = ""
    member_name: str = ""
    month: int
    year: int
    amount: float
    due_date: str
    late_fee: float = 0
    status: str = "pending"
    paid_amount: float = 0
    created_at: str = ""


class RecordPaymentRequest(BaseModel):
    bill_id: str
    amount_paid: float
    payment_mode: str = "bank"


# ─── Approval ────────────────────────────────────────
class ApprovalResponse(BaseModel):
    id: str
    transaction_id: str
    transaction: dict = {}
    requested_by: str
    requested_by_name: str = ""
    status: str
    approved_by: str = ""
    approved_by_name: str = ""
    comments: str = ""
    created_at: str


class ApprovalAction(BaseModel):
    comments: str = ""


# ─── Notification ────────────────────────────────────
class NotificationResponse(BaseModel):
    id: str
    society_id: str
    user_id: str
    title: str
    message: str
    type: str
    read: bool = False
    created_at: str


# ─── Reports ─────────────────────────────────────────
class MonthlySummary(BaseModel):
    month: int
    year: int
    total_inward: float
    total_outward: float
    net: float
    transaction_count: int


class CategorySpending(BaseModel):
    category: str
    total: float
    count: int
    percentage: float = 0


class DashboardData(BaseModel):
    society_balance: float = 0
    total_inward: float = 0
    total_outward: float = 0
    pending_dues: int = 0
    pending_approvals: int = 0
    recent_transactions: List[dict] = []
    monthly_trend: List[dict] = []
    member_count: int = 0
    flat_count: int = 0
