import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'common.dart';
import 'home_page_view.dart';
import 'forgot_password_view.dart';
import 'api_helper.dart' as api;

// const _storage = FlutterSecureStorage();
// Future ReadToken() async {
//   token = await _storage.read(key: 'TOKEN') ?? "";
// }

// Future SaveToken(token) async {
//   await _storage.write(key: 'TOKEN', value: token);
// }

// Future ClearToken() async {
//   await _storage.delete(key: 'TOKEN');
//   token = null;
// }

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  static const routeName = '/login';

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  var currentUser = lastUser ?? "";
  var currentPassword = lastPassword ?? "";
  bool busy = false;
  
  
  void _handleLogin() {
    lastUser = usernameController.text;
    lastPassword = passwordController.text;
    if (_formKey.currentState!.validate()) {
      setState(() {
        busy = true;
      });
      api
          .sendLoginRequest(usernameController.text,
              passwordController.text)
          .then((value) {
        if (value) {
          Navigator.pushNamed(
                  context, HomePage.routeName)
              .then((value) {
            setState(() {});
          });
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
                content: Text(
                    'Incorrect username or password')),
          );
        }
        setState(() {
          busy = false;
        });
      });
    }
  }

  @override
  void initState() {
    competitions = [];
    disciplines = [];
    api.getCompetitions().then((_) {
      // After competitions are loaded, update the UI
      if (mounted) {
        setState(() {
          // Competitions loaded - UI will update if needed
        });
      }
    });
    api.getDisciplinesAll(eventId: EVENTID);
    super.initState();

    currentUser = lastUser ?? "";
    currentPassword = lastPassword ?? "";

    if (kDebugMode) {
      // Code specific to debug mode
      print('Running in debug mode');
      // Only use test credentials if they are explicitly provided in environment
      if (ADMINTEST && adminUser.isNotEmpty && adminPassword.isNotEmpty) {
        currentUser = adminUser;
        currentPassword = adminPassword;
      } else if (TEST && testUser.isNotEmpty && testPassword.isNotEmpty) {
        currentUser = testUser;
        currentPassword = testPassword;
      }
      // Otherwise use saved credentials or empty
    } else {
      // Code specific to release mode
      print('Running in release mode');
      currentUser = lastUser ?? "";
      currentPassword = lastPassword ?? "";
    }
    usernameController.text = currentUser;
    passwordController.text = currentPassword;
  }

  @override
  Widget build(BuildContext context) {
    currentUser = lastUser ?? "";
    currentPassword = lastPassword ?? "";

    if (kDebugMode) {
      // Code specific to debug mode
      print('Running in debug mode');
      // Only use test credentials if they are explicitly provided in environment
      if (ADMINTEST && adminUser.isNotEmpty && adminPassword.isNotEmpty) {
        currentUser = adminUser;
        currentPassword = adminPassword;
      } else if (TEST && testUser.isNotEmpty && testPassword.isNotEmpty) {
        currentUser = testUser;
        currentPassword = testPassword;
      }
      // Otherwise use saved credentials or empty
    } else {
      // Code specific to release mode
      print('Running in release mode');
      currentUser = lastUser ?? "";
      currentPassword = lastPassword ?? "";
    }
    usernameController.text = currentUser;
    passwordController.text = currentPassword;
    return Scaffold(
      appBar: appBar(title: 'Events Platform'),
      body: Container(
        decoration: naslovnaDecoration(),
        child: SizedBox(
          child: Form(
            key: _formKey,
            child: busy
                ? busyOverlay(context)
                : Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 16),
                          child: TextFormField(
                            controller: usernameController,
                            decoration:
                                buildStandardInputDecoration("Username"),
                            style: Theme.of(context).textTheme.displaySmall,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your username';
                              }
                              return null;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 16),
                          child: TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            decoration:
                                buildPasswordInputDecoration("Password"),
                            style: Theme.of(context).textTheme.displaySmall,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                              vertical: verticalPadding),
                          child: Center(
                            child: ElevatedButton(
                              onPressed: _handleLogin,
                              child: const Text('LOG IN'),
                            ),
                          ),
                        ),
                        // Forgot Password link
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                              vertical: 8),
                          child: Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, ForgotPasswordView.routeName);
                              },
                              child: Text(
                                'Forgot Password?',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[500],
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: bigSpace,
                        ),
                        Visibility(
                          visible: false,
                          child: ListTile(
                            title: Text("Club registration form",
                                style: Theme.of(context).textTheme.displaySmall,
                                textAlign: TextAlign.center),
                            onTap: () {
                              launchUrlString(registrationFormURL);
                            },
                          ),
                        )
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
