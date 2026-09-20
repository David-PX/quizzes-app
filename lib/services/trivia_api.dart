import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/quiz_category.dart';
import '../models/quiz_difficulty.dart';
import '../models/quiz_question.dart';

class TriviaApiException implements Exception {
  const TriviaApiException(this.message, {this.canRetry = true});

  final String message;
  final bool canRetry;

  @override
  String toString() => message;
}

class TriviaApi {
  TriviaApi({
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 15),
    this.minimumRequestInterval = const Duration(seconds: 5),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration requestTimeout;
  final Duration minimumRequestInterval;

  DateTime? _lastRequestAt;
  Future<List<QuizCategory>>? _pendingCategories;
  final _pendingQuizzes = <String, Future<List<QuizQuestion>>>{};
  Future<void> _requestQueue = Future<void>.value();
  static const quizLength = 10;
  bool _closed = false;

  Future<List<QuizCategory>> fetchCategories() {
    // Two callers share the same operation while a request is in progress.
    return _pendingCategories ??= _fetchCategories().whenComplete(() {
      _pendingCategories = null;
    });
  }

  Future<List<QuizCategory>> _fetchCategories() async {
    try {
      final data = await _request(
        Uri.https('opentdb.com', '/api_category.php'),
      );
      final categories = data['trivia_categories'];
      if (categories is! List)
        throw const FormatException('Expected categories.');
      return categories
          .map((Object? item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Expected a category object.');
            }
            return QuizCategory.fromJson(item);
          })
          .toList(growable: false);
    } on FormatException {
      throw const TriviaApiException(
        'The trivia service returned unexpected data. Please try again.',
      );
    }
  }

  Future<List<QuizQuestion>> fetchQuestions({
    required int categoryId,
    required QuizDifficulty difficulty,
  }) {
    final key = '$categoryId:${difficulty.name}';
    return _pendingQuizzes[key] ??= _fetchQuestions(categoryId, difficulty)
        .whenComplete(() {
          _pendingQuizzes.remove(key);
        });
  }

  Future<List<QuizQuestion>> _fetchQuestions(
    int categoryId,
    QuizDifficulty difficulty,
  ) async {
    try {
      final data = await _request(
        Uri.https('opentdb.com', '/api.php', {
          'amount': '$quizLength',
          'category': '$categoryId',
          'difficulty': difficulty.name,
          'type': 'multiple',
          'encode': 'url3986',
        }),
      );
      switch (data['response_code']) {
        case 0:
          break;
        case 1:
          throw const TriviaApiException(
            'There are not enough questions for this difficulty. Please choose another difficulty.',
            canRetry: false,
          );
        case 2:
          throw const TriviaApiException(
            'This quiz could not be requested. Please choose another quiz.',
            canRetry: false,
          );
        case 3:
        case 4:
          throw const TriviaApiException(
            'This quiz is unavailable. Please choose another quiz.',
            canRetry: false,
          );
        case 5:
          throw const TriviaApiException(
            'Too many requests. Please wait a moment and try again.',
          );
        default:
          throw const FormatException('Unknown response code.');
      }
      final results = data['results'];
      if (results is! List || results.length != quizLength) {
        throw const FormatException('Expected ten questions.');
      }
      return results
          .map((Object? item) {
            if (item is! Map<String, dynamic> ||
                item['difficulty'] != difficulty.name) {
              throw const FormatException('Unexpected question.');
            }
            return QuizQuestion.fromJson(item);
          })
          .toList(growable: false);
    } on FormatException {
      throw const TriviaApiException(
        'The trivia service returned unexpected data. Please try again.',
      );
    }
  }

  // A shared queue spaces category and question requests, even across screens.
  Future<Map<String, dynamic>> _request(Uri uri) {
    final operation = _requestQueue.then((_) => _getJson(uri));
    _requestQueue = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return operation;
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final lastRequestAt = _lastRequestAt;
    if (lastRequestAt != null) {
      final elapsed = DateTime.now().difference(lastRequestAt);
      final remaining = minimumRequestInterval - elapsed;
      if (remaining > Duration.zero) {
        await Future<void>.delayed(remaining);
      }
    }

    if (_closed) {
      throw const TriviaApiException('The connection has been closed.');
    }

    try {
      _lastRequestAt = DateTime.now();
      final response = await _client.get(uri).timeout(requestTimeout);

      if (response.statusCode == 429) {
        throw const TriviaApiException(
          'Too many requests. Please wait a moment and try again.',
        );
      }
      if (response.statusCode != 200) {
        throw const TriviaApiException(
          'The trivia service is unavailable. Please try again.',
        );
      }

      final Object? data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object.');
      }
      return data;
    } on TimeoutException {
      throw const TriviaApiException(
        'The connection took too long. Please try again.',
      );
    } on http.ClientException {
      throw const TriviaApiException(
        'Could not connect. Check your internet connection and try again.',
      );
    } on FormatException {
      throw const TriviaApiException(
        'The trivia service returned unexpected data. Please try again.',
      );
    }
  }

  void close() {
    _closed = true;
    _client.close();
  }
}
