import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/society/society_switch_screen.dart';
import '../screens/society/create_society_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/transactions/add_transaction_screen.dart';
import '../screens/maintenance/maintenance_screen.dart';
import '../screens/maintenance/flat_ledger_screen.dart';
import '../screens/approvals/approvals_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/members/members_screen.dart';
import '../screens/settings/society_settings_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String switchSociety = '/switch-society';
  static const String createSociety = '/create-society';
  static const String dashboard = '/dashboard';
  static const String transactions = '/transactions';
  static const String addTransaction = '/transactions/add';
  static const String maintenance = '/maintenance';
  static const String flatLedger = '/flat-ledger';
  static const String approvals = '/approvals';
  static const String reports = '/reports';
  static const String notifications = '/notifications';
  static const String members = '/members';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _fade(const LoginScreen());
      case register:
        return _fade(const RegisterScreen());
      case switchSociety:
        return _fade(const SocietySwitchScreen());
      case createSociety:
        return _slide(const CreateSocietyScreen());
      case dashboard:
        return _fade(const DashboardScreen());
      case transactions:
        return _fade(const TransactionsScreen());
      case addTransaction:
        return _slide(const AddTransactionScreen());
      case maintenance:
        return _fade(const MaintenanceScreen());
      case flatLedger:
        final args = settings.arguments as Map<String, String>?;
        return _slide(FlatLedgerScreen(
          flatId: args?['flatId'] ?? '',
          flatNumber: args?['flatNumber'] ?? '',
        ));
      case approvals:
        return _fade(const ApprovalsScreen());
      case reports:
        return _fade(const ReportsScreen());
      case notifications:
        return _fade(const NotificationsScreen());
      case members:
        return _fade(const MembersScreen());
      case AppRoutes.settings:
        return _fade(const SocietySettingsScreen());
      default:
        return _fade(const LoginScreen());
    }
  }

  static PageRouteBuilder _fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  static PageRouteBuilder _slide(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
