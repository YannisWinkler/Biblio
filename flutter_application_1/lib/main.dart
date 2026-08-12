import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'router.dart';

/// Loads env vars and initializes Supabase before starting the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Builds the app's MaterialApp shell (theme, title, router).
  ///
  /// Sign-in state and page routing (`/login`, `/movies`, `/my-list`) are
  /// handled by [router], not here.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Films',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: router,
    );
  }
}
