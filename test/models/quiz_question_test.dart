import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/models/quiz_question.dart';

import '../fixtures/quiz_fixtures.dart';

void main() {
  test(
    'RFC 3986 text decodes exactly once, including Unicode and percent signs',
    () {
      final json = questionJson(1);
      const text = 'Don\'t forget π = 3.14 & 1 + 2; literal %20.';
      json['question'] = Uri.encodeComponent(text);
      json['correct_answer'] = Uri.encodeComponent('Électricité + 100%');
      final question = QuizQuestion.fromJson(json, random: Random(7));
      expect(question.text, text);
      expect(question.correctAnswer, 'Électricité + 100%');
      expect(
        question.options,
        containsAll(['Wrong A 1', 'Wrong B 1', 'Wrong C 1']),
      );
      expect(() => question.options.shuffle(), throwsUnsupportedError);
    },
  );

  test('shuffling preserves the correct answer at every resulting index', () {
    final indices = <int>{};
    for (var seed = 0; seed < 30; seed++) {
      final question = QuizQuestion.fromJson(
        questionJson(1),
        random: Random(seed),
      );
      indices.add(question.correctIndex);
      expect(question.correctAnswer, 'Correct 1');
      expect(question.options.toSet().length, 4);
    }
    expect(indices.length, 4);
  });

  test('malformed encoding and ambiguous options are rejected', () {
    expect(
      () => QuizQuestion.fromJson({...questionJson(1), 'question': '%ZZ'}),
      throwsFormatException,
    );
    expect(
      () => QuizQuestion.fromJson({
        ...questionJson(1),
        'incorrect_answers': ['Correct%201', 'B', 'C'],
      }),
      throwsFormatException,
    );
    expect(
      () => QuizQuestion.fromJson({...questionJson(1), 'type': 'boolean'}),
      throwsFormatException,
    );
  });
}
