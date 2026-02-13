class TransactionModel {
  final String id;
  final String societyId;
  final String type; // inward / outward
  final String category;
  final double amount;
  final String description;
  final String vendorName;
  final String paymentMode;
  final String invoicePath;
  final String createdBy;
  final String createdByName;
  final String date;
  final String createdAt;
  final String approvalStatus;

  TransactionModel({
    required this.id,
    required this.societyId,
    required this.type,
    required this.category,
    required this.amount,
    this.description = '',
    this.vendorName = '',
    this.paymentMode = 'bank',
    this.invoicePath = '',
    this.createdBy = '',
    this.createdByName = '',
    this.date = '',
    this.createdAt = '',
    this.approvalStatus = 'approved',
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
        id: json['id'] ?? '',
        societyId: json['society_id'] ?? '',
        type: json['type'] ?? '',
        category: json['category'] ?? '',
        amount: (json['amount'] ?? 0).toDouble(),
        description: json['description'] ?? '',
        vendorName: json['vendor_name'] ?? '',
        paymentMode: json['payment_mode'] ?? 'bank',
        invoicePath: json['invoice_path'] ?? '',
        createdBy: json['created_by'] ?? '',
        createdByName: json['created_by_name'] ?? '',
        date: json['date'] ?? '',
        createdAt: json['created_at'] ?? '',
        approvalStatus: json['approval_status'] ?? 'approved',
      );

  bool get isInward => type == 'inward';
  bool get isPending => approvalStatus == 'pending';
}

class TransactionCategories {
  final List<String> inward;
  final List<String> outward;

  TransactionCategories({required this.inward, required this.outward});

  factory TransactionCategories.fromJson(Map<String, dynamic> json) =>
      TransactionCategories(
        inward: List<String>.from(json['inward'] ?? []),
        outward: List<String>.from(json['outward'] ?? []),
      );
}
