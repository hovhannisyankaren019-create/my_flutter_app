import 'package:flutter/material.dart';

import 'firebase_auth_service.dart';
import '../spiritual_ai/spiritual_ai_screen.dart';
import 'firestore_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

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

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SpiritualAiScreen(),
        ),
      );
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

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SpiritualAiScreen(),
        ),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Մուտք' : 'Գրանցում'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 70,
              ),
              const SizedBox(height: 20),
              Text(
                'Հոգևոր ԱԲ',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                cursorColor: Theme.of(context).colorScheme.primary,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                cursorColor: Theme.of(context).colorScheme.primary,
                decoration: InputDecoration(
                  labelText: 'Գաղտնաբառ',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(),
                        )
                      : Text(
                          _isLogin ? 'Մուտք' : 'Գրանցվել',
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: const Icon(Icons.login),
                  label: const Text(
                    'Մուտք Google-ով',
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
                      ? 'Դեռ հաշիվ չունե՞ս։ Գրանցվել'
                      : 'Արդեն հաշիվ ունե՞ս։ Մուտք գործել',
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SpiritualAiScreen(
                        isGuest: true,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.person_outline),
                label: const Text('Մտնել որպես հյուր'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
