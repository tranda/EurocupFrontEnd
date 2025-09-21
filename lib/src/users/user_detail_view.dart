import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';

import 'package:eurocup_frontend/src/common.dart';

import '../model/user.dart';
import '../model/club/club.dart';
import '../model/event/event.dart';

class UserDetailView extends StatefulWidget {
  final User? user;
  UserDetailView({super.key, this.user});
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
  late User user;
  String mode = 'r';
  bool newUser = false;
  bool _isInitialized = false;
  List<Club> _clubs = [];
  List<Competition> _events = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    // Initialize user object
    user = User();

    // Use cached data immediately if available
    if (clubs.isNotEmpty || competitions.isNotEmpty) {
      _clubs = List.from(clubs);
      _events = List.from(competitions);
      _isLoadingData = false;
    }

    // Still fetch fresh data in case clubs were added/modified
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    try {
      // Fetch fresh data
      final freshClubs = await api.getClubs();
      final freshEvents = await api.getCompetitions();

      if (mounted) {
        setState(() {
          _clubs = freshClubs;
          _events = freshEvents;
          clubs = freshClubs; // Update global cache
          competitions = freshEvents; // Update global cache
          _isLoadingData = false;

          // Update controllers with display text once data is loaded
          if (!editable) {
            clubController.text = _getClubDisplayText();
            eventController.text = _getEventDisplayText();
            accessLevelController.text = _getAccessLevelDisplayText();
          }
        });
      }
    } catch (e) {
      print('Error loading dropdown data: $e');
      // If fetch fails but we have cached data, use it
      if (mounted && (_clubs.isEmpty || _events.isEmpty)) {
        setState(() {
          if (_clubs.isEmpty && clubs.isNotEmpty) _clubs = List.from(clubs);
          if (_events.isEmpty && competitions.isNotEmpty) _events = List.from(competitions);
          _isLoadingData = false;

          if (!editable) {
            clubController.text = _clubs.isNotEmpty ? _getClubDisplayText() : 'Error loading clubs';
            eventController.text = _events.isNotEmpty ? _getEventDisplayText() : 'Error loading events';
            accessLevelController.text = _getAccessLevelDisplayText();
          }
        });
      }
    }
  }

  // Build dropdown items for clubs
  List<DropdownMenuItem<int>> _buildClubDropdownItems() {
    final items = <DropdownMenuItem<int>>[
      const DropdownMenuItem(value: 0, child: Text('No club')),
    ];

    // Add clubs from API
    for (var club in _clubs) {
      if (club.id != null) {
        items.add(DropdownMenuItem(
          value: club.id!,
          child: Text(club.name ?? 'Club ${club.id}'),
        ));
      }
    }

    return items;
  }

  // Get valid club value for dropdown
  int? _getValidClubValue() {
    if (user.clubId == null || user.clubId == 0) return 0;

    // Check if the club exists in the fetched list
    if (_clubs.any((club) => club.id == user.clubId)) {
      return user.clubId;
    }

    // Club doesn't exist, return null to show hint
    return null;
  }

  // Build dropdown items for events
  List<DropdownMenuItem<int>> _buildEventDropdownItems() {
    final items = <DropdownMenuItem<int>>[
      const DropdownMenuItem(value: 0, child: Text('No event')),
    ];

    // Add events from API
    for (var event in _events) {
      if (event.id != null) {
        items.add(DropdownMenuItem(
          value: event.id!,
          child: Text(event.getShortName()),
        ));
      }
    }

    return items;
  }

  // Get valid event value for dropdown
  int? _getValidEventValue() {
    if (user.eventId == null || user.eventId == 0) return 0;

    // Check if the event exists in the fetched list
    if (_events.any((event) => event.id == user.eventId)) {
      return user.eventId;
    }

    // Event doesn't exist, return null to show hint
    return null;
  }

  // Get display text for club
  String _getClubDisplayText() {
    if (user.clubId == null || user.clubId == 0) return 'No club';

    final club = _clubs.firstWhere(
      (c) => c.id == user.clubId,
      orElse: () => Club(id: user.clubId, name: 'Unknown Club (ID: ${user.clubId})'),
    );

    return club.name ?? 'Club ${user.clubId}';
  }

  // Get display text for event
  String _getEventDisplayText() {
    if (user.eventId == null || user.eventId == 0) return 'No event';

    final event = _events.firstWhere(
      (e) => e.id == user.eventId,
      orElse: () => Competition(id: user.eventId, name: 'Unknown Event', year: null, location: null),
    );

    return event.getShortName();
  }

  // Get display text for access level
  String _getAccessLevelDisplayText() {
    switch (user.accessLevel) {
      case -1:
        return 'N/A';
      case 0:
        return 'Club Manager';
      case 1:
        return 'Judge';
      case 2:
        return 'Event Manager';
      case 3:
        return 'Administrator';
      default:
        return 'Unknown (${user.accessLevel})';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      // First try to get user from widget property, then from route arguments
      User? args = widget.user;
      if (args == null) {
        args = ModalRoute.of(context)!.settings.arguments as User?;
      }

      print('UserDetailView: didChangeDependencies called');
      print('UserDetailView: Widget user: ${widget.user}');
      print('UserDetailView: Arguments from route: ${ModalRoute.of(context)!.settings.arguments}');
      print('UserDetailView: Final args: $args');

      if (args != null) {
        user = args;
        newUser = false;
        mode = 'r';
        print('UserDetailView: Loaded existing user:');
        print('  - ID: ${user.id}');
        print('  - Name: ${user.name}');
        print('  - Username: ${user.username}');
        print('  - Email: ${user.email}');
        print('  - Access Level: ${user.accessLevel}');
        print('  - Club ID: ${user.clubId}');
        print('  - Event ID: ${user.eventId}');
      } else {
        user = User();
        newUser = true;
        mode = 'm';
        print('UserDetailView: Creating new user');
      }

      // Initialize controllers with user data
      setState(() {
        nameController.text = user.name ?? '';
        usernameController.text = user.username ?? '';
        eMailController.text = user.email ?? '';

        // Wait for data to load before setting display text
        if (_isLoadingData) {
          clubController.text = 'Loading...';
          eventController.text = 'Loading...';
          accessLevelController.text = 'Loading...';
        } else {
          clubController.text = _getClubDisplayText();
          eventController.text = _getEventDisplayText();
          accessLevelController.text = _getAccessLevelDisplayText();
        }
      });

      print('UserDetailView: Controllers initialized:');
      print('  - nameController: "${nameController.text}"');
      print('  - usernameController: "${usernameController.text}"');
      print('  - emailController: "${eMailController.text}"');
      print('  - clubController: "${clubController.text}"');
      print('  - mode: $mode');
      print('  - newUser: $newUser');
      print('  - editable: $editable');

      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    eMailController.dispose();
    clubController.dispose();
    eventController.dispose();
    accessLevelController.dispose();
    passwordController.dispose();
    passwordConfirmedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case 'r':
        editable = false;
        break;
      case 'm':
        editable = true;
        break;
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(user.name ?? "New User"),
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
        body: Container(
          decoration: bckDecoration(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextFormField(
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
                      : DropdownButtonFormField<int>(
                          isExpanded: true,
                          hint: Text(
                            user.clubId != null && user.clubId != 0 && !_clubs.any((c) => c.id == user.clubId)
                                ? 'Invalid ID: ${user.clubId}'
                                : 'Select Club',
                            overflow: TextOverflow.ellipsis,
                          ),
                          value: _isLoadingData ? null : _getValidClubValue(),
                          validator: (value) {
                            if (value == null) {
                              return 'Required - Please select a valid club';
                            }
                            return null;
                          },
                          items: _isLoadingData ? [] : _buildClubDropdownItems(),
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
                      : DropdownButtonFormField<int>(
                          isExpanded: true,
                          hint: Text(
                            user.eventId != null && user.eventId != 0 && !_events.any((e) => e.id == user.eventId)
                                ? 'Invalid ID: ${user.eventId}'
                                : 'Select Event',
                            overflow: TextOverflow.ellipsis,
                          ),
                          value: _isLoadingData ? null : _getValidEventValue(),
                          validator: (value) {
                            if (value == null) {
                              return 'Required - Please select a valid event';
                            }
                            return null;
                          },
                          items: _isLoadingData ? [] : _buildEventDropdownItems(),
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
                          value: user.accessLevel ?? -1,
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
                heroTag: "saveUserBtn",
                backgroundColor: Colors.blue,
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // Show loading indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    final updatedUser = await api.updateUser(user);

                    // Close loading indicator
                    Navigator.pop(context);

                    if (updatedUser != null) {
                      setState(() {
                        user = updatedUser;
                        nameController.text = updatedUser.name ?? '';
                        usernameController.text = updatedUser.username ?? '';
                        eMailController.text = updatedUser.email ?? '';
                        mode = 'r';
                      });

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('User updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to update user'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Icon(Icons.save),
              ),
              FloatingActionButton(
                heroTag: "deleteUserBtn",
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
                  // Debug: delete action
                },
                child: const Icon(Icons.delete),
              ),
            ],
          ),
        ));
  }
}
