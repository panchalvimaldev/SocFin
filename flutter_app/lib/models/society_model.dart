class SocietyModel {
  final String id;
  final String name;
  final String address;
  final int totalFlats;
  final String description;
  final String role;
  final String membershipId;

  SocietyModel({
    required this.id,
    required this.name,
    required this.address,
    this.totalFlats = 0,
    this.description = '',
    this.role = 'member',
    this.membershipId = '',
  });

  factory SocietyModel.fromJson(Map<String, dynamic> json) => SocietyModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        address: json['address'] ?? '',
        totalFlats: json['total_flats'] ?? 0,
        description: json['description'] ?? '',
        role: json['role'] ?? 'member',
        membershipId: json['membership_id'] ?? '',
      );

  bool get isManager => role == 'manager';
  bool get isCommittee => role == 'committee';
  bool get isAuditor => role == 'auditor';
  bool get canEdit => role == 'manager';
  bool get canApprove => role == 'committee' || role == 'manager';
}

class FlatModel {
  final String id;
  final String societyId;
  final String flatNumber;
  final int floor;
  final String wing;
  final double areaSqft;
  final String flatType;

  FlatModel({
    required this.id,
    required this.societyId,
    required this.flatNumber,
    this.floor = 0,
    this.wing = '',
    this.areaSqft = 0,
    this.flatType = '',
  });

  factory FlatModel.fromJson(Map<String, dynamic> json) => FlatModel(
        id: json['id'] ?? '',
        societyId: json['society_id'] ?? '',
        flatNumber: json['flat_number'] ?? '',
        floor: json['floor'] ?? 0,
        wing: json['wing'] ?? '',
        areaSqft: (json['area_sqft'] ?? 0).toDouble(),
        flatType: json['flat_type'] ?? '',
      );
}

class MembershipModel {
  final String id;
  final String userId;
  final String societyId;
  final String role;
  final String status;
  final String userName;
  final String userEmail;

  MembershipModel({
    required this.id,
    required this.userId,
    required this.societyId,
    required this.role,
    required this.status,
    this.userName = '',
    this.userEmail = '',
  });

  factory MembershipModel.fromJson(Map<String, dynamic> json) => MembershipModel(
        id: json['id'] ?? '',
        userId: json['user_id'] ?? '',
        societyId: json['society_id'] ?? '',
        role: json['role'] ?? 'member',
        status: json['status'] ?? 'active',
        userName: json['user_name'] ?? '',
        userEmail: json['user_email'] ?? '',
      );
}
