import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/theme.dart';
import 'config/api_config.dart';
import 'controllers/auth_controller.dart';
import 'controllers/society_controller.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/society_switch_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/maintenance_screen.dart';
import 'screens/approvals_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/members_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SocietyFinanceApp());
}

class SocietyFinanceApp extends StatelessWidget {
  const SocietyFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controllers
    Get.put(AuthController(), permanent: true);
    Get.put(SocietyController(), permanent: true);

    return GetMaterialApp(
      title: 'SocietyFin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/register', page: () => const RegisterScreen()),
        GetPage(name: '/switch-society', page: () => const SocietySwitchScreen()),
        GetPage(name: '/dashboard', page: () => const DashboardScreen()),
        GetPage(name: '/transactions', page: () => const TransactionsScreen()),
        GetPage(name: '/transactions/add', page: () => const AddTransactionScreen()),
        GetPage(name: '/maintenance', page: () => const MaintenanceScreen()),
        GetPage(name: '/approvals', page: () => const ApprovalsScreen()),
        GetPage(name: '/reports', page: () => const ReportsScreen()),
        GetPage(name: '/notifications', page: () => const NotificationsScreen()),
        GetPage(name: '/members', page: () => const MembersScreen()),
      ],
    );
  }
}
