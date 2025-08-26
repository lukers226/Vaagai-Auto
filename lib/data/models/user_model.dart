class UserModel {
  final String id;
  final String phoneNumber;
  final String userType; // 'admin' or 'driver'
  final String? name;

  UserModel({
    required this.id,
    required this.phoneNumber,
    required this.userType,
    this.name,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      userType: json['userType'] ?? '',
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'phoneNumber': phoneNumber,
      'userType': userType,
      'name': name,
    };
  }
}
