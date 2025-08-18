import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../core/di/service_locator.dart';
import 'inventory_selection_controller.dart';

enum AppState {
  initial,
  loading,
  onboarding,
  login,
  authenticated,
  error,
}

class AppController extends ChangeNotifier {
  AppState _state = AppState.initial;
  AppState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _hasSeenOnboarding = false;
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  StreamSubscription<AuthState>? _authSubscription;

  void _setState(AppState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _setState(AppState.error);
  }

  Future<void> initializeApp() async {
    try {
      _setState(AppState.loading);
      
      await _loadPreferences();
      await _checkAuthenticationStatus();
      _setupAuthListener();
      
      // Initialize inventory selection controller if authenticated
      if (_isAuthenticated) {
        try {
          await sl<InventorySelectionController>().initialize();
        } catch (e) {
          Logger.warning('Failed to initialize inventory selection controller', error: e);
        }
      }
      
      _determineInitialRoute();
    } catch (e) {
      Logger.error('App initialization failed', error: e);
      _setError('Errore durante l\'inizializzazione dell\'app');
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasSeenOnboarding = prefs.getBool(AppConstants.hasSeenOnboardingKey) ?? false;
    } catch (e) {
      Logger.error('Failed to load preferences', error: e);
      _hasSeenOnboarding = false;
    }
  }

  Future<void> _checkAuthenticationStatus() async {
    try {
      // Controlla se l'utente ha una sessione attiva con Supabase
      final session = Supabase.instance.client.auth.currentSession;
      _isAuthenticated = session != null;
      
      Logger.info('Authentication status checked: $_isAuthenticated');
    } catch (e) {
      Logger.error('Failed to check authentication status', error: e);
      _isAuthenticated = false;
    }
  }

  void _determineInitialRoute() {
    if (_isAuthenticated) {
      _setState(AppState.authenticated);
    } else if (_hasSeenOnboarding) {
      _setState(AppState.login);
    } else {
      _setState(AppState.onboarding);
    }
  }

  Future<void> setOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.hasSeenOnboardingKey, true);
      _hasSeenOnboarding = true;
      _setState(AppState.login);
    } catch (e) {
      Logger.error('Failed to set onboarding completed', error: e);
      _setError('Errore nel salvataggio delle preferenze');
    }
  }

  void setAuthenticated(bool authenticated) {
    _isAuthenticated = authenticated;
    if (authenticated) {
      _setState(AppState.authenticated);
    } else {
      _setState(_hasSeenOnboarding ? AppState.login : AppState.onboarding);
    }
  }

  Future<void> resetApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _hasSeenOnboarding = false;
      _isAuthenticated = false;
      _setState(AppState.onboarding);
    } catch (e) {
      Logger.error('Failed to reset app', error: e);
      _setError('Errore nel reset dell\'app');
    }
  }

  void _setupAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        final session = data.session;
        final isAuthenticated = session != null;
        
        Logger.info('Auth state changed: isAuthenticated=$isAuthenticated');
        
        if (_isAuthenticated != isAuthenticated) {
          _isAuthenticated = isAuthenticated;
          
          if (isAuthenticated) {
            _setState(AppState.authenticated);
            // Initialize inventory selection controller when user authenticates
            _initializeInventoryController();
          } else {
            _setState(_hasSeenOnboarding ? AppState.login : AppState.onboarding);
          }
        }
      },
      onError: (error) {
        Logger.error('Auth state change error', error: error);
      },
    );
  }

  Future<void> _initializeInventoryController() async {
    try {
      await sl<InventorySelectionController>().initialize();
    } catch (e) {
      Logger.warning('Failed to initialize inventory selection controller', error: e);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}