class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;

  UserModel({required this.id, required this.name, required this.email, this.phone = ''});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email, 'phone': phone};
}

class AuthResponse {
  final String accessToken;
  final String tokenType;
  final UserModel user;

  AuthResponse({required this.accessToken, this.tokenType = 'bearer', required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['access_token'] ?? '',
        tokenType: json['token_type'] ?? 'bearer',
        user: UserModel.fromJson(json['user'] ?? {}),
      );
}
