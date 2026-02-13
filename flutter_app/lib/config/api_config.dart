class ApiConfig {
  // ══════════════════════════════════════════════════════════
  // CHANGE THIS to your backend URL before running the app
  // ══════════════════════════════════════════════════════════
  static const String baseUrl = 'https://community-accounting.preview.emergentagent.com/api';

  // Auth
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String me = '$baseUrl/auth/me';

  // Societies
  static String societies = '$baseUrl/societies/';
  static String society(String id) => '$baseUrl/societies/$id';
  static String dashboard(String id) => '$baseUrl/societies/$id/dashboard';

  // Flats
  static String flats(String societyId) => '$baseUrl/societies/$societyId/flats';

  // Members
  static String members(String societyId) => '$baseUrl/societies/$societyId/members';
  static String updateMember(String societyId, String memId) =>
      '$baseUrl/societies/$societyId/members/$memId';

  // Transactions
  static String transactions(String societyId) =>
      '$baseUrl/societies/$societyId/transactions/';
  static String transactionCount(String societyId) =>
      '$baseUrl/societies/$societyId/transactions/count';
  static String transactionCategories(String societyId) =>
      '$baseUrl/societies/$societyId/transactions/categories';
  static String transaction(String societyId, String txnId) =>
      '$baseUrl/societies/$societyId/transactions/$txnId';

  // Maintenance
  static String maintenanceBills(String societyId) =>
      '$baseUrl/societies/$societyId/maintenance/bills';
  static String generateBills(String societyId) =>
      '$baseUrl/societies/$societyId/maintenance/generate';
  static String recordPayment(String societyId) =>
      '$baseUrl/societies/$societyId/maintenance/pay';
  static String flatLedger(String societyId, String flatId) =>
      '$baseUrl/societies/$societyId/maintenance/ledger/$flatId';

  // Approvals
  static String approvals(String societyId) =>
      '$baseUrl/societies/$societyId/approvals/';
  static String approveExpense(String societyId, String approvalId) =>
      '$baseUrl/societies/$societyId/approvals/$approvalId/approve';
  static String rejectExpense(String societyId, String approvalId) =>
      '$baseUrl/societies/$societyId/approvals/$approvalId/reject';

  // Reports
  static String monthlySummary(String societyId) =>
      '$baseUrl/societies/$societyId/reports/monthly-summary';
  static String categorySpending(String societyId) =>
      '$baseUrl/societies/$societyId/reports/category-spending';
  static String outstandingDues(String societyId) =>
      '$baseUrl/societies/$societyId/reports/outstanding-dues';
  static String annualSummary(String societyId) =>
      '$baseUrl/societies/$societyId/reports/annual-summary';
  static String exportExcel(String societyId) =>
      '$baseUrl/societies/$societyId/reports/export/excel';
  static String exportPdf(String societyId) =>
      '$baseUrl/societies/$societyId/reports/export/pdf';

  // Notifications
  static String notifications = '$baseUrl/notifications/';
  static String unreadCount = '$baseUrl/notifications/unread-count';
  static String markRead(String id) => '$baseUrl/notifications/$id/read';
  static String markAllRead = '$baseUrl/notifications/mark-all-read';

  // Seed
  static String seed = '$baseUrl/seed';
}
