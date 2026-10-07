import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pagina_inicial.dart';
import 'pagina_login.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabasePublishableKey =
    String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
const _supabaseConfigured =
    _supabaseUrl != '' && _supabasePublishableKey != '';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_supabaseConfigured) {
    await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabasePublishableKey,
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clinix',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F6F1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF167A68),
          primary: const Color(0xFF167A68),
          surface: const Color(0xFFF4F6F1),
        ),
        fontFamily: 'Roboto',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDCE3DD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDCE3DD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF167A68), width: 1.5),
          ),
        ),
      ),
      home: const _AuthGate(supabaseConfigured: _supabaseConfigured),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate({required this.supabaseConfigured});

  final bool supabaseConfigured;

  @override
  Widget build(BuildContext context) {
    if (!supabaseConfigured) {
      return const PaginaLogin(supabaseConfigured: false);
    }

    final client = Supabase.instance.client;
    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.hasData
            ? snapshot.data!.session
            : client.auth.currentSession;
        if (session == null) {
          return const PaginaLogin(supabaseConfigured: true);
        }
        return PaginaInicial(email: session.user.email ?? '');
      },
    );
  }
}
