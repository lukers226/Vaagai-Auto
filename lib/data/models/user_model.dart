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
    // DEBUG: Print the JSON being parsed
    print('UserModel.fromJson - Raw JSON: $json');
    
    String parsedId = json['_id'] ?? '';
    String parsedPhone = json['phoneNumber'] ?? '';
    String parsedType = json['userType'] ?? '';
    String? parsedName = json['name'];
    
    print('UserModel.fromJson - Parsed Values:');
    print('  ID: "$parsedId" (length: ${parsedId.length})');
    print('  Phone: "$parsedPhone"');
    print('  Type: "$parsedType"');
    print('  Name: "$parsedName"');
    
    return UserModel(
      id: parsedId,
      phoneNumber: parsedPhone,
      userType: parsedType,
      name: parsedName,
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

  @override
  String toString() {
    return 'UserModel(id: $id, phoneNumber: $phoneNumber, userType: $userType, name: $name)';
  }
}
