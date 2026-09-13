import 'package:flutter/material.dart';

import '../domain/models.dart';

/// One place for the colour, icon and wording of each swipe outcome.
extension GradeStyle on Grade {
  Color get color => switch (this) {
        Grade.know => const Color(0xFF2E9E5B),
        Grade.issues => const Color(0xFFE0A100),
        Grade.unknown => const Color(0xFFD64545),
      };

  IconData get icon => switch (this) {
        Grade.know => Icons.check_rounded,
        Grade.issues => Icons.replay_rounded,
        Grade.unknown => Icons.close_rounded,
      };

  String get label => switch (this) {
        Grade.know => 'Easy',
        Grade.issues => 'Shaky',
        Grade.unknown => 'No idea',
      };

  String get hint => switch (this) {
        Grade.know => 'Never show again',
        Grade.issues => 'Show again later',
        Grade.unknown => 'Show again soon',
      };
}
