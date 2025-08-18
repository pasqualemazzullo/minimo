import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/datasources/remote/auth_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordObscured = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
      );

      if (mounted) {
        if (response.user != null) {
          // Registrazione avvenuta con successo
          _showSuccessDialog();
        } else {
          _showErrorSnackBar('Errore durante la registrazione');
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        _showErrorSnackBar(_getErrorMessage(error.message));
      }
    } catch (error) {
      if (mounted) {
        _showErrorSnackBar('Errore imprevisto: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(String error) {
    // Traduci gli errori comuni di Supabase in italiano
    if (error.contains('User already registered')) {
      return 'Hai già un account Minimo';
    } else if (error.contains('Invalid email')) {
      return 'Email non valida';
    } else if (error.contains('Password should be at least')) {
      return 'La password deve avere almeno 6 caratteri';
    } else if (error.contains('signup is disabled')) {
      return 'Registrazione temporaneamente disabilitata';
    }
    return error;
  }

  void _showErrorSnackBar(String message) {
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SimpleDialog(
        title: const Text(
          'Registrazione completata!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        backgroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.cardBorder),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        children: [
          const Text(
            'Il tuo account è stato creato con successo. Controlla la tua email per confermare l\'account.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.black,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Chiudi dialog
                  Navigator.of(context).pop(); // Torna alla schermata di login
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(
                    fontFamily: AppConstants.fontFamily,
                    fontSize: 14,
                  ),
                ),
                child: const Text('OK'),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
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
                      children: [
                        const Text(
                          'Partiamo da qui!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.black,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Crea il tuo account Minimo per iniziare',
                          style: TextStyle(fontSize: 14, color: AppTheme.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        TextFormField(
                          controller: _nameController,
                          cursorColor: AppTheme.primaryColor,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            labelText: 'Nome completo *',
                            labelStyle: TextStyle(
                              color: AppTheme.unselectedText,
                              fontSize: 14,
                            ),
                            floatingLabelStyle: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: AppTheme.grey50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppTheme.cardBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppTheme.cardBorder,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppTheme.cardBorder,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nome completo obbligatorio';
                            } else if (value.trim().length < 2) {
                              return 'Il nome deve avere almeno 2 caratteri';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _emailController,
                          cursorColor: AppTheme.primaryColor,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            labelText: 'Email *',
                            labelStyle: TextStyle(
                              color: AppTheme.unselectedText,
                              fontSize: 14,
                            ),
                            floatingLabelStyle: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: AppTheme.grey50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppTheme.cardBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppTheme.cardBorder,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppTheme.cardBorder,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email obbligatoria';
                            } else if (!RegExp(
                              r'^[^@]+@[^@]+\.[^@]+',
                            ).hasMatch(value)) {
                              return 'Email non valida';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _passwordController,
                          cursorColor: AppTheme.primaryColor,
                          obscureText: _isPasswordObscured,
                          keyboardType: TextInputType.visiblePassword,
                          textInputAction: TextInputAction.done,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            labelText: 'Password *',
                            labelStyle: TextStyle(
                              color: AppTheme.unselectedText,
                              fontSize: 14,
                            ),
                            floatingLabelStyle: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: AppTheme.grey50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppTheme.cardBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppTheme.cardBorder,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppTheme.cardBorder,
                                width: 2,
                              ),
                            ),
                            suffixIcon: IconButton(
                              onPressed:
                                  _isLoading
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
                                    _isLoading
                                        ? AppTheme.grey
                                        : AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password obbligatoria';
                            } else if (value.length < 8) {
                              return 'La password deve avere almeno 8 caratteri';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 35),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignUp,
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
                              _isLoading
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
                                  : const Text(
                                    'Registrati',
                                    style: TextStyle(
                                      color: AppTheme.white,
                                      fontFamily: AppConstants.fontFamily,
                                      fontSize: 14,
                                    ),
                                  ),
                        ),
                        const SizedBox(height: 20),
                        RichText(
                          text: TextSpan(
                            text: 'Hai già un account? ',
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: AppConstants.fontFamily,
                              color: AppTheme.grey,
                            ),
                            children: [
                              TextSpan(
                                text: 'Accedi',
                                recognizer:
                                    TapGestureRecognizer()
                                      ..onTap =
                                          _isLoading
                                              ? null
                                              : () {
                                                Navigator.pop(context);
                                              },
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _isLoading
                                          ? AppTheme.grey
                                          : AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  children: const [
                    Divider(color: AppTheme.unselectedText),
                    SizedBox(height: 10),
                    _AgreeTermsTextCard(),
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

// --- Componenti riutilizzabili ---

class _AgreeTermsTextCard extends StatelessWidget {
  const _AgreeTermsTextCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: RichText(
        text: TextSpan(
          text: 'Registrandoti accetti i nostri ',
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
