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
import 'package:device_info_plus/device_info_plus.dart';

import '../../../services/fcm_service.dart';
import '../../../services/notification_service.dart';

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

    try {
      final result = await authService.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (result['success'] == true && result['user'] != null) {
        final user = Map<String, dynamic>.from(
          result['user'],
        );

        // Preserve the existing login session behavior.
        await storageService.saveCurrentUser(user);

        // FCM registration is non-blocking for the login flow.
        // Any failure here must not stop the user from entering the app.
        try {
          final token =
              await NotificationService.instance.getToken();

          if (token != null && token.trim().isNotEmpty) {
            final androidInfo =
                await DeviceInfoPlugin().androidInfo;

            final deviceName = [
              androidInfo.manufacturer.trim(),
              androidInfo.model.trim(),
            ].where((value) => value.isNotEmpty).join(' ');

            await FcmService().registerToken(
              email: (user['email'] ?? email)
                  .toString()
                  .trim(),
              phone: (user['phone'] ?? '')
                  .toString()
                  .trim(),
              token: token,
              deviceName: deviceName.isEmpty
                  ? 'Android Device'
                  : deviceName,
            );
          }
        } catch (error, stackTrace) {
          debugPrint(
            'FCM token registration failed: $error',
          );

          debugPrintStack(
            stackTrace: stackTrace,
          );
        }

        if (!mounted) return;

        showMessage(
          'Welcome ${user['name'] ?? ''}',
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const MainContentScreen(),
          ),
        );
      } else {
        showMessage(
          result['error'] ??
              'Invalid email or password',
        );
      }
    } catch (error) {
      if (!mounted) return;

      showMessage(
        'Unable to login. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
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