import 'package:flutter/material.dart';

import '../models/quiz_category.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key, required this.category, this.onTap});

  final QuizCategory category;
  final VoidCallback? onTap;

  // Presentation belongs to the app: the API only provides id and name.
  static const _icons = <int, IconData>{
    9: Icons.menu_book_rounded,
    10: Icons.auto_stories_rounded,
    11: Icons.movie_outlined,
    12: Icons.music_note_rounded,
    13: Icons.theater_comedy_outlined,
    14: Icons.tv_rounded,
    15: Icons.sports_esports_outlined,
    16: Icons.casino_outlined,
    17: Icons.science_outlined,
    18: Icons.computer_rounded,
    19: Icons.calculate_outlined,
    20: Icons.auto_awesome_outlined,
    21: Icons.sports_soccer_rounded,
    22: Icons.public_rounded,
    23: Icons.account_balance_rounded,
    24: Icons.how_to_vote_outlined,
    25: Icons.palette_outlined,
    26: Icons.star_outline_rounded,
    27: Icons.pets_rounded,
    28: Icons.directions_car_outlined,
    29: Icons.bubble_chart_outlined,
    30: Icons.devices_other_rounded,
    31: Icons.animation_rounded,
    32: Icons.face_retouching_natural,
  };

  static const _descriptions = <int, String>{
    9: 'Test your general knowledge',
    10: 'Stories, authors and books',
    11: 'Movies and the big screen',
    12: 'Songs, artists and albums',
    13: 'Discover the world of theatre',
    14: 'Shows and memorable characters',
    15: 'Explore the world of gaming',
    16: 'Games around the table',
    17: 'Questions about science and nature',
    18: 'Computers and technology',
    19: 'Numbers, shapes and logic',
    20: 'Gods, legends and myths',
    21: 'Teams, players and records',
    22: 'Places around the world',
    23: 'Historical events and figures',
    24: 'Governments and world affairs',
    25: 'Artists and their creations',
    26: 'Famous faces and their stories',
    27: 'Discover the animal kingdom',
    28: 'Cars, transport and more',
    29: 'Heroes and illustrated stories',
    30: 'Inventions and everyday tech',
    31: 'Japanese animation and manga',
    32: 'Animated worlds and characters',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shadowColor: const Color(0x26000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE9E2EF)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 180),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _icons[category.id] ?? Icons.quiz_outlined,
                  size: 44,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  category.name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 16,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _descriptions[category.id] ?? 'Explore a new topic',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    height: 1.3,
                    color: theme.colorScheme.onSurfaceVariant,
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
