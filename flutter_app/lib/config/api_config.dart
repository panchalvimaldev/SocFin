/// ═══════════════════════════════════════════════════════════
/// CHANGE [baseUrl] to your backend URL before running the app.
/// ═══════════════════════════════════════════════════════════
class ApiConfig {
  static const String baseUrl =
      'https://flatsfinance.preview.emergentagent.com/api';

  // ── Auth ──────────────────────────────────────────────────
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String me = '$baseUrl/auth/me';

  // ── Societies ─────────────────────────────────────────────
  static const String societies = '$baseUrl/societies/';
  static String society(String id) => '$baseUrl/societies/$id';
  static String dashboard(String id) => '$baseUrl/societies/$id/dashboard';
  static String flats(String id) => '$baseUrl/societies/$id/flats';
  static String members(String id) => '$baseUrl/societies/$id/members';
  static String updateMember(String sId, String mId) =>
      '$baseUrl/societies/$sId/members/$mId';

  // ── Transactions ──────────────────────────────────────────
  static String transactions(String id) =>
      '$baseUrl/societies/$id/transactions/';
  static String transactionCount(String id) =>
      '$baseUrl/societies/$id/transactions/count';
  static String transactionCategories(String id) =>
      '$baseUrl/societies/$id/transactions/categories';

  // ── Maintenance ───────────────────────────────────────────
  static String maintenanceBills(String id) =>
      '$baseUrl/societies/$id/maintenance/bills';
  static String generateBills(String id) =>
      '$baseUrl/societies/$id/maintenance/generate';
  static String recordPayment(String id) =>
      '$baseUrl/societies/$id/maintenance/pay';

  // ── Approvals ─────────────────────────────────────────────
  static String approvals(String id) =>
      '$baseUrl/societies/$id/approvals/';
  static String approve(String sId, String aId) =>
      '$baseUrl/societies/$sId/approvals/$aId/approve';
  static String reject(String sId, String aId) =>
      '$baseUrl/societies/$sId/approvals/$aId/reject';

  // ── Reports ───────────────────────────────────────────────
  static String monthlySummary(String id) =>
      '$baseUrl/societies/$id/reports/monthly-summary';
  static String categorySpending(String id) =>
      '$baseUrl/societies/$id/reports/category-spending';
  static String outstandingDues(String id) =>
      '$baseUrl/societies/$id/reports/outstanding-dues';
  static String annualSummary(String id) =>
      '$baseUrl/societies/$id/reports/annual-summary';
  static String exportExcel(String id) =>
      '$baseUrl/societies/$id/reports/export/excel';
  static String exportPdf(String id) =>
      '$baseUrl/societies/$id/reports/export/pdf';

  // ── Notifications ─────────────────────────────────────────
  static const String notifications = '$baseUrl/notifications/';
  static const String unreadCount = '$baseUrl/notifications/unread-count';
  static String markRead(String id) => '$baseUrl/notifications/$id/read';
  static const String markAllRead = '$baseUrl/notifications/mark-all-read';

  // ── Seed ──────────────────────────────────────────────────
  static const String seed = '$baseUrl/seed';
}
