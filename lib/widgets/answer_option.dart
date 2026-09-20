import 'package:flutter/material.dart';

class AnswerOption extends StatelessWidget {
  const AnswerOption({
    super.key,
    required this.index,
    required this.text,
    required this.selected,
    required this.confirmed,
    required this.correct,
    required this.onTap,
  });

  final int index;
  final String text;
  final bool selected;
  final bool confirmed;
  final bool correct;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = confirmed && correct
        ? const Color(0xFF1B6D35)
        : confirmed && selected
        ? theme.colorScheme.error
        : theme.colorScheme.primary;
    final highlighted = selected || (confirmed && correct);
    return Semantics(
      selected: selected,
      button: true,
      enabled: !confirmed,
      child: Material(
        color: highlighted ? color.withValues(alpha: 0.09) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: highlighted ? color : const Color(0xFFE5DFE9),
            width: highlighted ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: confirmed ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: highlighted
                      ? color
                      : const Color(0xFFF0EEF2),
                  foregroundColor: highlighted
                      ? Colors.white
                      : theme.colorScheme.onSurface,
                  child: Text(
                    String.fromCharCode(65 + index),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
                if (highlighted) ...[
                  const SizedBox(width: 8),
                  Icon(
                    confirmed
                        ? (correct ? Icons.check_circle : Icons.cancel)
                        : Icons.check_circle_outline,
                    color: color,
                    size: 22,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
