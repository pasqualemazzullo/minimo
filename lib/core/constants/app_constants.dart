class AppConstants {
  static const String appName = 'Minimo';
  static const String fontFamily = 'ArticulatCF';
  static const String headlineFontFamily = 'Recoleta';
  
  // API Constants
  static const int apiTimeoutDuration = 30000; // 30 seconds
  static const int cacheTimeoutDuration = 300000; // 5 minutes
  
  // Database Constants
  // Deprecated: Use FoodCategories.defaultCategory instead
  static const String defaultCategory = 'Generale';
  static const String defaultEmoji = '📦';
  
  // Preferences Keys
  static const String hasSeenOnboardingKey = 'has_seen_onboarding';
  
  // Routes
  static const String onboardingRoute = '/onboarding';
  static const String loginRoute = '/login'; 
  static const String signupRoute = '/signup';
  static const String homeRoute = '/home';
}

class AppStrings {
  // Common
  static const String loading = 'Caricamento...';
  static const String error = 'Errore';
  static const String retry = 'Riprova';
  static const String cancel = 'Annulla';
  static const String save = 'Salva';
  static const String delete = 'Elimina';
  
  // Auth
  static const String login = 'Accedi';
  static const String signup = 'Registrati';
  static const String logout = 'Esci';
  static const String email = 'Email';
  static const String password = 'Password';
  
  // Inventory
  static const String inventory = 'Inventario';
  static const String addProduct = 'Aggiungi Prodotto';
  static const String outOfStock = 'Esaurito';
  static const String expiringSoon = 'In scadenza';
  static const String expired = 'Scaduto';
  
  // Shopping List
  static const String shoppingList = 'Lista della Spesa';
  static const String restockAll = 'Rifornisci tutto';
  static const String restockSelected = 'Rifornisci selezionati';
  
  // Errors
  static const String networkError = 'Errore di connessione. Verifica la tua connessione internet.';
  static const String serverError = 'Errore del server. Riprova più tardi.';
  static const String authError = 'Errore di autenticazione. Effettua nuovamente il login.';
  static const String validationError = 'Dati non validi. Controlla i campi inseriti.';
  static const String cacheError = 'Errore nell\'accesso ai dati locali.';
}