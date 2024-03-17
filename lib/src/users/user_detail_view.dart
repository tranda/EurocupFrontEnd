import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';

import 'package:eurocup_frontend/src/common.dart';

import '../model/user.dart';

class UserDetailView extends StatefulWidget {
  const UserDetailView({super.key});
  static const routeName = '/user';

  @override
  State<UserDetailView> createState() => _UserDetailViewState();
}

class _UserDetailViewState extends State<UserDetailView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController eMailController = TextEditingController();
  final TextEditingController clubController = TextEditingController();
  final TextEditingController eventController = TextEditingController();
  final TextEditingController accessLevelController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmedController =
      TextEditingController();

  bool editable = false;
  User user = User();
  String mode = 'r';
  bool newUser = false;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as User?;
    if (args != null) {
      user = args;
    } else {
      newUser = true;
      mode = 'm';
    }
    switch (mode) {
      case 'r':
        editable = false;
        break;
      case 'm':
        editable = true;
        break;
    }

    nameController.text = user.name ?? '';
    usernameController.text = user.username ?? '';
    eMailController.text = user.email ?? '';
    clubController.text = '${user.clubId}';
    eventController.text = '${user.eventId}';
    accessLevelController.text = '${user.accessLevel}';

    return Scaffold(
        appBar: AppBar(
          title: Text(user.name ?? ""),
          actions: [
            Visibility(
              visible: !editable,
              child: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    mode = 'm';
                  });
                },
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Container(
            decoration: bckDecoration(),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                    decoration:
                        buildStandardInputDecorationWithLabel('Full Name'),
                    controller: nameController,
                    enabled: editable,
                    style: Theme.of(context).textTheme.displaySmall,
                    onChanged: (value) {
                      user.name = value;
                    },
                  ),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                    decoration:
                        buildStandardInputDecorationWithLabel('Username'),
                    controller: usernameController,
                    enabled: editable && newUser,
                    style: Theme.of(context).textTheme.displaySmall,
                    onChanged: (value) {
                      user.username = value;
                    },
                  ),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                    decoration: buildStandardInputDecorationWithLabel('email'),
                    controller: eMailController,
                    enabled: newUser,
                    style: Theme.of(context).textTheme.displaySmall,
                    onChanged: (value) {
                      user.email = value;
                    },
                  ),
                  Visibility(
                    visible: newUser,
                    child: TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                      decoration: buildPasswordInputDecoration('Password'),
                      controller: passwordController,
                      enabled: editable && newUser,
                      style: Theme.of(context).textTheme.displaySmall,
                      onChanged: (value) {
                        user.password = value;
                      },
                    ),
                  ),
                  Visibility(
                    visible: newUser,
                    child: TextFormField(
                      validator: (value) {
                        if (value != passwordController.text) {
                          return 'Must be the same as Password';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                      decoration:
                          buildPasswordInputDecoration('Password Confirmation'),
                      controller: passwordConfirmedController,
                      enabled: editable && newUser,
                      style: Theme.of(context).textTheme.displaySmall,
                      onChanged: (value) {
                        user.password_confirmation = value;
                      },
                    ),
                  ),
                  (!editable)
                      ? TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required!';
                            }
                            return null;
                          },
                          decoration:
                              buildStandardInputDecorationWithLabel('Club'),
                          controller: clubController,
                          enabled: false,
                          style: Theme.of(context).textTheme.displaySmall,
                        )
                      : DropdownButtonFormField(
                          hint: const Text('Select Club'),
                          value: user.clubId,
                          validator: (value) {
                            if (value == null) {
                              return 'Required';
                            }
                            return null;
                          },
                          items: const [
                            DropdownMenuItem(value: 0, child: Text('No club')),
                            DropdownMenuItem(value: 1, child: Text('Motion')),
                            DropdownMenuItem(
                                value: 2,
                                child: Text('Wraysbury Dragons & Waka Ama')),
                            DropdownMenuItem(
                                value: 3,
                                child: Text('Haifa Lions Sea Sports Club')),
                            DropdownMenuItem(
                                value: 4, child: Text('Gladiators Abu Dhabi')),
                            DropdownMenuItem(
                                value: 5, child: Text('Britannia UK')),
                            DropdownMenuItem(
                                value: 6,
                                child: Text('Clubul West Sport Arad')),
                            DropdownMenuItem(
                                value: 7,
                                child: Text('Nautic Banat Timisoara')),
                            DropdownMenuItem(
                                value: 9, child: Text('Beodragons')),
                            DropdownMenuItem(
                                value: 11,
                                child: Text('HSB Marİne Dragon Team')),
                            DropdownMenuItem(
                                value: 12, child: Text('Wraysbury/Britannia')),
                            DropdownMenuItem(
                                value: 13, child: Text('Long sprint')),
                            DropdownMenuItem(
                                value: 14, child: Text('Adski zmajevi')),
                            DropdownMenuItem(value: 15, child: Text('Vulturi')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              user.clubId = value;
                            });
                          },
                          style: Theme.of(context).textTheme.displaySmall,
                          padding:
                              const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                        ),
                  (!editable)
                      ? TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required!';
                            }
                            return null;
                          },
                          decoration:
                              buildStandardInputDecorationWithLabel('Event'),
                          controller: eventController,
                          enabled: false,
                          style: Theme.of(context).textTheme.displaySmall,
                        )
                      : DropdownButtonFormField(
                          hint: const Text('Select Event'),
                          value: user.eventId,
                          validator: (value) {
                            if (value == null) {
                              return 'Required';
                            }
                            return null;
                          },
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Eurocup')),
                            DropdownMenuItem(value: 2, child: Text('Festival'))
                          ],
                          onChanged: (value) {
                            setState(() {
                              user.eventId = value;
                            });
                          },
                          style: Theme.of(context).textTheme.displaySmall,
                          padding:
                              const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                        ),
                  (!editable)
                      ? TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required!';
                            }
                            return null;
                          },
                          decoration: buildStandardInputDecorationWithLabel(
                              'Access level'),
                          controller: accessLevelController,
                          enabled: false,
                          style: Theme.of(context).textTheme.displaySmall,
                        )
                      : DropdownButtonFormField(
                          hint: const Text('Select Access level'),
                          value: user.accessLevel,
                          validator: (value) {
                            if (value == null) {
                              return 'Required';
                            }
                            return null;
                          },
                          items: const [
                            DropdownMenuItem(
                                value: -1, child: Text('N/A')),
                            DropdownMenuItem(
                                value: 0, child: Text('Club Manager')),
                            DropdownMenuItem(value: 1, child: Text('Judge')),
                            DropdownMenuItem(
                                value: 2, child: Text('Event Manager')),
                            DropdownMenuItem(
                                value: 3, child: Text('Administrator'))
                          ],
                          onChanged: (value) {
                            setState(() {
                              user.accessLevel = value;
                            });
                          },
                          style: Theme.of(context).textTheme.displaySmall,
                          padding:
                              const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                        ),
                  const SizedBox(
                    height: bigSpace,
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Visibility(
          visible: editable,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              FloatingActionButton(
                backgroundColor: Colors.blue,
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      mode = 'r';
                      api.updateUser(user).then((value) => Navigator.pop(
                            context,
                          ));
                    });
                  }
                },
                child: const Icon(Icons.save),
              ),
              FloatingActionButton(
                backgroundColor: Colors.red,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Really??'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () {
                                api.deleteUser(user).then((value) {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                });
                              },
                              child: const Text('Delete')),
                        ],
                      );
                    },
                  );
                  print('delete');
                },
                child: const Icon(Icons.delete),
              ),
            ],
          ),
        ));
  }
}
