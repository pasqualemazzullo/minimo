import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Registrazione utente
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
        emailRedirectTo: 'com.minimo.minimo://signup-callback/',
      );
      return response;
    } catch (error) {
      rethrow;
    }
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'com.minimo.minimo://reset-password/',
      );
    } catch (error) {
      rethrow;
    }
  }

  // Login utente
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (error) {
      rethrow;
    }
  }

  // Logout utente
  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (error) {
      rethrow;
    }
  }

  // Ottieni utente corrente
  static User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // Verifica se l'utente è autenticato
  static bool isAuthenticated() {
    return _supabase.auth.currentUser != null;
  }

  // Invia nuovamente email di conferma
  static Future<void> resendConfirmation(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: 'com.minimo.minimo://signup-callback/',
      );
    } catch (error) {
      rethrow;
    }
  }

  // Verifica se l'email è confermata
  static bool isEmailConfirmed() {
    final user = _supabase.auth.currentUser;
    return user?.emailConfirmedAt != null;
  }
}
