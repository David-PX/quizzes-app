import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quiz_app/main.dart' as app;
import 'package:quiz_app/widgets/answer_option.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'real API: categories, difficulty, ten answers, results and replay',
    (tester) async {
      app.main();
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 60),
      );
      expect(find.text('General Knowledge'), findsOneWidget);
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      await binding.takeScreenshot('01-categories');
      await tester.tap(find.text('General Knowledge'));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('02-difficulties');
      await tester.tap(find.byKey(const ValueKey('difficulty-easy')));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 60),
      );
      expect(find.text('Question 1 of 10'), findsOneWidget);
      await binding.takeScreenshot('03-question');

      for (var number = 1; number <= 10; number++) {
        final option = find.byWidgetPredicate(
          (widget) => widget is AnswerOption && widget.correct == (number != 2),
        );
        await tester.scrollUntilVisible(option.first, 200);
        await tester.pumpAndSettle();
        await tester.tap(option.first);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('next')));
        await tester.pumpAndSettle();
        if (number == 1) {
          expect(find.text('Score: 1'), findsOneWidget);
          await tester.tap(find.text('Previous'));
          await tester.pumpAndSettle();
          await binding.takeScreenshot('04-confirmed-answer');
          await tester.tap(find.byKey(const ValueKey('next')));
          await tester.pumpAndSettle();
          expect(find.text('Score: 1'), findsOneWidget);
        }
      }
      expect(find.text('9 / 10'), findsOneWidget);
      expect(find.text('90% correct'), findsOneWidget);
      await binding.takeScreenshot('05-results');
      await tester.scrollUntilVisible(find.text('CC BY-SA 4.0'), 500);
      await binding.takeScreenshot('06-review');
      await tester.scrollUntilVisible(find.text('Play Again'), -500);
      await tester.tap(find.text('Play Again'));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 60),
      );
      expect(find.text('Score: 0'), findsOneWidget);
      expect(find.text('Question 1 of 10'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave quiz'));
      await tester.pumpAndSettle();
      expect(find.text('Choose your difficulty'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('General Knowledge'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
