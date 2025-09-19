import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'common.dart';
import 'home_page_view.dart';
import 'races/race_results_list_view.dart';
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
  
  // Event selection for public race results
  String selectedEventId = "1";
  List<Map<String, String>> get availableEvents {
    if (competitions.isEmpty) {
      // Fallback to hardcoded events if API hasn't loaded yet
      return [
        {"id": "1", "name": "EuroCup 2023"},
        {"id": "8", "name": "National Championship 2025"},
      ];
    }
    
    return competitions.map((competition) => {
      "id": competition.id.toString(),
      "name": "${competition.name} ${competition.year}, ${competition.location}",
    }).toList();
  }
  
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
      // After competitions are loaded, update the UI and set default selection
      if (mounted) {
        setState(() {
          // Set default to EVENTID if it exists in competitions, otherwise first competition
          if (competitions.isNotEmpty) {
            final defaultCompetition = competitions.firstWhere(
              (comp) => comp.id == EVENTID,
              orElse: () => competitions.first,
            );
            selectedEventId = defaultCompetition.id.toString();
          }
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
                        // Public Race Results Section
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                              vertical: verticalPadding),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'View Public Race Results',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: availableEvents.any((event) => event['id'] == selectedEventId) 
                                          ? selectedEventId 
                                          : availableEvents.isNotEmpty ? availableEvents.first['id'] : "1",
                                      isExpanded: true,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                      ),
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.black54,
                                      ),
                                      items: availableEvents.map((event) {
                                        return DropdownMenuItem<String>(
                                          value: event['id'],
                                          child: Text(event['name']!),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            selectedEventId = newValue;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      RaceResultsListView.routeName,
                                      arguments: {
                                        'eventId': selectedEventId,
                                        'eventName': availableEvents.firstWhere(
                                          (event) => event['id'] == selectedEventId,
                                          orElse: () => {'name': 'Unknown Event'}
                                        )['name'],
                                      },
                                    );
                                  },
                                  icon: const Icon(Icons.bar_chart, size: 20),
                                  label: const Text('View Results'),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: const Color.fromARGB(255, 15, 91, 169),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ],
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
