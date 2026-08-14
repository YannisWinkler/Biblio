import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/external/tmdb_client.dart';
import 'data/film_repository.dart';
import 'data/profile_repository.dart';
import 'router.dart';

/// Loads env vars and initializes Supabase before starting the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: _requireEnv('SUPABASE_URL'),
    publishableKey: _requireEnv('SUPABASE_PUBLISHABLE_KEY'),
  );
  runApp(MyApp(tmdbClient: TmdbClient(readAccessToken: _requireEnv('TMDB_API_READ_ACCESS_TOKEN'))));
}

/// Reads [key] from the loaded .env file, failing fast with a clear message
/// instead of a bare null-check crash if it's missing or blank.
String _requireEnv(String key) {
  final value = dotenv.env[key];
  if (value == null || value.isEmpty) {
    throw StateError('Missing $key in .env');
  }
  return value;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.tmdbClient});

  final TmdbClient tmdbClient;

  /// Builds the app's MaterialApp shell (theme, title, router) and provides
  /// the repositories/clients every page depends on, so pages ask
  /// `provider` for them instead of constructing their own Supabase- or
  /// TMDB-backed instance.
  ///
  /// Sign-in state and page routing (`/login`, `/movies`, `/my-list`) are
  /// handled by [router], not here.
  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    return MultiProvider(
      providers: [
        Provider<FilmRepository>(create: (_) => FilmRepository(client)),
        Provider<ProfileRepository>(create: (_) => ProfileRepository(client)),
        Provider<TmdbClient>.value(value: tmdbClient),
      ],
      child: MaterialApp.router(
        title: 'Films',
        theme: ThemeData(
          colorScheme: .fromSeed(seedColor: Colors.deepPurple),
        ),
        routerConfig: router,
      ),
    );
  }
}
