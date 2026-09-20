import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quiz_app/services/trivia_api.dart';

void main() {
  TriviaApi createApi(
    Future<http.Response> Function(http.Request) handler, {
    Duration timeout = const Duration(seconds: 15),
  }) {
    final api = TriviaApi(
      client: MockClient(handler),
      minimumRequestInterval: Duration.zero,
      requestTimeout: timeout,
    );
    addTearDown(api.close);
    return api;
  }

  test('requests the category endpoint and preserves IDs and names', () async {
    final api = createApi((request) async {
      expect(request.method, 'GET');
      expect(request.url, Uri.https('opentdb.com', '/api_category.php'));
      return http.Response(
        '{"trivia_categories":[{"id":9,"name":"General Knowledge"},'
        '{"id":17,"name":"Science & Nature"}]}',
        200,
      );
    });

    final categories = await api.fetchCategories();
    expect(categories.map((category) => category.id), [9, 17]);
    expect(categories.map((category) => category.name), [
      'General Knowledge',
      'Science & Nature',
    ]);
  });

  test('an empty result remains a valid empty category list', () async {
    final api = createApi(
      (_) async => http.Response('{"trivia_categories":[]}', 200),
    );
    expect(await api.fetchCategories(), isEmpty);
  });

  for (final body in [
    'not json',
    '[]',
    '{}',
    '{"trivia_categories":{}}',
    '{"trivia_categories":[null]}',
    '{"trivia_categories":[{"id":"9","name":"General Knowledge"}]}',
    '{"trivia_categories":[{"id":9,"name":" "}]}',
  ]) {
    test('invalid data becomes a readable API error: $body', () async {
      final api = createApi((_) async => http.Response(body, 200));
      await expectLater(
        api.fetchCategories(),
        throwsA(
          isA<TriviaApiException>().having(
            (error) => error.message,
            'message',
            contains('unexpected data'),
          ),
        ),
      );
    });
  }

  test('HTTP errors are handled before parsing their response body', () async {
    final api = createApi(
      (_) async => http.Response('<html>Error</html>', 503),
    );
    await expectLater(
      api.fetchCategories(),
      throwsA(
        isA<TriviaApiException>().having(
          (error) => error.message,
          'message',
          contains('unavailable'),
        ),
      ),
    );
  });

  test('rate limits have an actionable message', () async {
    final api = createApi((_) async => http.Response('', 429));
    await expectLater(
      api.fetchCategories(),
      throwsA(
        isA<TriviaApiException>().having(
          (error) => error.message,
          'message',
          contains('Too many requests'),
        ),
      ),
    );
  });

  test('connection errors suggest checking the connection', () async {
    final api = createApi((_) async => throw http.ClientException('Offline'));
    await expectLater(
      api.fetchCategories(),
      throwsA(
        isA<TriviaApiException>().having(
          (error) => error.message,
          'message',
          contains('internet connection'),
        ),
      ),
    );
  });

  test('a stalled request times out', () async {
    final response = Completer<http.Response>();
    final api = createApi(
      (_) => response.future,
      timeout: const Duration(milliseconds: 10),
    );
    await expectLater(
      api.fetchCategories(),
      throwsA(
        isA<TriviaApiException>().having(
          (error) => error.message,
          'message',
          contains('too long'),
        ),
      ),
    );
    response.complete(http.Response('{"trivia_categories":[]}', 200));
  });

  test('concurrent callers share one pending request', () async {
    var requests = 0;
    final response = Completer<http.Response>();
    final api = createApi((_) {
      requests++;
      return response.future;
    });
    final first = api.fetchCategories();
    final second = api.fetchCategories();
    expect(identical(first, second), isTrue);
    response.complete(http.Response('{"trivia_categories":[]}', 200));
    await Future.wait([first, second]);
    expect(requests, 1);
  });

  test('a failed request can be retried successfully', () async {
    var requests = 0;
    final api = createApi((_) async {
      requests++;
      return requests == 1
          ? http.Response('', 503)
          : http.Response(
              '{"trivia_categories":[{"id":23,"name":"History"}]}',
              200,
            );
    });
    await expectLater(
      api.fetchCategories(),
      throwsA(isA<TriviaApiException>()),
    );
    expect((await api.fetchCategories()).single.name, 'History');
    expect(requests, 2);
  });
}
