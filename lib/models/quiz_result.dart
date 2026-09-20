import 'quiz_question.dart';

class QuizAnswer {
  const QuizAnswer({required this.question, required this.selectedIndex});

  final QuizQuestion question;
  final int selectedIndex;

  String get selectedAnswer => question.options[selectedIndex];
  bool get isCorrect => selectedIndex == question.correctIndex;
}

class QuizResult {
  QuizResult(List<QuizAnswer> answers) : answers = List.unmodifiable(answers) {
    if (answers.isEmpty) throw ArgumentError('A result needs answers.');
  }

  final List<QuizAnswer> answers;

  int get total => answers.length;
  int get score => answers.where((answer) => answer.isCorrect).length;
  int get percentage => (score * 100 / total).round();
}
