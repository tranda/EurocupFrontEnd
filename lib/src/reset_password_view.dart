import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  static const routeName = '/reset-password';

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool busy = false;
  bool passwordReset = false;
  String? errorMessage;
  String? token;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get the token from the route arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    print('Route arguments: $args');
    if (args != null && args['token'] != null) {
      token = args['token'];
      print('Token from args: $token');
    }

    // Also try to get token from query parameters (for web)
    final uri = Uri.base;
    print('Current URI: $uri');
    print('Query parameters: ${uri.queryParameters}');
    if (uri.queryParameters.containsKey('token')) {
      token = uri.queryParameters['token'];
      print('Token from query params: $token');
    }

    print('Final token: $token');
  }

  @override
  Widget build(BuildContext context) {
    // If no token is provided, show an error
    if (token == null || token!.isEmpty) {
      return Scaffold(
        appBar: appBar(title: 'Reset Password'),
        body: Container(
          decoration: naslovnaDecoration(),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red.shade600,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Invalid Reset Link',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This password reset link is invalid or has expired. Please request a new one.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/forgot-password');
                    },
                    child: const Text('Request New Link'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
                                passwordReset ? Icons.check_circle : Icons.lock_reset,
                                size: 80,
                                color: passwordReset ? Colors.green : Theme.of(context).primaryColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                passwordReset ? 'Password Reset Successfully!' : 'Create New Password',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (!passwordReset) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Enter your new password below.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),

                        if (!passwordReset) ...[
                          // Email input field
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: buildStandardInputDecoration("Email Address"),
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black87),
                              textInputAction: TextInputAction.next,
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

                          // New password input field
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: TextFormField(
                              controller: passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'New Password',
                                hintText: 'Enter your new password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black87),
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a new password';
                                }
                                if (value.length < 8) {
                                  return 'Password must be at least 8 characters long';
                                }
                                return null;
                              },
                            ),
                          ),

                          // Confirm password input field
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: TextFormField(
                              controller: confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: 'Confirm New Password',
                                hintText: 'Re-enter your new password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ),
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black87),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleResetPassword(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your new password';
                                }
                                if (value != passwordController.text) {
                                  return 'Passwords do not match';
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

                          // Reset Password button
                          ElevatedButton(
                            onPressed: _handleResetPassword,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Reset Password',
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
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.check_circle_outline, color: Colors.green.shade600),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Your password has been reset successfully!',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'You can now use your new password to log in to your account.',
                                  style: TextStyle(color: Colors.green.shade700),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Go to login button
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/login',
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Go to Login',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      busy = true;
      errorMessage = null;
    });

    try {
      final response = await api.sendResetPasswordRequest(
        email: emailController.text.trim(),
        token: token!,
        password: passwordController.text,
        passwordConfirmation: confirmPasswordController.text,
      );

      setState(() {
        busy = false;
      });

      if (response['success']) {
        setState(() {
          passwordReset = true;
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
      case 400:
        return 'Invalid or expired reset token. Please request a new password reset.';
      case 422:
        return 'Please check your input and try again.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}