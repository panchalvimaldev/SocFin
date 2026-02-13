# Society Financial Management Application - PRD

## Original Problem Statement
Build a production-ready scalable society finance SaaS product supporting multiple societies, multi-member flats, maintenance billing, transaction management, approval workflows, reports, and role-based access.

## Architecture
- **Frontend**: React + Tailwind CSS + Shadcn UI (Midnight Ledger dark theme)
- **Backend**: FastAPI (Python) + MongoDB via Motor (async)
- **Auth**: JWT-based with email/password
- **File Storage**: Local uploads directory

## User Personas
1. **Society Manager** - Records all inward/outward transactions, generates bills, manages members
2. **Member** - Views transactions, bills, receipts, reports
3. **Committee Member** - Approves/rejects large expenses, views reports
4. **Auditor** - Read-only full access to all financial data

## Core Requirements
- Multi-society membership (one user can belong to multiple societies with different roles)
- Multi-member flats (Owner, Family, Tenant, Partner)
- Role-based access control (Manager, Member, Committee, Auditor)
- Society switching within the same app
- Maintenance billing with flat-wise charges
- Transaction management with inward/outward categories
- Expense approval workflow (configurable threshold)
- Reports with PDF/Excel export
- In-app notifications

## What's Been Implemented (Feb 2026)

### Backend (12 files)
- JWT authentication (register, login, profile)
- Society CRUD with membership management
- Flat management with multi-member support
- Transaction management (inward/outward) with pagination & filters
- Maintenance bill generation, payment recording, ledger
- Expense approval workflow (auto-trigger above threshold)
- Reports (monthly summary, category spending, outstanding dues, annual summary)
- PDF/Excel export
- Notification system (in-app)
- Comprehensive seed data (8 users, 2 societies, 30 flats, 63 transactions, 10 bills)

### Frontend (12 pages + components)
- Login & Register pages (dark theme with abstract background)
- Society Switch screen (multi-society selection)
- Dashboard with Bento grid (stats cards, monthly trend chart, recent transactions)
- Transactions page (table with filters, pagination)
- Add Transaction form (inward/outward tabs)
- Maintenance Billing (bills table, generate dialog, record payment dialog)
- Expense Approvals (pending list with approve/reject, history table)
- Reports (monthly charts, category pie chart, outstanding dues, PDF/Excel export)
- Notifications center (mark read, mark all read)
- Members management (member list, role management, flat listing)
- Responsive sidebar layout with role-based navigation

## Demo Credentials
- vikram@demo.com / password123 (Manager in Sunrise, Member in Green Valley)
- priya@demo.com / password123 (Member in Sunrise, Manager in Green Valley)
- rajesh@demo.com / password123 (Committee in Sunrise)
- anita@demo.com / password123 (Auditor in Sunrise)

## Prioritized Backlog

### P0 (Done)
- [x] Authentication + Multi-society membership
- [x] Dashboard with financial overview
- [x] Transaction management
- [x] Maintenance billing
- [x] Expense approval workflow
- [x] Reports with charts
- [x] Notifications
- [x] Member management

### P0.5 (Done - Feb 2026)
- [x] Flutter Mobile App (Riverpod) - Complete codebase at /app/flutter_app/
  - 37 files, clean architecture, Riverpod state management
  - All 11 screens: Login, Register, Society Switch, Dashboard, Transactions, Add Transaction, Maintenance, Approvals, Reports, Notifications, Members
  - Midnight Ledger dark theme, fl_chart charts, role-based navigation drawer

### P0.6 (Done - Feb 2026) - 4 New Features
- [x] **Society Creation** - Users can create new societies from Society Switch page
  - Web: CreateSociety.js with form validation
  - Flutter: create_society_screen.dart with Riverpod
  - Backend: POST /api/societies/ (creator becomes manager)
- [x] **Society Settings** - Managers can edit society configuration
  - Web: Settings.js page with editable form
  - Flutter: society_settings_screen.dart 
  - Backend: PUT /api/societies/{id} (manager-only)
- [x] **Member Assignment to Flats** - Link members to flats with relationship types
  - Web: FlatMembers.js page with flat selection and member linking
  - Flutter: Updated members_screen.dart with flat navigation
  - Backend: GET/POST/DELETE /api/societies/{id}/flats/{flat_id}/members
- [x] **Flat Ledger View** - Detailed payment history per flat
  - Web: FlatLedger.js showing billing history, paid/due amounts
  - Flutter: flat_ledger_screen.dart with summary cards
  - Backend: GET /api/societies/{id}/maintenance/ledger/{flat_id}

### P1 (Next)
- [ ] Invoice/receipt file upload attached to transactions
- [ ] Push notifications (Firebase integration - credentials required)
- [ ] PDF/Excel report export verification
