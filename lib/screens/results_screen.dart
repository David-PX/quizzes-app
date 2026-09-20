import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/quiz_category.dart';
import '../models/quiz_difficulty.dart';
import '../models/quiz_result.dart';
import '../services/trivia_api.dart';
import 'quiz_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    super.key,
    required this.category,
    required this.difficulty,
    required this.result,
    required this.api,
  });

  final QuizCategory category;
  final QuizDifficulty difficulty;
  final QuizResult result;
  final TriviaApi api;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _replaying = false;

  void _playAgain() {
    if (_replaying) return;
    _replaying = true;
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          category: widget.category,
          difficulty: widget.difficulty,
          api: widget.api,
        ),
      ),
    );
  }

  Future<void> _openLink(String url) async {
    try {
      if (await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication))
        return;
    } catch (_) {
      // Show a readable fallback if the device has no browser available.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open the link. Please try again.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = widget.result;
    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Quiz complete!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.category.name} · ${widget.difficulty.label}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  '${result.score} / ${result.total}',
                  key: const ValueKey('result-score'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${result.percentage}% correct',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _playAgain,
                  icon: const Icon(Icons.replay),
                  label: const Text('Play Again'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('Back to Categories'),
                ),
                const SizedBox(height: 28),
                Text('Review your answers', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                for (var i = 0; i < result.answers.length; i++)
                  _AnswerReview(number: i + 1, answer: result.answers[i]),
                const SizedBox(height: 16),
                const Text(
                  'Questions provided by Open Trivia DB. Answer order randomized.',
                  textAlign: TextAlign.center,
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => _openLink('https://opentdb.com/'),
                      child: const Text('Open Trivia DB'),
                    ),
                    TextButton(
                      onPressed: () => _openLink(
                        'https://creativecommons.org/licenses/by-sa/4.0/',
                      ),
                      child: const Text('CC BY-SA 4.0'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnswerReview extends StatelessWidget {
  const _AnswerReview({required this.number, required this.answer});

  final int number;
  final QuizAnswer answer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = answer.isCorrect
        ? const Color(0xFF1B6D35)
        : theme.colorScheme.error;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  answer.isCorrect
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Question $number · ${answer.isCorrect ? 'Correct' : 'Incorrect'}',
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(answer.question.text, style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            Text('Your answer: ${answer.selectedAnswer}'),
            const SizedBox(height: 4),
            Text('Correct answer: ${answer.question.correctAnswer}'),
          ],
        ),
      ),
    );
  }
}
