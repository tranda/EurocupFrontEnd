import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'common.dart';
import 'home_page_view.dart';
import 'api_helper.dart' as api;

const _storage = FlutterSecureStorage();
Future readToken() async {
  token = await _storage.read(key: 'TOKEN') ?? "";
}

Future saveToken(token) async {
  await _storage.write(key: 'TOKEN', value: token);
}

Future clearToken() async {
  await _storage.delete(key: 'TOKEN');
  token = '';
}

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
  var startUser = "";
  var startPassword = "";
  bool busy = false;

  @override
  void initState() {
    readToken();
    super.initState();

    if (kDebugMode) {
      // Code specific to debug mode
      print('Running in debug mode');
      startUser = ADMINTEST ? adminUser : (TEST ? testUser : "");
      startPassword = ADMINTEST ? adminPassword : (TEST ? testPassword : "");
    } else {
      // Code specific to release mode
      print('Running in release mode');
      startUser = "";
      startPassword = "";
    }

    if (token != '') {
      Navigator.pushNamed(context, HomePage.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    usernameController.text = startUser;
    passwordController.text = startPassword;
    return Scaffold(
      appBar: appBar(title: 'Events Platform'),
      body: Container(
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/images/naslovna-bck.jpg'),
                fit: BoxFit.cover)),
        child: SizedBox(
          // width: 640,
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: TextFormField(
                      controller: usernameController,
                      decoration: buildStandardInputDecoration("Username"),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: buildPasswordInputDecoration("Password"),
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
                      child: Visibility(
                        visible: !busy,
                        child: ElevatedButton(
                          onPressed: () {
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
                                      context, HomePage.routeName);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
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
