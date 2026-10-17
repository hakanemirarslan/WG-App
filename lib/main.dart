import 'package:flutter/material.dart';

import 'core/supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WG App',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const ConnectionCheckPage(),
    );
  }
}

class ConnectionCheckPage extends StatefulWidget {
  const ConnectionCheckPage({super.key});

  @override
  State<ConnectionCheckPage> createState() => _ConnectionCheckPageState();
}

class _ConnectionCheckPageState extends State<ConnectionCheckPage> {
  late final Future<int> _catalogCount = _fetchCatalogCount();

  Future<int> _fetchCatalogCount() async {
    final response = await supabase.from('catalog_items').select();
    return response.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WG App')),
      body: Center(
        child: FutureBuilder<int>(
          future: _catalogCount,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text('Supabase error: ${snapshot.error}');
            }
            return Text('Connected to Supabase. catalog_items rows visible: ${snapshot.data}');
          },
        ),
      ),
    );
  }
}
