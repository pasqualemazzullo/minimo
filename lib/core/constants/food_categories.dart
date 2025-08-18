class FoodCategories {
  // Lista delle categorie alimentari disponibili
  static const List<String> categories = [
    'Frutta',
    'Verdura', 
    'Latticini',
    'Carne',
    'Pesce',
    'Cereali',
    'Bevande',
    'Dolci',
    'Condimenti',
    'Surgelati',
    'Snack',
    'Altro',
  ];

  // Categoria predefinita
  static const String defaultCategory = 'Altro';

  // Emoji associate alle categorie per migliorare l'UX
  static const Map<String, String> categoryEmojis = {
    'Frutta': '🍎',
    'Verdura': '🥬',
    'Latticini': '🥛',
    'Carne': '🥩', 
    'Pesce': '🐟',
    'Cereali': '🌾',
    'Bevande': '🥤',
    'Dolci': '🍰',
    'Condimenti': '🧂',
    'Surgelati': '❄️',
    'Snack': '🍿',
    'Altro': '📦',
  };

  // Metodo per ottenere l'emoji di una categoria
  static String getCategoryEmoji(String category) {
    return categoryEmojis[category] ?? categoryEmojis[defaultCategory]!;
  }

  // Metodo per verificare se una categoria è valida
  static bool isValidCategory(String category) {
    return categories.contains(category);
  }

  // Metodo per ottenere la categoria corretta o quella predefinita
  static String getValidCategoryOrDefault(String? category) {
    if (category == null || category.trim().isEmpty) {
      return defaultCategory;
    }
    return isValidCategory(category) ? category : defaultCategory;
  }
}