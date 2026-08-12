import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';

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

  /// Builds the app's MaterialApp shell (theme, title, home page).
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Films',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthGate(),
    );
  }
}

/// Shows the auth page when signed out, the home page when signed in.
/// Rebuilds automatically whenever Supabase's auth state changes.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;
        if (session == null) {
          return const AuthPage();
        }
        return const MyHomePage(title: 'Data Home Page');
      },
    );
  }
}

/// Home page shown once the user is signed in: an app bar with the user's
/// profile menu, and a list of films fetched from Supabase.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  /// Fetches all rows from the 'film' table. Created once per State instance
  /// so rebuilds (e.g. from the profile FutureBuilder) don't re-query.
  final Future<List<Map<String, dynamic>>> _future =
      Supabase.instance.client.from('film').select();

  /// Fetches the signed-in user's profile (username + avatar).
  final Future<Map<String, dynamic>> _profileFuture = Supabase.instance.client
      .from('profile')
      .select()
      .eq('id', Supabase.instance.client.auth.currentUser!.id)
      .single();

  /// Builds the page: an app bar plus a list of films loaded from Supabase.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          FutureBuilder<Map<String, dynamic>>(
            future: _profileFuture,
            builder: (context, snapshot) {
              final profile = snapshot.data;
              final username = profile?['username'] as String?;
              final avatarUrl = profile?['avatar'] as String?;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (username != null) Text(username),
                  const SizedBox(width: 8),
                  /// Tapping the avatar reveals the sign-out option.
                  PopupMenuButton<String>(
                    tooltip: 'Account',
                    onSelected: (_) => Supabase.instance.client.auth.signOut(),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'logout',
                        child: Text('Sign out'),
                      ),
                    ],
                    child: CircleAvatar(
                      backgroundImage:
                          (avatarUrl != null && avatarUrl.isNotEmpty)
                              ? NetworkImage(avatarUrl)
                              : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? const Icon(Icons.person)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load films: ${snapshot.error}'));
          }
          /// Show a spinner while the query is still in flight.
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final films = snapshot.data!;
          return ListView.builder(
            itemCount: films.length,
            itemBuilder: (context, index) {
              final film = films[index];
              return ListTile(
                title: Text(film['name'] as String? ?? 'Untitled'),
              );
            },
          );
        },
      ),
    );
  }
}
