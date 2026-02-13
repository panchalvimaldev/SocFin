class DashboardModel {
  final double societyBalance;
  final double totalInward;
  final double totalOutward;
  final int pendingDues;
  final int pendingApprovals;
  final List<Map<String, dynamic>> recentTransactions;
  final List<Map<String, dynamic>> monthlyTrend;
  final int memberCount;
  final int flatCount;

  DashboardModel({
    this.societyBalance = 0,
    this.totalInward = 0,
    this.totalOutward = 0,
    this.pendingDues = 0,
    this.pendingApprovals = 0,
    this.recentTransactions = const [],
    this.monthlyTrend = const [],
    this.memberCount = 0,
    this.flatCount = 0,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) => DashboardModel(
        societyBalance: (json['society_balance'] ?? 0).toDouble(),
        totalInward: (json['total_inward'] ?? 0).toDouble(),
        totalOutward: (json['total_outward'] ?? 0).toDouble(),
        pendingDues: json['pending_dues'] ?? 0,
        pendingApprovals: json['pending_approvals'] ?? 0,
        recentTransactions:
            List<Map<String, dynamic>>.from(json['recent_transactions'] ?? []),
        monthlyTrend:
            List<Map<String, dynamic>>.from(json['monthly_trend'] ?? []),
        memberCount: json['member_count'] ?? 0,
        flatCount: json['flat_count'] ?? 0,
      );
}

class MonthlySummary {
  final int month;
  final int year;
  final double totalInward;
  final double totalOutward;
  final double net;
  final int transactionCount;

  MonthlySummary({
    required this.month,
    required this.year,
    this.totalInward = 0,
    this.totalOutward = 0,
    this.net = 0,
    this.transactionCount = 0,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) => MonthlySummary(
        month: json['month'] ?? 0,
        year: json['year'] ?? 0,
        totalInward: (json['total_inward'] ?? 0).toDouble(),
        totalOutward: (json['total_outward'] ?? 0).toDouble(),
        net: (json['net'] ?? 0).toDouble(),
        transactionCount: json['transaction_count'] ?? 0,
      );
}

class CategorySpendingModel {
  final String category;
  final double total;
  final int count;
  final double percentage;

  CategorySpendingModel({
    required this.category,
    this.total = 0,
    this.count = 0,
    this.percentage = 0,
  });

  factory CategorySpendingModel.fromJson(Map<String, dynamic> json) =>
      CategorySpendingModel(
        category: json['category'] ?? '',
        total: (json['total'] ?? 0).toDouble(),
        count: json['count'] ?? 0,
        percentage: (json['percentage'] ?? 0).toDouble(),
      );
}
