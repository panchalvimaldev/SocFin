class NotificationModel {
  final String id;
  final String societyId;
  final String userId;
  final String title;
  final String message;
  final String type;
  final bool read;
  final String createdAt;

  NotificationModel({
    required this.id,
    this.societyId = '',
    this.userId = '',
    required this.title,
    required this.message,
    this.type = 'system',
    this.read = false,
    this.createdAt = '',
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] ?? '',
        societyId: json['society_id'] ?? '',
        userId: json['user_id'] ?? '',
        title: json['title'] ?? '',
        message: json['message'] ?? '',
        type: json['type'] ?? 'system',
        read: json['read'] ?? false,
        createdAt: json['created_at'] ?? '',
      );

  NotificationModel copyWith({bool? read}) => NotificationModel(
        id: id,
        societyId: societyId,
        userId: userId,
        title: title,
        message: message,
        type: type,
        read: read ?? this.read,
        createdAt: createdAt,
      );
}
