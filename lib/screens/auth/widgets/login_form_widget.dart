// ===============================================================
// login_form_widget.dart
// ---------------------------------------------------------------
// Login Form Widget
//
// PURPOSE
// ---------------------------------------------------------------
// Displays email, password, login button and forgot password.
//
// NOTES
// ---------------------------------------------------------------
// - Uses AuthService
// - Saves session using StorageService
// - Navigates to MainContentScreen after successful login
// ===============================================================

import 'package:flutter/material.dart';

import '../../main/main_content_screen.dart';
import '../../../services/auth_service.dart';
import '../../../services/storage_service.dart';

class LoginFormWidget extends StatefulWidget {
  const LoginFormWidget({super.key});

  @override
  State<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends State<LoginFormWidget> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final authService = AuthService();
  final storageService = StorageService();

  bool isLoading = false;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage('Enter email and password');
      return;
    }

    setState(() => isLoading = true);

    final result = await authService.login(
      email: email,
      password: password,
    );

    if (!mounted) return;

    setState(() => isLoading = false);

    if (result['success'] == true && result['user'] != null) {
      await storageService.saveCurrentUser(
        Map<String, dynamic>.from(result['user']),
      );

      showMessage('Welcome ${result['user']['name']}');

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainContentScreen(),
        ),
      );
    } else {
      showMessage(result['error'] ?? 'Invalid email or password');
    }
  }

  Future<void> forgotPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      showMessage('Please enter your email first');
      return;
    }

    setState(() => isLoading = true);

    final result = await authService.forgotPassword(email);

    if (!mounted) return;

    setState(() => isLoading = false);

    if (result['success'] == true) {
      showMessage('Password sent to registered email');
    } else {
      showMessage(result['error'] ?? 'Something went wrong');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email Address',
            hintText: 'Enter your email',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Enter password',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: isLoading ? null : login,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff6B46C1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: forgotPassword,
          child: const Text(
            'Forgot Password?',
            style: TextStyle(
              color: Color(0xff6B46C1),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}