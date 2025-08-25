class WorkExperienceItem {
  final String position;
  final String company;
  final String startDate;
  final String endDate;
  final List<String> projects;
  final List<String> projectUrls;
  final String description;
  final bool isCurrent;

  WorkExperienceItem({
    required this.position,
    required this.company,
    required this.startDate,
    required this.endDate,
    required this.projects,
    required this.description,
    required this.projectUrls,
    this.isCurrent = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'position': position,
      'company': company,
      'startDate': startDate,
      'endDate': endDate,
      'projects': projects,
      'projectUrls': projectUrls,
      'description': description,
      'isCurrent': isCurrent,
    };
  }
}