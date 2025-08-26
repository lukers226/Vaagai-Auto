class DriverModel {
  final String id;
  final String name;
  final String phoneNumber;
  final DateTime createdAt;

  DriverModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.createdAt,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
    };
  }
}
