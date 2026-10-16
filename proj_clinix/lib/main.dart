import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'apis/supabase_api.dart';
import 'models/modelos_atendimento.dart';
import 'pages/pagina_inicial.dart';
import 'auth/pagina_login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseApi.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clinix',
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
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
      home: const _AuthGate(supabaseConfigured: SupabaseApi.isConfigured),
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

    return StreamBuilder<AuthState>(
      stream: SupabaseApi.authStateChanges,
      builder: (context, snapshot) {
        final session = snapshot.hasData
            ? snapshot.data!.session
            : SupabaseApi.currentSession;
        if (session == null) {
          return const PaginaLogin(supabaseConfigured: true);
        }
        return PaginaInicial(
          key: ValueKey(session.user.id),
          email: session.user.email ?? '',
          perfil: PerfilClinix.deMetadados(session.user.appMetadata),
        );
      },
    );
  }
}
