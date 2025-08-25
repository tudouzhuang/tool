class Skill {
  final String name;

  Skill({required this.name});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }
}