class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email è obbligatoria';
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Inserisci un\'email valida';
    }
    
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La password è obbligatoria';
    }
    
    if (value.length < 6) {
      return 'La password deve essere di almeno 6 caratteri';
    }
    
    return null;
  }

  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Questo campo'} è obbligatorio';
    }
    return null;
  }

  static String? quantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La quantità è obbligatoria';
    }
    return null;
  }

  static String? positiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Questo campo è obbligatorio';
    }
    
    final number = double.tryParse(value);
    if (number == null || number <= 0) {
      return 'Inserisci un numero positivo valido';
    }
    
    return null;
  }

  static String? minLength(String? value, int minLength) {
    if (value == null || value.length < minLength) {
      return 'Deve essere di almeno $minLength caratteri';
    }
    return null;
  }

  static String? maxLength(String? value, int maxLength) {
    if (value != null && value.length > maxLength) {
      return 'Non può essere più lungo di $maxLength caratteri';
    }
    return null;
  }
}