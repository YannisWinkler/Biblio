import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_page.dart';
import 'home_page.dart';
import 'home_shell.dart';
import 'my_list_page.dart';

/// Adapts a [Stream] into a [Listenable] so go_router re-runs its
/// `redirect` callback whenever Supabase's auth state changes (sign in,
/// sign out, token refresh).
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// App-wide route table.
///
/// `/login` is public. Every other route requires a signed-in session:
/// signed-out users are redirected to `/login`, and a signed-in user
/// visiting `/login` is sent to `/home`. Home and My List are separate URLs
/// (rather than an in-memory tab index) so they're bookmarkable and support
/// the browser back/forward buttons on web. TMDB search lives in
/// [HomeShell] itself (see there), not as its own route.
final GoRouter router = GoRouter(
  initialLocation: '/home',
  refreshListenable:
      GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange),
  redirect: (context, state) {
    final signedIn = Supabase.instance.client.auth.currentSession != null;
    final onLoginPage = state.matchedLocation == '/login';

    if (!signedIn) return onLoginPage ? null : '/login';
    if (onLoginPage) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const AuthPage()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          HomeShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/home', builder: (context, state) => const HomePage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/my-list', builder: (context, state) => const MyListPage()),
          ],
        ),
      ],
    ),
  ],
);
