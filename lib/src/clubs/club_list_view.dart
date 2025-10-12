import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

import 'club_detail_page.dart';

class ClubListView extends StatefulWidget {
  const ClubListView({super.key});

  static const routeName = '/club_list';

  @override
  State<ClubListView> createState() => ListViewState();
}

class ListViewState extends State<ClubListView> {
  late Future<List<Club>> dataFuture;

  @override
  void initState() {
    super.initState();
    // Show all clubs for admins, only active for others
    dataFuture = api.getClubs(activeOnly: currentUser.accessLevel != null && currentUser.accessLevel! >= 2 ? false : true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: FutureBuilder(
            future: dataFuture, // api.getClubs(1),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasData) {
                return Text('Club List (${snapshot.data!.length})');
              }
              return const Text('Club list');
            },
          ),
        ),
        actions: currentUser.accessLevel != null && currentUser.accessLevel! >= 2 ? [
          IconButton(
            onPressed: () {
              _showCreateClubDialog(context);
            },
            icon: const Icon(Icons.add),
          ),
        ] : [],
      ),
      body: Container(
        decoration: bckDecoration(),
        child: FutureBuilder(
          future: dataFuture, // api.getClubs(1),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData) {
              final clubs = snapshot.data!;
              // Sort clubs: active first, then inactive
              clubs.sort((a, b) {
                if (a.active == b.active) return 0;
                return (a.active ?? false) ? -1 : 1;
              });
              // Debug: clubs list
              return ListView.builder(
                itemCount: clubs.length,
                itemBuilder: (BuildContext context, int index) {
                  final isInactive = clubs[index].active == false;
                  return Opacity(
                    opacity: isInactive ? 0.5 : 1.0,
                    child: Column(
                      children: [
                        ListTile(
                            // tileColor: Colors.blue,
                            title: Row(
                            children: [
                              if (clubs[index].country != null)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Text(
                                    '${getCountryFlag(clubs[index].country)} ${getCountryCode(clubs[index].country)}',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  clubs[index].name!,
                                  style: Theme.of(context).textTheme.displaySmall,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                                context, ClubDetailPage.routeName,
                                arguments: {
                                  'clubId': clubs[index].id,
                                }).then((value) {
                              setState(() {});
                            });
                          },
                          trailing: const Icon(Icons.arrow_forward)),
                      const Divider(
                        height: 4,
                      ),
                      const Divider(
                        height: smallSpace,
                      )
                    ],
                  ),
                );
              },
            );
          }
          return (const Text('No data'));
        },
      ),
    ),
  );
  }

  void _showCreateClubDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final countryController = TextEditingController();
    bool isActive = true;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create New Club'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: buildStandardInputDecorationWithLabel('Club Name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a club name';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: countryController,
                        decoration: buildStandardInputDecorationWithLabel('Country'),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Active'),
                        value: isActive,
                        onChanged: (bool value) {
                          setState(() {
                            isActive = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        await api.createClub(
                          nameController.text,
                          countryController.text,
                          isActive,
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          // Refresh the list
                          this.setState(() {
                            dataFuture = api.getClubs(activeOnly: currentUser.accessLevel != null && currentUser.accessLevel! >= 2 ? false : true);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Club created successfully')),
                          );
                        }
                      } catch (e) {
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(content: Text('Failed to create club: $e')),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
