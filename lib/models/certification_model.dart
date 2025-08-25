class CertificationItem {
  final String certificationName;
  final String organizationName;
  final String startDate;
  final String endDate;
  final bool isCompleted;
  final String description;

  CertificationItem({
    required this.certificationName,
    required this.organizationName,
    required this.startDate,
    this.endDate = '',
    this.isCompleted = false,
    this.description = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'certificationName': certificationName,
      'organizationName': organizationName,
      'startDate': startDate,
      'endDate': endDate,
      'isCompleted': isCompleted,
      'description': description,
    };
  }
}