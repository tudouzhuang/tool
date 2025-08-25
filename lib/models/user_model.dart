class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final DateTime lastSignIn;
  final String gender;
  final String dateOfBirth;
  final String avatarId;
  final bool hasPassword;
  final String? phoneNumber;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.createdAt,
    required this.lastSignIn,
    required this.gender,
    required this.dateOfBirth,
    required this.avatarId,
    required this.hasPassword,
    this.phoneNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt.toIso8601String(),
      'lastSignIn': lastSignIn.toIso8601String(),
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'avatarId': avatarId,
      'hasPassword': hasPassword,
      'phoneNumber': phoneNumber,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      lastSignIn: DateTime.parse(map['lastSignIn'] ?? DateTime.now().toIso8601String()),
      gender: map['gender'] ?? 'Not set',
      dateOfBirth: map['dateOfBirth'] ?? 'Not set',
      avatarId: map['avatarId'] ?? '6',
      hasPassword: map['hasPassword'] ?? false,
      phoneNumber: map['phoneNumber'],
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    DateTime? createdAt,
    DateTime? lastSignIn,
    String? gender,
    String? dateOfBirth,
    String? avatarId,
    bool? hasPassword,
    String? phoneNumber,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      lastSignIn: lastSignIn ?? this.lastSignIn,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      avatarId: avatarId ?? this.avatarId,
      hasPassword: hasPassword ?? this.hasPassword,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, gender: $gender, dateOfBirth: $dateOfBirth, avatarId: $avatarId, hasPassword: $hasPassword, phoneNumber: $phoneNumber)';
  }
}