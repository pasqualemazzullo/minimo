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
git clone https://github.com/pasqualemazzullo/minimo.git
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
1. Crea un file `.env` nella root del progetto:
   ```bash
   touch .env
   ```

2. Apri il file `.env` e aggiungi le tue credenziali Supabase:
   ```
   SUPABASE_URL=your_supabase_project_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

   **Come ottenere le credenziali Supabase:**
   - Vai su [supabase.com](https://supabase.com) e crea un account
   - Crea un nuovo progetto
   - Vai in Settings > API
   - Copia l'URL del progetto e la chiave anonima

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
