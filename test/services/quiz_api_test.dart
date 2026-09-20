import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quiz_app/models/quiz_difficulty.dart';
import 'package:quiz_app/services/trivia_api.dart';

import '../fixtures/quiz_fixtures.dart';

void main() {
  TriviaApi apiFor(Future<http.Response> Function(http.Request) handler) {
    final api = TriviaApi(
      client: MockClient(handler),
      minimumRequestInterval: Duration.zero,
    );
    addTearDown(api.close);
    return api;
  }

  test(
    'questions use the selected category, difficulty, encoding and amount',
    () async {
      final api = apiFor((request) async {
        expect(request.url.path, '/api.php');
        expect(request.url.queryParameters, {
          'category': '23',
          'difficulty': 'hard',
          'amount': '10',
          'type': 'multiple',
          'encode': 'url3986',
        });
        return http.Response(questionsResponse(difficulty: 'hard'), 200);
      });
      final questions = await api.fetchQuestions(
        categoryId: 23,
        difficulty: QuizDifficulty.hard,
      );
      expect(questions.length, 10);
      expect(questions.last.text, 'Test question 10?');
    },
  );

  for (final code in [1, 2, 3, 4, 5]) {
    test('API response code $code has a recovery policy', () async {
      final api = apiFor(
        (_) async => http.Response(
          jsonEncode({'response_code': code, 'results': <Object>[]}),
          200,
        ),
      );
      await expectLater(
        api.fetchQuestions(categoryId: 9, difficulty: QuizDifficulty.easy),
        throwsA(
          isA<TriviaApiException>().having(
            (e) => e.canRetry,
            'canRetry',
            code == 5,
          ),
        ),
      );
    });
  }

  test('incomplete quiz and wrong difficulty are rejected', () async {
    var call = 0;
    final api = apiFor(
      (_) async => http.Response(
        call++ == 0
            ? jsonEncode({
                'response_code': 0,
                'results': [questionJson(1)],
              })
            : questionsResponse(difficulty: 'hard'),
        200,
      ),
    );
    for (var i = 0; i < 2; i++) {
      await expectLater(
        api.fetchQuestions(categoryId: 9, difficulty: QuizDifficulty.easy),
        throwsA(isA<TriviaApiException>()),
      );
    }
  });

  test(
    'pending requests coalesce, but a replay fetches new questions',
    () async {
      var requests = 0;
      final response = Completer<http.Response>();
      final api = apiFor((_) {
        requests++;
        return response.future;
      });
      final first = api.fetchQuestions(
        categoryId: 9,
        difficulty: QuizDifficulty.easy,
      );
      final second = api.fetchQuestions(
        categoryId: 9,
        difficulty: QuizDifficulty.easy,
      );
      expect(identical(first, second), isTrue);
      response.complete(http.Response(questionsResponse(), 200));
      await Future.wait([first, second]);
      expect(requests, 1);
      await api.fetchQuestions(categoryId: 9, difficulty: QuizDifficulty.easy);
      expect(requests, 2);
    },
  );

  testWidgets('category and question requests share the five-second gate', (
    tester,
  ) async {
    final paths = <String>[];
    final api = TriviaApi(
      client: MockClient((request) async {
        paths.add(request.url.path);
        return http.Response(
          request.url.path == '/api.php'
              ? questionsResponse()
              : categoriesResponse,
          200,
        );
      }),
    );
    addTearDown(api.close);
    final categories = api.fetchCategories();
    final questions = api.fetchQuestions(
      categoryId: 9,
      difficulty: QuizDifficulty.easy,
    );
    await tester.pump();
    expect(paths, ['/api_category.php']);
    await tester.pump(const Duration(seconds: 4));
    expect(paths, ['/api_category.php']);
    await tester.pump(const Duration(seconds: 1));
    await Future.wait<Object>([categories, questions]);
    expect(paths, ['/api_category.php', '/api.php']);
  });
}
