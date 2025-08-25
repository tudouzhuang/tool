class UserModel {
  String? fullName;
  String? designation;
  String? email;
  String? phoneNumber;
  String? profileImagePath;
  String? careerObjective;
  String? websiteUrl;

  UserModel({
    this.fullName,
    this.designation,
    this.email,
    this.phoneNumber,
    this.profileImagePath,
    this.careerObjective,
    this.websiteUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'designation': designation,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImagePath': profileImagePath,
      'careerObjective': careerObjective,
      'websiteUrl': websiteUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      fullName: map['fullName'],
      designation: map['designation'],
      email: map['email'],
      phoneNumber: map['phoneNumber'],
      profileImagePath: map['profileImagePath'],
      careerObjective: map['careerObjective'],
      websiteUrl: map['websiteUrl'],
    );
  }
}
