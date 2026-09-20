import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/state/quiz_session.dart';

import '../fixtures/quiz_fixtures.dart';

void main() {
  test('selecting does not score; advancing confirms and scores once', () {
    final quiz = QuizSession(fixtureQuestions());
    addTearDown(quiz.dispose);
    quiz.advance();
    expect(quiz.index, 0);
    expect(quiz.canGoPrevious, isFalse);
    quiz.selectAnswer(quiz.currentQuestion.correctIndex);
    expect(quiz.score, 0);
    quiz.advance();
    expect(quiz.index, 1);
    expect(quiz.score, 1);
    quiz.previous();
    expect(quiz.isConfirmed, isTrue);
    final selection = quiz.selectedIndex;
    quiz.selectAnswer((selection! + 1) % 4);
    expect(quiz.selectedIndex, selection);
    quiz.advance();
    expect(quiz.score, 1);
  });

  test('unconfirmed selection and answer order survive Previous', () {
    final quiz = QuizSession(fixtureQuestions());
    addTearDown(quiz.dispose);
    quiz.selectAnswer(0);
    quiz.advance();
    final options = List.of(quiz.currentQuestion.options);
    quiz.selectAnswer(2);
    quiz.previous();
    quiz.advance();
    expect(quiz.selectedIndex, 2);
    expect(quiz.currentQuestion.options, options);
    expect(quiz.isConfirmed, isFalse);
  });

  test('Finish includes the last answer and completion is immutable', () {
    final quiz = QuizSession(fixtureQuestions());
    addTearDown(quiz.dispose);
    for (var i = 0; i < 10; i++) {
      final correct = quiz.currentQuestion.correctIndex;
      quiz.selectAnswer(i == 0 ? (correct + 1) % 4 : correct);
      quiz.advance();
    }
    expect(quiz.isComplete, isTrue);
    expect(quiz.score, 9);
    final result = quiz.result;
    expect(result.percentage, 90);
    expect(result.answers.first.isCorrect, isFalse);
    expect(result.answers.last.isCorrect, isTrue);
    quiz.advance();
    quiz.previous();
    quiz.selectAnswer(0);
    expect(quiz.index, 9);
    expect(quiz.score, 9);
    expect(result.score, 9);
    expect(() => result.answers.clear(), throwsUnsupportedError);
  });

  test('empty games and unfinished results are rejected', () {
    expect(() => QuizSession([]), throwsArgumentError);
    final quiz = QuizSession(fixtureQuestions());
    addTearDown(quiz.dispose);
    expect(() => quiz.result, throwsStateError);
  });
}
