import 'package:flutter/material.dart';

import '../models/quiz_category.dart';
import '../models/quiz_difficulty.dart';
import '../services/trivia_api.dart';
import '../state/quiz_session.dart';
import '../widgets/answer_option.dart';
import 'results_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.category,
    required this.difficulty,
    required this.api,
  });

  final QuizCategory category;
  final QuizDifficulty difficulty;
  final TriviaApi api;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  QuizSession? _session;
  Object? _error;
  bool _loading = true;
  bool _dialogOpen = false;
  bool _allowExit = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final questions = await widget.api.fetchQuestions(
        categoryId: widget.category.id,
        difficulty: widget.difficulty,
      );
      if (!mounted) return;
      setState(() {
        _session = QuizSession(questions);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _retry() {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    _load();
  }

  Future<void> _requestExit() async {
    if (_dialogOpen) return;
    if (_session == null || _session!.isComplete) {
      Navigator.of(context).pop();
      return;
    }
    _dialogOpen = true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave this quiz?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep playing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave quiz'),
          ),
        ],
      ),
    );
    _dialogOpen = false;
    if (!mounted || leave != true) return;
    setState(() => _allowExit = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop();
  }

  void _advance() {
    final session = _session!;
    if (!session.canAdvance) return;
    session.advance();
    if (session.isComplete) {
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            category: widget.category,
            difficulty: widget.difficulty,
            result: session.result,
            api: widget.api,
          ),
        ),
      );
    } else {
      _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _session?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    return PopScope<void>(
      canPop: _allowExit || session == null || session.isComplete,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _requestExit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _requestExit),
          title: Text('${widget.difficulty.label} Quiz'),
        ),
        body: SafeArea(
          child: _loading
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(semanticsLabel: 'Loading quiz'),
                      SizedBox(height: 16),
                      Text('Preparing your quiz...'),
                    ],
                  ),
                )
              : _error != null
              ? _buildError()
              : ListenableBuilder(
                  listenable: session!,
                  builder: (context, child) => _buildQuestions(session),
                ),
        ),
      ),
    );
  }

  Widget _buildError() {
    final error = _error;
    final message = error is TriviaApiException
        ? error.message
        : 'Something went wrong. Please try again.';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load quiz',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (error is! TriviaApiException || error.canRetry)
              FilledButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Choose another difficulty'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestions(QuizSession session) {
    final theme = Theme.of(context);
    final question = session.currentQuestion;
    return Column(
      children: [
        Container(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Question ${session.index + 1} of ${session.questions.length}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Score: ${session.score}',
                      key: const ValueKey('score'),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: session.progress,
                semanticsLabel: 'Quiz progress',
              ),
            ],
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  Text(widget.category.name, style: theme.textTheme.labelLarge),
                  const SizedBox(height: 12),
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        question.text,
                        style: theme.textTheme.titleMedium?.copyWith(
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (var i = 0; i < question.options.length; i++) ...[
                    AnswerOption(
                      key: ValueKey('answer-$i'),
                      index: i,
                      text: question.options[i],
                      selected: session.selectedIndex == i,
                      confirmed: session.isConfirmed,
                      correct: i == question.correctIndex,
                      onTap: () => session.selectAnswer(i),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (session.isConfirmed)
                    Text(
                      'Answer confirmed. Correct answer: ${question.correctAnswer}',
                      style: theme.textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: session.canGoPrevious
                      ? () {
                          session.previous();
                          _scrollController.jumpTo(0);
                        }
                      : null,
                  child: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  key: const ValueKey('next'),
                  onPressed: session.canAdvance ? _advance : null,
                  child: Text(session.isLastQuestion ? 'Finish' : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
