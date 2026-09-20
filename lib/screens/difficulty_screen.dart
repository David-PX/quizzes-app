import 'package:flutter/material.dart';

import '../models/quiz_category.dart';
import '../models/quiz_difficulty.dart';
import '../services/trivia_api.dart';
import 'quiz_screen.dart';

class DifficultyScreen extends StatefulWidget {
  const DifficultyScreen({
    super.key,
    required this.category,
    required this.api,
  });

  final QuizCategory category;
  final TriviaApi api;

  @override
  State<DifficultyScreen> createState() => _DifficultyScreenState();
}

class _DifficultyScreenState extends State<DifficultyScreen> {
  bool _openingQuiz = false;

  Future<void> _start(QuizDifficulty difficulty) async {
    if (_openingQuiz) return;
    _openingQuiz = true;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          category: widget.category,
          difficulty: difficulty,
          api: widget.api,
        ),
      ),
    );
    _openingQuiz = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Choose your difficulty',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Each quiz has 10 random multiple-choice questions.',
                ),
                const SizedBox(height: 20),
                for (final difficulty in QuizDifficulty.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: Colors.white,
                      child: ListTile(
                        key: ValueKey('difficulty-${difficulty.name}'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          foregroundColor: theme.colorScheme.primary,
                          child: Icon(switch (difficulty) {
                            QuizDifficulty.easy => Icons.eco_outlined,
                            QuizDifficulty.medium => Icons.psychology_outlined,
                            QuizDifficulty.hard =>
                              Icons.local_fire_department_outlined,
                          }),
                        ),
                        title: Text(
                          '${difficulty.label} Quiz',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(difficulty.description),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _start(difficulty),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
