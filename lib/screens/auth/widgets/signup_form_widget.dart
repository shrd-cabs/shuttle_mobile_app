// ===============================================================
// signup_form_widget.dart
// ---------------------------------------------------------------
// Signup Form Widget
//
// PURPOSE
// ---------------------------------------------------------------
// Displays:
//
// 1. Full Name
// 2. Email Address
// 3. Phone Number
// 4. Password
// 5. Create Account Button
//
// SIGNUP FLOW
// ---------------------------------------------------------------
// 1. Creates the user account
// 2. Logs the newly created user in
// 3. Saves the user session
// 4. Redirects to MainContentScreen
//
// NOTES
// ---------------------------------------------------------------
// - Uses AuthService
// - Saves session using StorageService
// - Matches the existing login flow
// ===============================================================

import 'package:flutter/material.dart';

import '../../main/main_content_screen.dart';
import '../../../services/auth_service.dart';
import '../../../services/storage_service.dart';

class SignupFormWidget extends StatefulWidget {
  const SignupFormWidget({super.key});

  @override
  State<SignupFormWidget> createState() => _SignupFormWidgetState();
}

class _SignupFormWidgetState extends State<SignupFormWidget> {
  // ===========================================================
  // Controllers
  // ===========================================================

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  // ===========================================================
  // Services
  // ===========================================================

  final authService = AuthService();
  final storageService = StorageService();

  // ===========================================================
  // State
  // ===========================================================

  bool isLoading = false;

  // ===========================================================
  // Signup
  // ===========================================================

  Future<void> signup() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();

    // ---------------------------------------------------------
    // Validate fields
    // ---------------------------------------------------------

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty) {
      showMessage('Fill all fields');
      return;
    }

    setState(() => isLoading = true);

    try {
      // -------------------------------------------------------
      // Create account
      // -------------------------------------------------------

      final signupResult = await authService.signup(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );

      if (!mounted) return;

      if (signupResult['success'] != true) {
        setState(() => isLoading = false);

        showMessage(
          signupResult['error'] ??
              signupResult['message'] ??
              'Signup failed',
        );

        return;
      }

      // -------------------------------------------------------
      // Login newly registered user
      //
      // This ensures that we receive the same user object used
      // by the normal login flow.
      // -------------------------------------------------------

      final loginResult = await authService.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (loginResult['success'] == true &&
          loginResult['user'] != null) {
        // -----------------------------------------------------
        // Save user session
        // -----------------------------------------------------

        final user = Map<String, dynamic>.from(
          loginResult['user'],
        );

        await storageService.saveCurrentUser(user);

        if (!mounted) return;

        setState(() => isLoading = false);

        showMessage(
          'Account created successfully. Welcome ${user['name'] ?? name}',
        );

        // -----------------------------------------------------
        // Replace AuthScreen with MainContentScreen
        //
        // pushReplacement prevents the back button from
        // returning to the authentication screen.
        // -----------------------------------------------------

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainContentScreen(),
          ),
        );

        return;
      }

      // -------------------------------------------------------
      // Account created but automatic login failed
      // -------------------------------------------------------

      setState(() => isLoading = false);

      showMessage(
        loginResult['error'] ??
            'Account created, but automatic login failed. Please login.',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => isLoading = false);

      showMessage(
        'Something went wrong. Please try again.',
      );
    }
  }

  // ===========================================================
  // Snackbar Helper
  // ===========================================================

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ===========================================================
  // Dispose Controllers
  // ===========================================================

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // ===========================================================
  // UI
  // ===========================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // =====================================================
        // Full Name
        // =====================================================

        TextField(
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          enabled: !isLoading,
          decoration: InputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your name',
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

        const SizedBox(height: 16),

        // =====================================================
        // Email Address
        // =====================================================

        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          enabled: !isLoading,
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

        const SizedBox(height: 16),

        // =====================================================
        // Phone Number
        // =====================================================

        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          enabled: !isLoading,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: 'Enter your phone',
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

        const SizedBox(height: 16),

        // =====================================================
        // Password
        // =====================================================

        TextField(
          controller: passwordController,
          obscureText: true,
          textInputAction: TextInputAction.done,
          enabled: !isLoading,
          onSubmitted: (_) {
            if (!isLoading) {
              signup();
            }
          },
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Create password',
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

        // =====================================================
        // Create Account Button
        // =====================================================

        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: isLoading ? null : signup,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff6B46C1),
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  const Color(0xff6B46C1).withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}