import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'common.dart';
import 'home_page_view.dart';
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
  LoginView({super.key});

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

  @override
  void initState() {
    super.initState();

    currentUser = lastUser ?? "";
    currentPassword = lastPassword ?? "";

    if (kDebugMode) {
      // Code specific to debug mode
      print('Running in debug mode');
      currentUser = (ADMINTEST ? adminUser : (TEST ? testUser : currentUser));
      currentPassword =
          ADMINTEST ? adminPassword : (TEST ? testPassword : currentPassword);
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
      currentUser = (ADMINTEST ? adminUser : (TEST ? testUser : currentUser));
      currentPassword =
          ADMINTEST ? adminPassword : (TEST ? testPassword : currentPassword);
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
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/images/naslovna-bck.jpg'),
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter)),
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
                              onPressed: () {
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
                              },
                              child: const Text('LOG IN'),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: bigSpace,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
