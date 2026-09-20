import 'package:flutter/material.dart';

import '../models/quiz_category.dart';
import '../services/trivia_api.dart';
import '../widgets/category_card.dart';
import 'difficulty_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key, this.api});

  // Tests can supply an API with a simulated HTTP client.
  final TriviaApi? api;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final TriviaApi _api;
  late Future<List<QuizCategory>> _categoriesFuture;
  bool _openingCategory = false;

  Future<void> _openCategory(QuizCategory category) async {
    if (_openingCategory) return;
    _openingCategory = true;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => DifficultyScreen(category: category, api: _api),
      ),
    );
    _openingCategory = false;
  }

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? TriviaApi();
    // Store the Future once. Creating it in build would repeat the request.
    _categoriesFuture = _api.fetchCategories();
  }

  void _retry() {
    setState(() {
      _categoriesFuture = _api.fetchCategories();
    });
  }

  @override
  void dispose() {
    if (widget.api == null) {
      _api.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz App')),
      body: SafeArea(
        child: FutureBuilder<List<QuizCategory>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      semanticsLabel: 'Loading categories',
                    ),
                    SizedBox(height: 16),
                    Text('Loading categories...'),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              final error = snapshot.error;
              return _StatusMessage(
                icon: Icons.cloud_off_outlined,
                title: 'Could not load categories',
                message: error is TriviaApiException
                    ? error.message
                    : 'Something went wrong. Please try again.',
                onRetry: _retry,
              );
            }

            final categories = snapshot.data ?? const <QuizCategory>[];
            if (categories.isEmpty) {
              return _StatusMessage(
                icon: Icons.category_outlined,
                title: 'No categories available',
                message: 'Please try again in a moment.',
                onRetry: _retry,
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final textScaler = MediaQuery.textScalerOf(context);
                    final useOneColumn =
                        constraints.maxWidth < 320 ||
                        textScaler.scale(16) >= 24;
                    final columns = useOneColumn ? 1 : 2;

                    // Rows grow with their text instead of clipping long names.
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: (categories.length / columns).ceil(),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, row) {
                        final first = row * columns;
                        if (columns == 1) {
                          return CategoryCard(
                            category: categories[first],
                            onTap: () => _openCategory(categories[first]),
                          );
                        }
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: CategoryCard(
                                  category: categories[first],
                                  onTap: () => _openCategory(categories[first]),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: first + 1 < categories.length
                                    ? CategoryCard(
                                        category: categories[first + 1],
                                        onTap: () => _openCategory(
                                          categories[first + 1],
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
