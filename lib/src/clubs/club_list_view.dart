import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:eurocup_frontend/src/widgets/page_template.dart';
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
              // Sort clubs: active first, then alphabetically by name
              clubs.sort((a, b) {
                final aActive = a.active ?? false;
                final bActive = b.active ?? false;
                if (aActive != bActive) {
                  return aActive ? -1 : 1;
                }
                return (a.name ?? '')
                    .toLowerCase()
                    .compareTo((b.name ?? '').toLowerCase());
              });
              final activeClubs =
                  clubs.where((c) => c.active != false).toList();
              final inactiveClubs =
                  clubs.where((c) => c.active == false).toList();

              Widget clubRow(Club club, bool isInactive) {
                return Opacity(
                  opacity: isInactive ? 0.5 : 1.0,
                  child: PageListItem(
                    onTap: () {
                      // Persist for refresh recovery: clubId rides in the
                      // URL, plus localStorage fallback. Without this the
                      // page's args are lost on reload and it crashes grey.
                      saveSelectedClubId(club.id);
                      Navigator.pushNamed(
                          context,
                          '${ClubDetailPage.routeName}?clubId=${club.id}',
                          arguments: {
                            'clubId': club.id,
                          }).then((value) {
                        setState(() {
                          dataFuture = api.getClubs(
                              activeOnly: currentUser.accessLevel != null &&
                                      currentUser.accessLevel! >= 2
                                  ? false
                                  : true);
                        });
                      });
                    },
                    child: ListTile(
                      title: Row(
                        children: [
                          CountryBadge(country: club.country),
                          Expanded(
                            child: Text(
                              club.name ?? '',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward),
                    ),
                  ),
                );
              }

              List<Widget> section(String title, List<Club> items, bool inactive) {
                if (items.isEmpty) return [];
                return [
                  ColoredPageHeader(title: '$title (${items.length})'),
                  const Divider(height: 4),
                  for (final club in items) clubRow(club, inactive),
                  pageSectionGap,
                ];
              }

              return ListView(
                children: [
                  PageTitleBlock(title: 'Clubs (${clubs.length})'),
                  if (clubs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('No clubs found')),
                    ),
                  ...section('Active clubs', activeClubs, false),
                  ...section('Inactive clubs', inactiveClubs, true),
                ],
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
