import 'dart:convert';
import 'dart:math';

import 'package:quiz_app/models/quiz_question.dart';

Map<String, dynamic> questionJson(
  int index, {
  String difficulty = 'easy',
  bool longText = false,
}) {
  final question = longText
      ? 'Which of these answers best describes a very long question about science, history, literature and the world around us? Question $index'
      : 'Test question $index?';
  return {
    'type': 'multiple',
    'difficulty': difficulty,
    'category': Uri.encodeComponent('General Knowledge'),
    'question': Uri.encodeComponent(question),
    'correct_answer': Uri.encodeComponent('Correct $index'),
    'incorrect_answers': [
      Uri.encodeComponent('Wrong A $index'),
      Uri.encodeComponent('Wrong B $index'),
      Uri.encodeComponent(
        longText
            ? 'This is a long answer with many words that should wrap safely on a narrow display.'
            : 'Wrong C $index',
      ),
    ],
  };
}

List<QuizQuestion> fixtureQuestions({int count = 10}) => [
  for (var i = 1; i <= count; i++)
    QuizQuestion.fromJson(questionJson(i), random: Random(i)),
];

String questionsResponse({String difficulty = 'easy', bool longText = false}) =>
    jsonEncode({
      'response_code': 0,
      'results': [
        for (var i = 1; i <= 10; i++)
          questionJson(i, difficulty: difficulty, longText: longText),
      ],
    });

const categoriesResponse =
    '{"trivia_categories":[{"id":9,"name":"General Knowledge"}]}';
