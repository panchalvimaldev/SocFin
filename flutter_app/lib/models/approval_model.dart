class ApprovalModel {
  final String id;
  final String transactionId;
  final Map<String, dynamic> transaction;
  final String requestedBy;
  final String requestedByName;
  final String status;
  final String approvedBy;
  final String approvedByName;
  final String comments;
  final String createdAt;

  ApprovalModel({
    required this.id,
    required this.transactionId,
    this.transaction = const {},
    this.requestedBy = '',
    this.requestedByName = '',
    required this.status,
    this.approvedBy = '',
    this.approvedByName = '',
    this.comments = '',
    this.createdAt = '',
  });

  factory ApprovalModel.fromJson(Map<String, dynamic> json) => ApprovalModel(
        id: json['id'] ?? '',
        transactionId: json['transaction_id'] ?? '',
        transaction: json['transaction'] ?? {},
        requestedBy: json['requested_by'] ?? '',
        requestedByName: json['requested_by_name'] ?? '',
        status: json['status'] ?? 'pending',
        approvedBy: json['approved_by'] ?? '',
        approvedByName: json['approved_by_name'] ?? '',
        comments: json['comments'] ?? '',
        createdAt: json['created_at'] ?? '',
      );

  bool get isPending => status == 'pending';
  double get amount => (transaction['amount'] ?? 0).toDouble();
  String get category => transaction['category'] ?? '';
  String get vendorName => transaction['vendor_name'] ?? '';
  String get description => transaction['description'] ?? '';
}
