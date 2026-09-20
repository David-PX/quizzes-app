class QuizCategory {
  const QuizCategory({required this.id, required this.name});

  final int id;
  final String name;

  // Converts an API object into the type used by our app.
  factory QuizCategory.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];

    if (id is! int || id <= 0 || name is! String || name.trim().isEmpty) {
      throw const FormatException('Invalid category.');
    }

    return QuizCategory(id: id, name: name.trim());
  }
}
