import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/result.dart';
import '../../../shared/theme/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/app_controller.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authController = context.read<AuthController>();

    final result = await authController.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (mounted) {
      result.fold(
        (failure) => _showErrorSnackBar(
          authController.errorMessage ?? 'Errore durante l\'accesso',
        ),
        (user) {
          _showSuccessSnackBar('Accesso effettuato con successo!');
          // Notifica l'AppController che l'autenticazione è avvenuta con successo
          context.read<AppController>().setAuthenticated(true);
          
          // Forza il redirect usando Navigator
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppConstants.homeRoute, 
                (route) => false,
              );
            }
          });
        },
      );
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showErrorSnackBar('Inserisci la tua email per recuperare la password');
      return;
    }

    final emailValidationError = Validators.email(email);
    if (emailValidationError != null) {
      _showErrorSnackBar(emailValidationError);
      return;
    }

    _showSuccessSnackBar('Funzionalità in via di sviluppo');
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: AppTheme.white)),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: AppTheme.white)),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateToSignUp() {
    if (!mounted || context.read<AuthController>().isLoading) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Pronto a salvare un altro avocado?',
                          textAlign: TextAlign.center,
                          style: AppTheme.headline2,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Accedi al tuo account ${AppConstants.appName} per continuare',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),

                        // Email Field
                        Consumer<AuthController>(
                          builder: (context, authController, child) {
                            return TextFormField(
                              controller: _emailController,
                              cursorColor: AppTheme.primaryColor,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              enabled: !authController.isLoading,
                              decoration: InputDecoration(
                                labelText: 'Email *',
                                labelStyle: const TextStyle(
                                  color: AppTheme.unselectedText,
                                  fontSize: 14,
                                ),
                                floatingLabelStyle: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: AppTheme.grey50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppTheme.cardBorder,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppTheme.cardBorder,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppTheme.cardBorder,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: Validators.email,
                            );
                          },
                        ),
                        const SizedBox(height: 15),

                        // Password Field
                        Consumer<AuthController>(
                          builder: (context, authController, child) {
                            return TextFormField(
                              controller: _passwordController,
                              cursorColor: AppTheme.primaryColor,
                              obscureText: _isPasswordObscured,
                              keyboardType: TextInputType.visiblePassword,
                              textInputAction: TextInputAction.done,
                              enabled: !authController.isLoading,
                              onFieldSubmitted: (_) => _handleLogin(),
                              decoration: InputDecoration(
                                labelText: 'Password *',
                                labelStyle: const TextStyle(
                                  color: AppTheme.unselectedText,
                                  fontSize: 14,
                                ),
                                floatingLabelStyle: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: AppTheme.grey50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppTheme.cardBorder,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppTheme.cardBorder,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppTheme.cardBorder,
                                    width: 2,
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  onPressed:
                                      authController.isLoading
                                          ? null
                                          : () => setState(() {
                                            _isPasswordObscured =
                                                !_isPasswordObscured;
                                          }),
                                  icon: Icon(
                                    _isPasswordObscured
                                        ? UniconsLine.eye
                                        : UniconsLine.eye_slash,
                                    color:
                                        authController.isLoading
                                            ? AppTheme.grey
                                            : AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              validator: Validators.password,
                            );
                          },
                        ),
                        const SizedBox(height: 8),

                        // Forgot Password
                        Consumer<AuthController>(
                          builder: (context, authController, child) {
                            return Row(
                              children: [
                                const Spacer(),
                                TextButton(
                                  onPressed:
                                      authController.isLoading
                                          ? null
                                          : _handleForgotPassword,
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        authController.isLoading
                                            ? AppTheme.grey
                                            : AppTheme.primaryColor,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                  child: const Text(
                                    'Password dimenticata?',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 35),

                        // Login Button
                        Consumer<AuthController>(
                          builder: (context, authController, child) {
                            return ElevatedButton(
                              onPressed:
                                  authController.isLoading
                                      ? null
                                      : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: AppTheme.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 24,
                                ),
                                minimumSize: const Size(double.infinity, 0),
                              ),
                              child:
                                  authController.isLoading
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppTheme.white,
                                              ),
                                        ),
                                      )
                                      : const Text(
                                        'Accedi',
                                        style: TextStyle(
                                          color: AppTheme.white,
                                          fontFamily: AppConstants.fontFamily,
                                          fontSize: 14,
                                        ),
                                      ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Sign Up Link
                        Consumer<AuthController>(
                          builder: (context, authController, child) {
                            return RichText(
                              text: TextSpan(
                                text: 'Non hai un account? ',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: AppConstants.fontFamily,
                                  color: AppTheme.grey,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Registrati',
                                    recognizer:
                                        TapGestureRecognizer()
                                          ..onTap =
                                              authController.isLoading
                                                  ? null
                                                  : _navigateToSignUp,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          authController.isLoading
                                              ? AppTheme.grey
                                              : AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  children: const [
                    Divider(color: AppTheme.unselectedText),
                    SizedBox(height: 10),
                    _TermsAndConditionsWidget(),
                    SizedBox(height: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Reusable Components ---

class _TermsAndConditionsWidget extends StatelessWidget {
  const _TermsAndConditionsWidget();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: RichText(
        text: TextSpan(
          text: 'Accedendo accetti i nostri ',
          style: const TextStyle(
            fontSize: 14,
            fontFamily: AppConstants.fontFamily,
            color: AppTheme.grey,
          ),
          children: [
            TextSpan(
              text: 'Termini',
              style: const TextStyle(
                color: AppTheme.black,
                fontWeight: FontWeight.bold,
              ),
              recognizer: TapGestureRecognizer()..onTap = () {},
            ),
            const TextSpan(text: ' e '),
            TextSpan(
              text: 'Condizioni d\'uso',
              style: const TextStyle(
                color: AppTheme.black,
                fontWeight: FontWeight.bold,
              ),
              recognizer: TapGestureRecognizer()..onTap = () {},
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
