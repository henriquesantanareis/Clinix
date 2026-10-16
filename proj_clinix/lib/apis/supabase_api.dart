import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class SupabaseApi {
  static const isConfigured = SupabaseConfig.url != '' &&
      SupabaseConfig.publishableKey != '';

  static Future<void> initialize() async {
    if (!isConfigured) return;

    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  }

  // ... o resto do arquivo continua igual

  static Stream<AuthState> get authStateChanges =>
      Supabase.instance.client.auth.onAuthStateChange;

  static Session? get currentSession =>
      Supabase.instance.client.auth.currentSession;

  static Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) {
    return Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  static Future<void> resetPasswordForEmail(String email) {
    return Supabase.instance.client.auth.resetPasswordForEmail(email);
  }

  static Future<void> signOut() {
    return Supabase.instance.client.auth.signOut();
  }
}