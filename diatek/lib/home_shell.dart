import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/film_repository.dart';
import 'data/models.dart';
import 'data/profile_repository.dart';
import 'state/user_films_controller.dart';
import 'widgets/profile_menu.dart';

/// Shell around the Movies / My List tabs: app bar with the profile menu,
/// bottom navigation wired to the router's branches, and the
/// [UserFilmsController] shared by both tabs so a change in one is
/// immediately visible in the other.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.navigationShell});

  /// Injected by the `StatefulShellRoute` in router.dart; tracks which
  /// branch (Movies / My List) is active and lets us switch between them
  /// while preserving each branch's own navigation state.
  final StatefulNavigationShell navigationShell;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final UserFilmsController _controller;
  late final Future<Profile> _profileFuture;

  @override
  void initState() {
    super.initState();
    // Router guarantees only a signed-in user ever reaches HomeShell (see
    // the redirect in router.dart), so currentUser is never null here.
    final userId = Supabase.instance.client.auth.currentUser!.id;
    _controller = UserFilmsController(
      repository: context.read<FilmRepository>(),
      userId: userId,
    )..load();
    _profileFuture = context.read<ProfileRepository>().fetchProfile(userId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Films'),
          actions: [ProfileMenu(profileFuture: _profileFuture)],
        ),
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: (index) => widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          ),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.movie), label: 'Movies'),
            NavigationDestination(icon: Icon(Icons.list), label: 'My List'),
          ],
        ),
      ),
    );
  }
}
