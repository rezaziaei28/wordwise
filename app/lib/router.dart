import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/settings.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/review/review_screen.dart';
import 'features/settings/about_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/stats/stats_screen.dart';
import 'features/words/word_detail_screen.dart';
import 'features/words/words_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final settings = await ref.read(settingsProvider.future);
      final onOnboarding = state.matchedLocation == '/onboarding';
      if (!settings.onboarded && !onOnboarding) return '/onboarding';
      if (settings.onboarded && onOnboarding) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const ReviewScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(
        path: '/words',
        builder: (_, _) => const WordsScreen(),
        routes: [
          GoRoute(path: ':id', builder: (_, s) => WordDetailScreen(wordId: int.parse(s.pathParameters['id']!))),
        ],
      ),
      GoRoute(path: '/stats', builder: (_, _) => const StatsScreen()),
      GoRoute(
        path: '/settings',
        builder: (_, _) => const SettingsScreen(),
        routes: [GoRoute(path: 'about', builder: (_, _) => const AboutScreen())],
      ),
    ],
  );
});
