import 'dart:math';

class QuizQuestion {
  QuizQuestion._({
    required this.text,
    required List<String> options,
    required this.correctIndex,
  }) : options = List.unmodifiable(options);

  final String text;
  final List<String> options;
  final int correctIndex;

  String get correctAnswer => options[correctIndex];

  factory QuizQuestion.fromJson(Map<String, dynamic> json, {Random? random}) {
    String decode(Object? value) {
      if (value is! String || value.isEmpty) {
        throw const FormatException('Missing question text.');
      }
      try {
        final text = Uri.decodeComponent(value);
        if (text.trim().isEmpty) throw const FormatException('Empty text.');
        return text;
      } on ArgumentError {
        throw const FormatException('Invalid URL encoding.');
      }
    }

    final incorrect = json['incorrect_answers'];
    if (json['type'] != 'multiple' ||
        incorrect is! List ||
        incorrect.length != 3) {
      throw const FormatException('Expected four multiple-choice options.');
    }
    final text = decode(json['question']);
    final correct = decode(json['correct_answer']);
    final options = [correct, ...incorrect.map(decode)];
    if (options.toSet().length != 4) {
      throw const FormatException('Duplicate answer options.');
    }
    // Shuffle once when parsing, never when a widget rebuilds.
    options.shuffle(random ?? Random());
    return QuizQuestion._(
      text: text,
      options: options,
      correctIndex: options.indexOf(correct),
    );
  }
}
