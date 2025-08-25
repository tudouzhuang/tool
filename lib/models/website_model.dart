class Website {
  final String name;
  final String url;

  Website({
    required this.name,
    required this.url,
  });

  // Add toMap method
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'url': url,
    };
  }

  // Add fromMap factory method
  factory Website.fromMap(Map<String, dynamic> map) {
    return Website(
      name: map['name'] ?? 'Website',
      url: map['url'] ?? '',
    );
  }
}