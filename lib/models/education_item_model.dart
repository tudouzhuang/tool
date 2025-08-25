class EducationItem {
  final String degree;
  final String institute;
  final String startDate;
  final String endDate;
  final String description;
  final bool isCompleted;

  EducationItem({
    required this.degree,
    required this.institute,
    required this.startDate,
    required this.endDate,
    required this.description,
    required this.isCompleted,
  });

  Map<String, dynamic> toMap() {
    return {
      'degree': degree,
      'institute': institute,
      'startDate': startDate,
      'endDate': endDate,
      'description': description,
      'isCompleted': isCompleted,
    };
  }
}