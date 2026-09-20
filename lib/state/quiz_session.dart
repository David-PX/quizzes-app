import 'package:flutter/foundation.dart';

import '../models/quiz_question.dart';
import '../models/quiz_result.dart';

class QuizSession extends ChangeNotifier {
  QuizSession(List<QuizQuestion> questions)
    : questions = List.unmodifiable(questions),
      _selections = List.filled(questions.length, null),
      _confirmed = List.filled(questions.length, false) {
    if (questions.isEmpty) throw ArgumentError('A quiz needs questions.');
  }

  final List<QuizQuestion> questions;
  final List<int?> _selections;
  final List<bool> _confirmed;
  int _index = 0;
  bool _isComplete = false;

  int get index => _index;
  QuizQuestion get currentQuestion => questions[_index];
  int? get selectedIndex => _selections[_index];
  bool get isConfirmed => _confirmed[_index];
  bool get isComplete => _isComplete;
  bool get canGoPrevious => _index > 0 && !_isComplete;
  bool get canAdvance => selectedIndex != null && !_isComplete;
  bool get isLastQuestion => _index == questions.length - 1;
  double get progress => (_index + 1) / questions.length;

  // Deriving score from confirmed answers makes double-counting impossible.
  int get score {
    var correct = 0;
    for (var i = 0; i < questions.length; i++) {
      if (_confirmed[i] && _selections[i] == questions[i].correctIndex)
        correct++;
    }
    return correct;
  }

  void selectAnswer(int optionIndex) {
    if (isConfirmed || _isComplete) return;
    RangeError.checkValidIndex(optionIndex, currentQuestion.options);
    _selections[_index] = optionIndex;
    notifyListeners();
  }

  void previous() {
    if (!canGoPrevious) return;
    _index--;
    notifyListeners();
  }

  void advance() {
    if (!canAdvance) return;
    _confirmed[_index] = true;
    if (isLastQuestion) {
      _isComplete = true;
    } else {
      _index++;
    }
    notifyListeners();
  }

  QuizResult get result {
    if (!_isComplete)
      throw StateError('Finish the quiz before reading results.');
    return QuizResult([
      for (var i = 0; i < questions.length; i++)
        QuizAnswer(question: questions[i], selectedIndex: _selections[i]!),
    ]);
  }
}
