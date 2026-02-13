import 'package:flutter/material.dart';
import '../../data/auth_service.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null && mounted) {
        widget.onLoginSuccess(); // Повідомляємо MainScreen про успіх
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle_outlined, size: 80, color: Color(0xFF2D5A40)),
            const SizedBox(height: 20),
            const Text(
              'Авторизація',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D5A40)),
            ),
            const SizedBox(height: 10),
            const Text(
              'Увійдіть, щоб синхронізувати розклад\nта бачити свій прогрес',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _handleSignIn,
                    icon: const Icon(Icons.login),
                    label: const Text('Увійти через @pnu.edu.ua'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}