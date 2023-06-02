import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';

import 'common.dart';
import 'home_page_view.dart';
import 'api_helper.dart' as api;

class LoginView extends StatelessWidget {
  LoginView({super.key});

  static const routeName = '/login';

  final _formKey = GlobalKey<FormState>();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    usernameController.text = 'marko@gmail.com';
    passwordController.text = '12345678';
    return Scaffold(
      appBar: appBar(title: 'Log In'),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Card(
            child: Form(
              key: _formKey,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: bigSpace),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 16),
                      child: TextFormField(
                        controller: usernameController,
                        decoration: buildStandardInputDecoration("Username"),
                        style: Theme.of(context).textTheme.bodyText1,
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
                        decoration: buildPasswordInputDecoration("Password"),
                        style: Theme.of(context).textTheme.bodyText1,
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
                          horizontal: horizontalPadding, vertical: verticalPadding),
                      child: Center(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              api
                                  .sendLoginRequest(usernameController.text,
                                      passwordController.text)
                                  .then((value) => {
                                        if (value)
                                          {
                                            Navigator.restorablePushNamed(
                                                context, HomePage.routeName)
                                          }
                                        else
                                          {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'Incorrect username or password')),
                                            )
                                          }
                                      });
                            }
                          },
                          child: const Text('LOG IN'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
