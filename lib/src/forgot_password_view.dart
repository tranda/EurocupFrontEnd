import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  static const routeName = '/forgot-password';

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  bool busy = false;
  bool emailSent = false;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(title: 'Reset Password'),
      body: Container(
        decoration: naslovnaDecoration(),
        child: SizedBox(
          child: Form(
            key: _formKey,
            child: busy
                ? busyOverlay(context)
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo or title section
                        Container(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.lock_reset,
                                size: 80,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                emailSent ? 'Check Your Email' : 'Forgot Password?',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                emailSent
                                    ? 'We\'ve sent a password reset link to your email address.'
                                    : 'Enter your email address and we\'ll send you a link to reset your password.',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        if (!emailSent) ...[
                          // Email input field
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: buildStandardInputDecoration("Email Address"),
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.black87,
                              ),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleForgotPassword(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email address';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                          ),

                          // Error message
                          if (errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  border: Border.all(color: Colors.red.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.red.shade600),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        errorMessage!,
                                        style: TextStyle(color: Colors.red.shade700),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 24),

                          // Send Reset Link button
                          ElevatedButton(
                            onPressed: _handleForgotPassword,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Send Reset Link',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ] else ...[
                          // Success state
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              border: Border.all(color: Colors.green.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: Colors.green.shade600),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Reset link sent successfully! Check your email and follow the instructions to reset your password.',
                                    style: TextStyle(color: Colors.green.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Send another email button
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                emailSent = false;
                                errorMessage = null;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Send Another Email',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Back to login button
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Back to Login',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              decoration: TextDecoration.underline,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _handleForgotPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      busy = true;
      errorMessage = null;
    });

    try {
      final response = await api.sendForgotPasswordRequest(emailController.text.trim());

      setState(() {
        busy = false;
      });

      if (response['success']) {
        setState(() {
          emailSent = true;
        });
      } else {
        setState(() {
          errorMessage = _getErrorMessage(response);
        });
      }
    } catch (e) {
      setState(() {
        busy = false;
        errorMessage = 'Network error. Please check your internet connection and try again.';
      });
    }
  }

  String _getErrorMessage(Map<String, dynamic> response) {
    if (response['data'] != null && response['data']['message'] != null) {
      return response['data']['message'];
    }

    switch (response['statusCode']) {
      case 422:
        return 'Please enter a valid email address that is registered with us.';
      case 404:
        return 'No account found with this email address.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}