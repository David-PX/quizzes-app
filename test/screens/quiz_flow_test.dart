import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quiz_app/screens/categories_screen.dart';
import 'package:quiz_app/screens/difficulty_screen.dart';
import 'package:quiz_app/screens/quiz_screen.dart';
import 'package:quiz_app/screens/results_screen.dart';
import 'package:quiz_app/services/trivia_api.dart';
import 'package:quiz_app/theme/app_theme.dart';

import '../fixtures/quiz_fixtures.dart';

void main() {
  Future<void> start(
    WidgetTester tester, {
    int? errorCode,
    bool longText = false,
    double scale = 1,
    List<Uri>? requests,
  }) async {
    var quizCalls = 0;
    final api = TriviaApi(
      minimumRequestInterval: Duration.zero,
      client: MockClient((request) async {
        requests?.add(request.url);
        if (request.url.path == '/api_category.php')
          return http.Response(categoriesResponse, 200);
        if (errorCode != null && quizCalls++ == 0)
          return http.Response(
            '{"response_code":$errorCode,"results":[]}',
            200,
          );
        return http.Response(
          questionsResponse(
            difficulty: request.url.queryParameters['difficulty']!,
            longText: longText,
          ),
          200,
        );
      }),
    );
    addTearDown(api.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: CategoriesScreen(api: api),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('General Knowledge'));
    await tester.pumpAndSettle();
    expect(find.text('Easy Quiz'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Medium Quiz'), 200);
    expect(find.text('Medium Quiz'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Hard Quiz'), 200);
    expect(find.text('Hard Quiz'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Easy Quiz'), -200);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('difficulty-easy')));
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, String answer) async {
    await tester.scrollUntilVisible(find.text(answer), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text(answer));
    await tester.pump();
  }

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('next')));
    await tester.pumpAndSettle();
  }

  testWidgets('full quiz scores on Next, locks answers, reviews and replays', (
    tester,
  ) async {
    final requests = <Uri>[];
    await start(tester, requests: requests);
    expect(find.text('Question 1 of 10'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(const ValueKey('next'))).onPressed,
      isNull,
    );
    await choose(tester, 'Correct 1');
    expect(find.text('Score: 0'), findsOneWidget);
    await next(tester);
    expect(find.text('Score: 1'), findsOneWidget);
    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();
    await choose(tester, 'Wrong A 1');
    await next(tester);
    expect(find.text('Score: 1'), findsOneWidget);
    for (var i = 2; i <= 10; i++) {
      await choose(tester, i == 2 ? 'Wrong A $i' : 'Correct $i');
      if (i == 10) expect(find.text('Finish'), findsOneWidget);
      await next(tester);
    }
    expect(find.byType(ResultsScreen), findsOneWidget);
    expect(find.text('9 / 10'), findsOneWidget);
    expect(find.text('90% correct'), findsOneWidget);
    expect(find.text('Your answer: Correct 1'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Question 10 · Correct'), 400);
    expect(find.text('Correct answer: Correct 10'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Question 2 · Incorrect'), -400);
    expect(find.text('Your answer: Wrong A 2'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Play Again'), -400);
    await tester.tap(find.text('Play Again'));
    await tester.pumpAndSettle();
    expect(find.text('Question 1 of 10'), findsOneWidget);
    expect(find.text('Score: 0'), findsOneWidget);
    expect(requests.where((uri) => uri.path == '/api.php').length, 2);
    // Android back follows the same confirmation path as the app bar.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Leave this quiz?'), findsOneWidget);
    await tester.tap(find.text('Leave quiz'));
    await tester.pumpAndSettle();
    expect(find.byType(DifficultyScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(CategoriesScreen), findsOneWidget);
    expect(requests.where((uri) => uri.path == '/api_category.php').length, 1);
  });

  testWidgets('canceling exit keeps the selection', (tester) async {
    await start(tester);
    await choose(tester, 'Correct 1');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep playing'));
    await tester.pumpAndSettle();
    expect(find.byType(QuizScreen), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(const ValueKey('next'))).onPressed,
      isNotNull,
    );
    await next(tester);
    expect(find.text('Score: 1'), findsOneWidget);
  });

  testWidgets(
    'no-results error offers another difficulty without altering filters',
    (tester) async {
      final requests = <Uri>[];
      await start(tester, errorCode: 1, requests: requests);
      expect(find.text('Try again'), findsNothing);
      expect(find.textContaining('not enough questions'), findsOneWidget);
      await tester.tap(find.text('Choose another difficulty'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('difficulty-medium')));
      await tester.pumpAndSettle();
      expect(find.text('Question 1 of 10'), findsOneWidget);
      expect(requests.last.queryParameters['difficulty'], 'medium');
    },
  );

  testWidgets('a rate-limit error can be retried without leaving the screen', (
    tester,
  ) async {
    await start(tester, errorCode: 5);
    expect(find.textContaining('Too many requests'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Question 1 of 10'), findsOneWidget);
  });

  testWidgets('results return directly to the cached category screen', (
    tester,
  ) async {
    final requests = <Uri>[];
    await start(tester, requests: requests);
    for (var i = 1; i <= 10; i++) {
      await choose(tester, 'Correct $i');
      await next(tester);
    }
    await tester.tap(find.text('Back to Categories'));
    await tester.pumpAndSettle();
    expect(find.byType(CategoriesScreen), findsOneWidget);
    expect(find.byType(ResultsScreen), findsNothing);
    expect(requests.where((uri) => uri.path == '/api_category.php').length, 1);
  });

  testWidgets(
    'large text and long questions fit a small phone through results',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await start(tester, longText: true, scale: 2);
      expect(tester.takeException(), isNull);
      for (var i = 1; i <= 10; i++) {
        await choose(tester, 'Correct $i');
        await next(tester);
        expect(tester.takeException(), isNull);
      }
      await tester.scrollUntilVisible(find.text('Question 10 · Correct'), 500);
      expect(tester.takeException(), isNull);
    },
  );
}
