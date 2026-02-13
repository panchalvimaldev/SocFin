# SocietyFin - Flutter Mobile App

## Society Financial Management App (iOS + Android)

A production-ready mobile application built with **Flutter** and **Riverpod** state management that connects to the SocietyFin FastAPI backend.

## Architecture & Folder Structure

```
lib/
├── main.dart                          # App entry point + ProviderScope
├── config/
│   ├── api_config.dart               # All API endpoint URLs (configure here)
│   ├── app_theme.dart                # Dark theme (Midnight Ledger design)
│   └── routes.dart                   # Named routes + transitions
├── core/
│   └── constants.dart                # Helpers: formatCurrency, formatDate, timeAgo
├── models/
│   ├── user_model.dart               # User + AuthResponse
│   ├── society_model.dart            # Society + Flat + Membership
│   ├── transaction_model.dart        # Transaction + Categories
│   ├── maintenance_model.dart        # MaintenanceBill
│   ├── approval_model.dart           # Approval
│   ├── notification_model.dart       # Notification
│   └── dashboard_model.dart          # Dashboard + Reports models
├── services/
│   ├── api_service.dart              # Dio HTTP client with auth interceptor
│   └── storage_service.dart          # FlutterSecureStorage wrapper
├── providers/
│   ├── auth_provider.dart            # AuthNotifier (login/register/logout)
│   ├── society_provider.dart         # SocietyNotifier + members/flats providers
│   ├── dashboard_provider.dart       # FutureProvider for dashboard data
│   ├── transaction_provider.dart     # StateNotifier for transactions + categories
│   ├── maintenance_provider.dart     # FutureProvider for bills
│   ├── approval_provider.dart        # FutureProvider for approvals
│   ├── report_provider.dart          # Providers for all report types
│   └── notification_provider.dart    # NotificationNotifier with mark read
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart         # Login with demo credentials
│   │   └── register_screen.dart      # Registration
│   ├── society/
│   │   └── society_switch_screen.dart # Multi-society selector
│   ├── dashboard/
│   │   └── dashboard_screen.dart     # Stats + chart + recent transactions
│   ├── transactions/
│   │   ├── transactions_screen.dart  # List with filters + pagination
│   │   └── add_transaction_screen.dart # Inward/Outward form
│   ├── maintenance/
│   │   └── maintenance_screen.dart   # Bills + generate + record payment
│   ├── approvals/
│   │   └── approvals_screen.dart     # Approve/reject workflow
│   ├── reports/
│   │   └── reports_screen.dart       # Charts + categories + dues
│   ├── notifications/
│   │   └── notifications_screen.dart # Notification center
│   └── members/
│       └── members_screen.dart       # Members + flats management
└── widgets/
    ├── common/
    │   └── loading_widget.dart       # Loading, Empty, Error states
    ├── dashboard/
    │   └── stat_card.dart            # Reusable stat card
    └── navigation/
        └── app_drawer.dart           # Role-based navigation drawer
```

## State Management: Riverpod

| Provider | Type | Purpose |
|----------|------|---------|
| `authProvider` | `StateNotifierProvider` | Auth state (login/register/logout) |
| `societyProvider` | `StateNotifierProvider` | Society selection + role context |
| `dashboardProvider` | `FutureProvider.family` | Dashboard data by society ID |
| `transactionListProvider` | `StateNotifierProvider.family` | Paginated transactions with filters |
| `transactionCategoriesProvider` | `FutureProvider.family` | Inward/outward categories |
| `maintenanceBillsProvider` | `FutureProvider.family` | Maintenance bills |
| `approvalsProvider` | `FutureProvider.family` | Approval requests |
| `monthlySummaryProvider` | `FutureProvider.family` | Monthly report data |
| `categorySpendingProvider` | `FutureProvider.family` | Category breakdown |
| `notificationProvider` | `StateNotifierProvider` | Notifications with unread count |
| `membersProvider` | `FutureProvider.family` | Society members |
| `flatsProvider` | `FutureProvider.family` | Society flats |

## Setup Instructions

### Prerequisites
- Flutter SDK >= 3.2.0
- Dart >= 3.2.0
- Xcode (for iOS)
- Android Studio (for Android)

### 1. Clone & Configure

```bash
# Copy the flutter_app folder to your local machine
cd flutter_app

# Configure the backend URL
# Edit lib/config/api_config.dart and update:
static const String baseUrl = 'https://YOUR_BACKEND_URL/api';
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run on Device/Emulator

```bash
# iOS
flutter run -d ios

# Android
flutter run -d android

# Both platforms
flutter run
```

### 4. Build for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## Demo Credentials

| Role | Email | Password |
|------|-------|----------|
| Manager (Sunrise) | vikram@demo.com | password123 |
| Committee (Sunrise) | rajesh@demo.com | password123 |
| Auditor (Sunrise) | anita@demo.com | password123 |
| Manager (Green Valley) | priya@demo.com | password123 |

## Features

- **Multi-Society**: Switch between societies, each with different roles
- **Role-Based UI**: Manager sees add/edit controls; Members get read-only views
- **Dashboard**: Balance stats, monthly trend chart, recent transactions
- **Transactions**: Filtered list with pagination, inward/outward creation
- **Maintenance**: Bill generation, payment recording, due tracking
- **Approvals**: Committee workflow for high-value expenses
- **Reports**: Monthly charts, category pie chart, outstanding dues
- **Notifications**: In-app notifications with mark read
- **Members**: Society member management with role assignment
- **Dark Theme**: Midnight Ledger design system throughout

## Key Packages

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_riverpod | ^2.5.1 | State management |
| dio | ^5.4.3 | HTTP client |
| flutter_secure_storage | ^9.2.2 | Secure token storage |
| fl_chart | ^0.68.0 | Bar charts + Pie charts |
| google_fonts | ^6.2.1 | Manrope font family |
| intl | ^0.19.0 | Number/date formatting |
