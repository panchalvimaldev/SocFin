class MaintenanceBillModel {
  final String id;
  final String societyId;
  final String flatId;
  final String flatNumber;
  final String memberId;
  final String memberName;
  final int month;
  final int year;
  final double amount;
  final String dueDate;
  final double lateFee;
  final String status;
  final double paidAmount;
  final String createdAt;

  MaintenanceBillModel({
    required this.id,
    required this.societyId,
    this.flatId = '',
    this.flatNumber = '',
    this.memberId = '',
    this.memberName = '',
    required this.month,
    required this.year,
    required this.amount,
    this.dueDate = '',
    this.lateFee = 0,
    this.status = 'pending',
    this.paidAmount = 0,
    this.createdAt = '',
  });

  factory MaintenanceBillModel.fromJson(Map<String, dynamic> json) =>
      MaintenanceBillModel(
        id: json['id'] ?? '',
        societyId: json['society_id'] ?? '',
        flatId: json['flat_id'] ?? '',
        flatNumber: json['flat_number'] ?? '',
        memberId: json['member_id'] ?? '',
        memberName: json['member_name'] ?? '',
        month: json['month'] ?? 0,
        year: json['year'] ?? 0,
        amount: (json['amount'] ?? 0).toDouble(),
        dueDate: json['due_date'] ?? '',
        lateFee: (json['late_fee'] ?? 0).toDouble(),
        status: json['status'] ?? 'pending',
        paidAmount: (json['paid_amount'] ?? 0).toDouble(),
        createdAt: json['created_at'] ?? '',
      );

  double get outstanding => amount - paidAmount;
  bool get isPaid => status == 'paid';
}
