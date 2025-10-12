import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:eurocup_frontend/src/clubs/club_athlete_list_view.dart';
import 'package:eurocup_frontend/src/clubs/club_details_view.dart';
import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';

class ClubDetailPage extends StatefulWidget {
  const ClubDetailPage({super.key});

  static const routeName = '/club_detail_page';

  @override
  State<ClubDetailPage> createState() => _ClubDetailPageState();
}

class _ClubDetailPageState extends State<ClubDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController countryController = TextEditingController();

  bool editable = false;
  Club? club;
  bool _isActive = true;
  String mode = 'r'; // 'r' for read, 'm' for modify
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isLoading) {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      final int clubId = args['clubId'];

      // Fetch club data
      api.getClubs(activeOnly: false).then((clubs) {
        final foundClub = clubs.firstWhere((c) => c.id == clubId,
          orElse: () => Club(id: clubId, name: 'Unknown', country: null));

        setState(() {
          club = foundClub;
          nameController.text = foundClub.name ?? '';
          countryController.text = foundClub.country ?? '';
          _isActive = foundClub.active ?? true;
          _isLoading = false;
        });
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || club == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Club Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
        title: Text(club!.name ?? 'Club Details'),
        actions: [
          if (!editable && currentUser.accessLevel != null && currentUser.accessLevel! >= 2)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  mode = 'm';
                });
              },
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
                // Club Information Section
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Club Information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                          textCapitalization: TextCapitalization.words,
                          decoration: buildStandardInputDecorationWithLabel('Club Name'),
                          controller: nameController,
                          enabled: editable,
                          style: Theme.of(context).textTheme.displaySmall,
                          onChanged: (value) {
                            // Update club name
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          textCapitalization: TextCapitalization.words,
                          decoration: buildStandardInputDecorationWithLabel('Country'),
                          controller: countryController,
                          enabled: editable,
                          style: Theme.of(context).textTheme.displaySmall,
                          onChanged: (value) {
                            // Update country
                          },
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Active'),
                          subtitle: Text(_isActive ? 'Club is active' : 'Club is inactive'),
                          value: _isActive,
                          onChanged: editable ? (bool value) {
                            setState(() {
                              _isActive = value;
                            });
                          } : null,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons Section
                if (!editable) ...[
                  Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.people),
                          title: const Text('Club Members'),
                          subtitle: const Text('View all athletes in this club'),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              ClubAthleteListView.routeName,
                              arguments: {
                                'clubId': club!.id,
                                'title': club!.name!
                              },
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.analytics),
                          title: const Text('Club Statistics'),
                          subtitle: const Text('View club statistics and breakdown'),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              ClubDetailView.routeName,
                              arguments: {
                                'clubId': club!.id,
                                'title': club!.name!
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
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
              heroTag: "saveClubBtn",
              backgroundColor: Colors.blue,
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    await api.updateClub(
                      club!.id!,
                      nameController.text,
                      countryController.text,
                      _isActive,
                    );
                    if (mounted) {
                      setState(() {
                        club = Club(
                          id: club!.id,
                          name: nameController.text,
                          country: countryController.text,
                          active: _isActive,
                          req_adel: club!.req_adel,
                          createdAt: club!.createdAt,
                          updatedAt: club!.updatedAt,
                        );
                        mode = 'r';
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Club updated successfully')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update club: $e')),
                      );
                    }
                  }
                }
              },
              child: const Icon(Icons.save),
            ),
            FloatingActionButton(
              heroTag: "deleteClubBtn",
              backgroundColor: Colors.red,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Delete Club?'),
                      content: const Text('Are you sure you want to delete this club? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            try {
                              await api.deleteClub(club!.id!);
                              if (context.mounted) {
                                Navigator.pop(context); // Close dialog
                                Navigator.pop(context); // Go back to list
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Club deleted successfully')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.pop(context); // Close dialog
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to delete club: $e')),
                                );
                              }
                            }
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Icon(Icons.delete),
            ),
          ],
        ),
      ),
    );
  }
}
