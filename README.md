# Minimo

Un'applicazione Flutter minimalista e pulita per gestire la tua spesa, la tua dispensa e tutti i tuoi alimenti affinché tu possa ridurre al minimo gli sprechi.

## Requisiti

- Flutter SDK 3.7.0 o superiore
- Dart SDK
- Android Studio / VS Code o Cursor
- Account Supabase (per il backend)

## Installazione

### 1. Clona il repository
```bash
git clone <repository-url>
cd minimo
```

### 2. Installa Flutter
Se non hai ancora Flutter installato, segui la [guida ufficiale](https://docs.flutter.dev/get-started/install).

### 3. Verifica l'installazione Flutter
```bash
flutter doctor
```

### 4. Installa le dipendenze
```bash
flutter pub get
```

### 5. Configura l'ambiente
1. Copia il file `.env.example` in `.env` (se presente)
2. Configura le tue credenziali Supabase nel file `.env`:
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

### 6. Esegui l'app
```bash
# Per dispositivi Android/iOS connessi o emulatori
flutter run

## Sviluppo

### Comandi utili
```bash
# Analizza il codice
flutter analyze

# Esegui i test
flutter test

# Build per produzione
flutter build apk          # Android APK
```

### Struttura del progetto
```
lib/
├── main.dart              # Entry point dell'app
├── models/               # Modelli dati
├── services/            # Servizi (API, database)
├── providers/           # State management
└── screens/            # Schermate UI
```

## Dipendenze principali

- `supabase_flutter`: Backend e autenticazione
- `provider`: State management
- `shared_preferences`: Storage locale
- `unicons`: Icone
- `flutter_dotenv`: Gestione variabili ambiente

## Troubleshooting

### Problemi comuni

**Errore "flutter not found"**
```bash
export PATH="$PATH:`pwd`/flutter/bin"
```

**Dipendenze non installate correttamente**
```bash
flutter clean
flutter pub get
```

**Problemi con Supabase**
- Verifica che le credenziali nel file `.env` siano corrette
- Controlla la connessione internet

## Supporto

Per problemi o domande, apri un issue nel repository.
