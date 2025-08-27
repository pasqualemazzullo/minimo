import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// New architecture imports
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/theme/app_theme.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentIndex = 0;
  bool _isCompleting = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_isCompleting) return;

    setState(() {
      _isCompleting = true;
    });

    try {
      Logger.info('Completing onboarding process');

      // Save onboarding completion preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.hasSeenOnboardingKey, true);

      Logger.info('Onboarding completed successfully');

      if (mounted) {
        // Navigate to login screen with custom animation
        _navigateToLoginWithAnimation();
      }
    } catch (error) {
      Logger.error('Error saving onboarding preferences', error: error);

      // Even if preferences fail, continue to login
      if (mounted) {
        _navigateToLoginWithAnimation();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  void _navigateToLoginWithAnimation() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 800),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Combined fade and slide transition
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          final slideAnimation = Tween(
            begin: begin,
            end: end,
          ).animate(CurvedAnimation(parent: animation, curve: curve));

          final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
            ),
          );

          // Scale transition for the outgoing screen
          final scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
            CurvedAnimation(
              parent: secondaryAnimation,
              curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
            ),
          );

          return Stack(
            children: [
              // Outgoing screen (onboarding) with scale effect
              Transform.scale(
                scale: scaleAnimation.value,
                child: FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                    CurvedAnimation(
                      parent: secondaryAnimation,
                      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
                    ),
                  ),
                  child:
                      Container(), // This will be the current onboarding screen
                ),
              ),
              // Incoming screen (login) with slide and fade
              SlideTransition(
                position: slideAnimation,
                child: FadeTransition(opacity: fadeAnimation, child: child),
              ),
            ],
          );
        },
      ),
    );
  }

  void _nextPage() {
    if (_currentIndex < _onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  void _skipOnboarding() {
    if (_isCompleting) return;

    // Jump to last page or complete onboarding directly
    if (_currentIndex == _onboardingPages.length - 1) {
      _completeOnboarding();
    } else {
      _pageController.animateToPage(
        _onboardingPages.length - 1,
        duration: const Duration(milliseconds: 800),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header with App Name and Skip
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // App Logo/Name
                    Text(
                      AppConstants.appName,
                      style: AppTheme.headline2.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Skip Button with fixed space
                    SizedBox(
                      width: 80, // Fixed width to maintain layout consistency
                      height: 40, // Fixed height
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        child:
                            _currentIndex < _onboardingPages.length - 1
                                ? TextButton(
                                  key: const ValueKey('skip_button'),
                                  onPressed:
                                      _isCompleting ? null : _skipOnboarding,
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.grey600,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: Text(
                                    'Salta',
                                    style: AppTheme.bodyText2.copyWith(
                                      color:
                                          _isCompleting
                                              ? AppTheme.grey
                                              : AppTheme.grey600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )
                                : SizedBox(
                                  key: const ValueKey('empty_skip_space'),
                                  width: 80,
                                  height: 40,
                                ),
                      ),
                    ),
                  ],
                ),
              ),

              // Page View Content
              Expanded(
                flex: 5,
                child: PageView.builder(
                  itemCount: _onboardingPages.length,
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final page = _onboardingPages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          // Illustration
                          Expanded(
                            flex: 4,
                            child: Container(
                              margin: const EdgeInsets.only(top: 20, bottom: 0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: AppTheme.grey50,
                              ),
                              child: Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    page.imagePath,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Title and Description
                          Expanded(
                            flex: 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  page.title,
                                  textAlign: TextAlign.center,
                                  style: AppTheme.headline3.copyWith(),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  page.description,
                                  textAlign: TextAlign.center,
                                  style: AppTheme.bodyText1.copyWith(
                                    color: AppTheme.grey600,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Page Indicators
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _onboardingPages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentIndex == index ? 24.0 : 8.0,
                      height: 8.0,
                      decoration: BoxDecoration(
                        color:
                            _currentIndex == index
                                ? AppTheme.primaryColor
                                : AppTheme.grey300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

              // Action Buttons with Smooth Transition
              Container(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Main Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _isCompleting
                                ? null
                                : () {
                                  if (_currentIndex ==
                                      _onboardingPages.length - 1) {
                                    _completeOnboarding();
                                  } else {
                                    _nextPage();
                                  }
                                },
                        style: AppTheme.primaryButtonStyle.copyWith(
                          minimumSize: WidgetStateProperty.all(
                            const Size(double.infinity, 56),
                          ),
                        ),
                        child:
                            _isCompleting
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.white,
                                    ),
                                  ),
                                )
                                : Text(
                                  _currentIndex == _onboardingPages.length - 1
                                      ? 'Iniziamo!'
                                      : 'Continua',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
                    ),

                    // Spacing
                    const SizedBox(height: 12),

                    // Animated Back Button with fixed container
                    SizedBox(
                      height: 48, // Fixed height to prevent overflow
                      width: double.infinity,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.3),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeInOut,
                                ),
                              ),
                              child: child,
                            ),
                          );
                        },
                        child:
                            _currentIndex > 0
                                ? TextButton(
                                  key: const ValueKey('back_button'),
                                  onPressed:
                                      _isCompleting
                                          ? null
                                          : () {
                                            _pageController.previousPage(
                                              duration: const Duration(
                                                milliseconds: 500,
                                              ),
                                              curve: Curves.fastOutSlowIn,
                                            );
                                          },
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.grey600,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    minimumSize: const Size(
                                      double.infinity,
                                      48,
                                    ),
                                  ),
                                  child: Text(
                                    'Indietro',
                                    style: AppTheme.bodyText2.copyWith(
                                      color:
                                          _isCompleting
                                              ? AppTheme.grey
                                              : AppTheme.grey600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )
                                : SizedBox(
                                  key: const ValueKey('empty_space'),
                                  width: double.infinity,
                                  height: 48,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Data Models ---

class OnboardingPage {
  final String title;
  final String description;
  final String imagePath;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

// --- Static Data ---

final List<OnboardingPage> _onboardingPages = [
  const OnboardingPage(
    title: 'Riduci lo Spreco',
    description:
        'Tieni traccia degli alimenti in scadenza e riduci lo spreco alimentare con notifiche intelligenti.',
    imagePath: 'assets/images/reduce_waste.jpg',
  ),
  const OnboardingPage(
    title: 'Organizza la Dispensa',
    description:
        'Gestisci facilmente tutti i tuoi alimenti con categorie, date di scadenza e quantità.',
    imagePath: 'assets/images/manage_pantry.png',
  ),
  const OnboardingPage(
    title: 'Lista della Spesa Smart',
    description:
        'Crea liste della spesa intelligenti basate sui tuoi consumi e alimenti in esaurimento.',
    imagePath: 'assets/images/shopping_list.jpg',
  ),
  const OnboardingPage(
    title: 'Inizia il Viaggio',
    description:
        'Sei pronto per trasformare il modo in cui gestisci la tua dispensa e ridurre gli sprechi!',
    imagePath: 'assets/images/start_your_journey.jpg',
  ),
];
