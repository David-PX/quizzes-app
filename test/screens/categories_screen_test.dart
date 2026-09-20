import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quiz_app/screens/categories_screen.dart';
import 'package:quiz_app/services/trivia_api.dart';
import 'package:quiz_app/theme/app_theme.dart';

void main() {
  TriviaApi createApi(Future<http.Response> Function(http.Request) handler) {
    final api = TriviaApi(
      client: MockClient(handler),
      minimumRequestInterval: Duration.zero,
    );
    addTearDown(api.close);
    return api;
  }

  Widget app(TriviaApi api, {double textScale = 1}) {
    return MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: CategoriesScreen(api: api),
    );
  }

  testWidgets('shows loading then data without refetching on rebuild', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    var requests = 0;
    final api = createApi((_) {
      requests++;
      return response.future;
    });
    await tester.pumpWidget(app(api));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    response.complete(
      http.Response(
        '{"trivia_categories":[{"id":9,"name":"General Knowledge"}]}',
        200,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('General Knowledge'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pumpWidget(app(api, textScale: 1.2));
    await tester.pumpAndSettle();
    expect(requests, 1);
  });

  testWidgets('an error can be retried and replaced by categories', (
    tester,
  ) async {
    var requests = 0;
    final api = createApi((_) async {
      requests++;
      if (requests == 1) throw http.ClientException('Offline');
      return http.Response(
        '{"trivia_categories":[{"id":23,"name":"History"}]}',
        200,
      );
    });
    await tester.pumpWidget(app(api));
    await tester.pumpAndSettle();
    expect(find.text('Could not load categories'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Could not load categories'), findsNothing);
    expect(requests, 2);
  });

  testWidgets('an empty list offers retry instead of a blank screen', (
    tester,
  ) async {
    final api = createApi(
      (_) async => http.Response('{"trivia_categories":[]}', 200),
    );
    await tester.pumpWidget(app(api));
    await tester.pumpAndSettle();
    expect(find.text('No categories available'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('long titles fit a narrow phone at text scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = createApi(
        (_) async => http.Response(
          jsonEncode({
            'trivia_categories': [
              {'id': 31, 'name': 'Entertainment: Japanese Anime & Manga'},
              {'id': 13, 'name': 'Entertainment: Musicals & Theatres'},
              {'id': 32, 'name': 'Entertainment: Cartoon & Animations'},
            ],
          }),
          200,
        ),
      );
      await tester.pumpWidget(app(api, textScale: scale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('retry respects the default five second request interval', (
    tester,
  ) async {
    var requests = 0;
    final api = TriviaApi(
      client: MockClient((_) async {
        requests++;
        return requests == 1
            ? http.Response('', 429)
            : http.Response(
                '{"trivia_categories":[{"id":23,"name":"History"}]}',
                200,
              );
      }),
    );
    addTearDown(api.close);
    await tester.pumpWidget(app(api));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(requests, 1);
    await tester.pump(const Duration(seconds: 4));
    expect(requests, 1);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(requests, 2);
    expect(find.text('History'), findsOneWidget);
  });
}
