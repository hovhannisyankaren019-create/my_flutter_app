import 'package:flutter/material.dart';

import '../main.dart';
import '../spiritual_ai/spiritual_ai_screen.dart';
import 'firebase_auth_service.dart';
import 'firestore_service.dart';

class AuthScreen extends StatefulWidget {
  final bool embedded;
  final VoidCallback? onGuest;

  const AuthScreen({
    super.key,
    this.embedded = false,
    this.onGuest,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _authService = FirebaseAuthService();
  final _firestoreService = FirestoreService();

  bool _isLogin = true;
  bool _isLoading = false;

  InputDecoration _fieldDecoration({
    required bool isDark,
    required String label,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.muted(isDark)),
      filled: true,
      fillColor: isDark ? AppColors.darkForest : AppColors.lightChip,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? AppColors.olive : AppColors.forest,
          width: 1.4,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Future<void> _openAi({required bool guest}) async {
    if (guest && widget.embedded && widget.onGuest != null) {
      widget.onGuest!();
      return;
    }
    if (widget.embedded) {
      return;
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SpiritualAiScreen(isGuest: guest),
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Լրացրեք email-ը և գաղտնաբառը');
      return;
    }

    if (password.length < 6) {
      _showMessage('Գաղտնաբառը պետք է լինի առնվազն 6 նիշ');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        await _authService.login(
          email: email,
          password: password,
        );
      } else {
        final credential = await _authService.register(
          email: email,
          password: password,
        );

        final user = credential.user;

        if (user != null) {
          try {
            await _firestoreService.createUserDocument(user);
          } catch (_) {}
        }
      }

      if (!mounted) return;
      await _openAi(guest: false);
    } catch (e) {
      if (!mounted) return;

      String message = 'Սխալ տեղի ունեցավ';

      if (e.toString().contains('user-not-found')) {
        message = 'Այս email-ով օգտատեր գոյություն չունի';
      } else if (e.toString().contains('wrong-password') ||
          e.toString().contains('invalid-credential')) {
        message = 'Email-ը կամ գաղտնաբառը սխալ է';
      } else if (e.toString().contains('email-already-in-use')) {
        message = 'Այս email-ով արդեն հաշիվ կա';
      } else if (e.toString().contains('weak-password')) {
        message = 'Գաղտնաբառը շատ թույլ է';
      } else if (e.toString().contains('invalid-email')) {
        message = 'Email-ի ձևաչափը սխալ է';
      }

      _showMessage(message);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await _authService.loginWithGoogle();

      final user = credential.user;

      if (user != null) {
        try {
          await _firestoreService.createUserDocument(user);
        } catch (_) {}
      }

      if (!mounted) return;
      await _openAi(guest: false);
    } catch (e) {
      if (!mounted) return;

      final error = e.toString();
      if (error.contains('google-canceled')) {
        return;
      }
      if (error.contains('google-empty-token') ||
          error.contains('ApiException: 10') ||
          error.contains('DEVELOPER_ERROR') ||
          error.contains('10:')) {
        _showMessage(
          'Google հաշիվը ընտրվեց, բայց Firebase-ը չընդունեց։ SHA-1 ավելացրեք Console-ում։',
        );
        return;
      }
      if (error.contains('operation-not-allowed')) {
        _showMessage('Firebase-ում Google մուտքը միացված չէ։');
        return;
      }

      _showMessage('Google-ով մուտք գործել չհաջողվեց');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.bg(isDark),
        automaticallyImplyLeading: !widget.embedded,
        title: Text(
          _isLogin ? 'Մուտք' : 'Գրանցում',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppColors.text(isDark),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 48,
                color: isDark ? AppColors.olive : AppColors.forest,
              ),
              const SizedBox(height: 12),
              Text(
                'ԱԲ',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text(isDark),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin
                    ? 'Մուտք գործեք՝ զրույցները պահելու համար'
                    : 'Ստեղծեք հաշիվ՝ զրույցները պահելու համար',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.muted(isDark),
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: AppColors.text(isDark)),
                cursorColor: AppColors.forest,
                decoration: _fieldDecoration(isDark: isDark, label: 'Email'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: TextStyle(color: AppColors.text(isDark)),
                cursorColor: AppColors.forest,
                decoration: _fieldDecoration(
                  isDark: isDark,
                  label: 'Գաղտնաբառ',
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        isDark ? AppColors.darkForest : AppColors.forest,
                    foregroundColor: AppColors.cream,
                    disabledBackgroundColor: AppColors.olive,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.cream,
                          ),
                        )
                      : Text(
                          _isLogin ? 'Մուտք' : 'Գրանցվել',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text(isDark),
                    side: BorderSide(
                      color: AppColors.olive.withValues(alpha: 0.55),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: Icon(
                    Icons.login,
                    color: isDark ? AppColors.olive : AppColors.forest,
                  ),
                  label: const Text(
                    'Մուտք Google-ով',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _isLogin = !_isLogin;
                        });
                      },
                child: Text(
                  _isLogin
                      ? 'Դեռ հաշիվ չունե՞ս։ Գրանցվի՛ր'
                      : 'Արդեն հաշիվ ունե՞ս։ Մուտք գործել',
                  style: TextStyle(
                    color: isDark ? AppColors.olive : AppColors.forest,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => _openAi(guest: true),
                icon: Icon(
                  Icons.person_outline,
                  color: AppColors.muted(isDark),
                ),
                label: Text(
                  'Մտնել որպես հյուր',
                  style: TextStyle(color: AppColors.muted(isDark)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
