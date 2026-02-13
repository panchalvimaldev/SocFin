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


class SocietyUpdate(BaseModel):
    name: Optional[str] = None
    address: Optional[str] = None
    total_flats: Optional[int] = None
    description: Optional[str] = None
    approval_threshold: Optional[float] = None


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


# ─── Maintenance Settings ────────────────────────────
class MaintenanceSettingsCreate(BaseModel):
    default_rate_per_sqft: float = 5.0
    billing_cycle: str = "monthly"  # monthly, quarterly, yearly
    due_date_day: int = 10
    late_fee_amount: float = 0
    late_fee_type: str = "flat"  # flat, percentage
    is_discount_scheme_enabled: bool = True


class MaintenanceSettingsResponse(BaseModel):
    id: str
    society_id: str
    default_rate_per_sqft: float
    billing_cycle: str
    due_date_day: int
    late_fee_amount: float
    late_fee_type: str
    is_discount_scheme_enabled: bool
    updated_at: str = ""


# ─── Maintenance Discount Scheme ─────────────────────
class DiscountSchemeCreate(BaseModel):
    scheme_name: str
    eligible_months: int = 12
    free_months: int = 1
    discount_type: str = "free_months"  # free_months, percentage, flat
    discount_value: float = 0  # Used for percentage or flat discount
    is_active: bool = True


class DiscountSchemeResponse(BaseModel):
    id: str
    society_id: str
    scheme_name: str
    eligible_months: int
    free_months: int
    discount_type: str
    discount_value: float
    is_active: bool
    created_at: str


# ─── Maintenance Bill (Enhanced) ─────────────────────
class GenerateBillsRequest(BaseModel):
    bill_period_type: str = "monthly"  # monthly, yearly
    month: Optional[int] = None  # Required for monthly
    year: int
    apply_discount_scheme: bool = False
    discount_scheme_id: Optional[str] = None


class MaintenanceBillResponse(BaseModel):
    id: str
    society_id: str
    flat_id: str
    flat_number: str = ""
    wing: str = ""
    primary_user_id: str = ""
    primary_user_name: str = ""
    bill_period_type: str = "monthly"
    month: Optional[int] = None
    year: int
    area_sqft: float = 0
    rate_per_sqft: float = 0
    total_before_discount: float = 0
    discount_applied: float = 0
    discount_scheme_id: Optional[str] = None
    discount_scheme_name: str = ""
    final_payable_amount: float = 0
    late_fee: float = 0
    due_date: str = ""
    status: str = "pending"  # pending, paid, partial, overdue
    paid_amount: float = 0
    created_at: str = ""


class BillPreviewResponse(BaseModel):
    total_flats: int
    total_area_sqft: float
    rate_per_sqft: float
    total_collection_before_discount: float
    estimated_discount: float
    total_collection_after_discount: float
    bills_preview: List[dict] = []


# ─── Member Ledger Entry ─────────────────────────────
class LedgerEntryResponse(BaseModel):
    id: str
    society_id: str
    flat_id: str
    flat_number: str = ""
    user_id: str
    user_name: str = ""
    entry_date: str
    entry_type: str  # bill_generated, payment_received, discount_applied, late_fee, adjustment
    reference_id: str = ""
    reference_type: str = ""  # bill, payment
    debit_amount: float = 0
    credit_amount: float = 0
    balance_after_entry: float = 0
    notes: str = ""


class LedgerSummaryResponse(BaseModel):
    flat_id: str
    flat_number: str
    primary_user_name: str
    total_billed: float
    total_paid: float
    total_discount: float
    outstanding_balance: float
    last_payment_date: Optional[str] = None
    entries: List[LedgerEntryResponse] = []


# ─── Maintenance Payment ─────────────────────────────
class RecordPaymentRequest(BaseModel):
    flat_id: str
    bill_ids: List[str] = []  # Empty for bulk/annual payment
    amount_paid: float
    payment_mode: str = "upi"  # upi, cash, bank, cheque
    payment_date: str = ""
    transaction_reference: str = ""
    remarks: str = ""
    is_annual_payment: bool = False
    discount_scheme_id: Optional[str] = None


class PaymentResponse(BaseModel):
    id: str
    society_id: str
    flat_id: str
    flat_number: str = ""
    bill_ids: List[str] = []
    paid_by_user_id: str
    paid_by_user_name: str = ""
    amount_paid: float
    discount_applied: float = 0
    payment_mode: str
    payment_date: str
    receipt_number: str
    transaction_reference: str = ""
    remarks: str = ""
    created_at: str


class ReceiptResponse(BaseModel):
    receipt_number: str
    society_name: str
    society_address: str
    flat_number: str
    owner_name: str
    period_covered: str
    amount_before_discount: float
    discount_applied: float
    late_fee: float
    final_paid_amount: float
    payment_mode: str
    payment_date: str
    transaction_reference: str
    generated_at: str


# ─── Annual Payment Preview ──────────────────────────
class AnnualPaymentPreviewRequest(BaseModel):
    flat_id: str
    year: int
    discount_scheme_id: Optional[str] = None


class AnnualPaymentPreviewResponse(BaseModel):
    flat_id: str
    flat_number: str
    area_sqft: float
    rate_per_sqft: float
    monthly_amount: float
    total_months: int
    total_before_discount: float
    discount_scheme_name: str = ""
    free_months: int = 0
    discount_amount: float = 0
    final_payable: float = 0
    pending_months: List[int] = []
    already_paid_months: List[int] = []


# ─── Collection Dashboard ────────────────────────────
class CollectionDashboardResponse(BaseModel):
    total_flats: int
    paid_flats: int
    pending_flats: int
    overdue_flats: int
    total_billed: float
    total_collected: float
    total_outstanding: float
    collection_percentage: float
    month_wise_collection: List[dict] = []
    recent_payments: List[dict] = []


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
