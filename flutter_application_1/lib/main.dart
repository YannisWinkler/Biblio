import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Loads env vars and initializes Supabase before starting the app.
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

  // Builds the app's MaterialApp shell (theme, title, home page).
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Films',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Data Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Query fetching all rows from the 'film' table.
  final _future = Supabase.instance.client
      .from('film')
      .select();

  // Builds the page: an app bar plus a list of films loaded from Supabase.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          // Show a spinner while the query is still in flight.
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final films = snapshot.data!;
          return ListView.builder(
            itemCount: films.length,
            itemBuilder: ((context, index) {
              final film = films[index];
              return ListTile(
                title: Text(film['name']),
              );
            }),
          );
        },
      ),
    );
  }
}
