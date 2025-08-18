import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/supabase_keys.dart';
import 'core/constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'presentation/controllers/app_controller.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/controllers/food_controller.dart';
import 'presentation/controllers/invitations_controller.dart';
import 'presentation/controllers/inventory_selection_controller.dart';
import 'presentation/widgets/common/custom_bottom_bar.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/inventory/inventory_screen.dart';
import 'presentation/screens/inventory/add_product_screen.dart';
import 'presentation/screens/shopping/shopping_list_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/auth/onboarding_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/signup_screen.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  await Supabase.initialize(
    url: SupabaseKeys.supabaseUrl,
    anonKey: SupabaseKeys.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  await initializeDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => sl<AppController>()),
        ChangeNotifierProvider(create: (_) => sl<AuthController>()),
        ChangeNotifierProvider(create: (_) => sl<FoodController>()),
        ChangeNotifierProvider(create: (_) => sl<InvitationsController>()),
        ChangeNotifierProvider(create: (_) => sl<InventorySelectionController>()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        locale: const Locale('it', 'IT'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('it', 'IT'), Locale('en', 'US')],
        home: const AppRouterWidget(),
        routes: {
          AppConstants.onboardingRoute: (context) => const OnboardingScreen(),
          AppConstants.loginRoute: (context) => const LoginScreen(),
          AppConstants.signupRoute: (context) => const SignUpScreen(),
          AppConstants.homeRoute: (context) => const MainNavigation(),
        },
      ),
    );
  }
}

class AppRouterWidget extends StatefulWidget {
  const AppRouterWidget({super.key});

  @override
  State<AppRouterWidget> createState() => _AppRouterWidgetState();
}

class _AppRouterWidgetState extends State<AppRouterWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppController>().initializeApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, appController, child) {
        return switch (appController.state) {
          AppState.initial || AppState.loading => const _LoadingWidget(),
          AppState.onboarding => const OnboardingScreen(),
          AppState.login => const LoginScreen(),
          AppState.authenticated => const MainNavigation(),
          AppState.error => const _ErrorWidget(),
        };
      },
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget();

  @override
  Widget build(BuildContext context) {
    final error = context.read<AppController>().errorMessage;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.red),
            const SizedBox(height: 16),
            Text(
              error ?? 'Errore sconosciuto',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<AppController>().initializeApp();
              },
              child: const Text('Riprova'),
            ),
          ],
        ),
      ),
    );
  }
}

// === NAVIGAZIONE PRINCIPALE ===
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    HomeScreen(),
    InventoryScreen(),
    AddProductScreen(),
    ShoppingListScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
