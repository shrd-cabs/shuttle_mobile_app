// ===============================================================
// auth_screen.dart
// ---------------------------------------------------------------
// Authentication Screen
//
// PURPOSE
// ---------------------------------------------------------------
// Displays:
//
// 1. Application Header
// 2. Login Form
// 3. Signup Toggle
// 4. Signup Form
// 5. Application Footer
//
// NOTES
// ---------------------------------------------------------------
// - Login form is always visible
// - Signup form is collapsible
// - Authentication logic is handled by AuthService
// ===============================================================

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

import 'widgets/footer_widget.dart';
import 'widgets/header_widget.dart';
import 'widgets/login_form_widget.dart';
import 'widgets/signup_form_widget.dart';

class AuthScreen extends StatefulWidget {

  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();

}

class _AuthScreenState extends State<AuthScreen> {

  // ===========================================================
  // Controls Signup Form Visibility
  // ===========================================================

  bool showSignup = false;

  // ===========================================================
  // Toggle Signup Form
  // ===========================================================

  void toggleSignup() {

    setState(() {

      showSignup = !showSignup;

    });

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: AppConstants.backgroundColor,

      body: SafeArea(

        child: SingleChildScrollView(

          child: Column(

            children: [

              const HeaderWidget(),

              Padding(

                padding: const EdgeInsets.all(24),

                child: Column(

                  children: [

                    const SizedBox(height: 20),

                    const LoginFormWidget(),

                    const SizedBox(height: 16),

                    GestureDetector(

                      onTap: toggleSignup,

                      child: RichText(

                        text: TextSpan(

                          style: const TextStyle(

                            color: Colors.black,

                            fontSize: 16,

                          ),

                          children: [

                            const TextSpan(

                              text: "Don't have an account? ",

                            ),

                            TextSpan(

                              text: showSignup
                                  ? "Hide"
                                  : "Sign up here",

                              style: TextStyle(

                                color: AppConstants.primaryColor,

                                fontWeight: FontWeight.bold,

                              ),

                            ),

                          ],

                        ),

                      ),

                    ),

                    if (showSignup) ...[

                      const SizedBox(height: 30),

                      const SignupFormWidget(),

                    ],

                  ],

                ),

              ),

              const FooterWidget(),

            ],

          ),

        ),

      ),

    );

  }

}