import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseApi {
  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static const isConfigured = _url != '' && _publishableKey != '';

  static Future<void> initialize() async {
    if (!isConfigured) return;

    await Supabase.initialize(
      url: _url,
      publishableKey: _publishableKey,
    );
  }

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