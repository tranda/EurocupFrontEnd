import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:eurocup_frontend/src/clubs/club_athlete_list_view.dart';
import 'package:eurocup_frontend/src/clubs/club_details_view.dart';
import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/teams/team_list_view.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:eurocup_frontend/src/widgets/page_template.dart';
import 'package:flutter/material.dart';

class ClubDetailPage extends StatefulWidget {
  const ClubDetailPage({super.key});

  static const routeName = '/club_detail_page';

  @override
  State<ClubDetailPage> createState() => _ClubDetailPageState();
}

class _ClubDetailPageState extends State<ClubDetailPage> {
  static const Color primaryBlue = pageBlue;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController countryController = TextEditingController();

  bool editable = false;
  Club? club;
  bool _isActive = true;
  String mode = 'r';
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isLoading) {
      // On a browser refresh the in-memory route arguments are gone; recover
      // clubId from the URL/localStorage (App._extractArgumentsFromSettings
      // repopulates it) and fall back to localStorage directly if needed.
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      final int? clubId = args?['clubId'] as int? ?? loadSelectedClubId();
      if (clubId == null) {
        // No club context at all — stop the spinner and show an empty page
        // instead of crashing grey.
        setState(() => _isLoading = false);
        return;
      }
      // Keep the fallback fresh so a subsequent refresh still recovers context.
      saveSelectedClubId(clubId);

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

  List<Widget> _infoDisplay() {
    final textTheme = Theme.of(context).textTheme;
    final hasCountry = club!.country != null && club!.country!.isNotEmpty;
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasCountry) CountryBadge(country: club!.country),
          Flexible(
            child: Text(
              club!.country ?? 'No country',
              style: textTheme.headlineMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      StatusChip(
        label: _isActive ? 'Active' : 'Inactive',
        color: _isActive ? Colors.green : Colors.grey,
      ),
    ];
  }

  Widget _infoForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          validator: (value) =>
              (value == null || value.isEmpty) ? 'Required' : null,
          textCapitalization: TextCapitalization.words,
          decoration: pageFieldDecoration('Club Name'),
          controller: nameController,
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 12),
        TextFormField(
          textCapitalization: TextCapitalization.words,
          decoration: pageFieldDecoration('Country'),
          controller: countryController,
          style: Theme.of(context).textTheme.displaySmall,
        ),
        SwitchListTile(
          title: Text('Active',
              style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Text(_isActive ? 'Club is active' : 'Club is inactive',
              style: Theme.of(context).textTheme.bodyMedium),
          value: _isActive,
          activeColor: primaryBlue,
          contentPadding: EdgeInsets.zero,
          onChanged: (bool value) {
            setState(() {
              _isActive = value;
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Club Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (club == null) {
      // No club context (e.g. refreshed a bare URL). Offer a way back instead
      // of spinning or crashing grey.
      return Scaffold(
        appBar: AppBar(title: const Text('Club Details')),
        body: const Center(child: Text('Club not found.')),
      );
    }

    editable = mode == 'm';

    return Scaffold(
      appBar: AppBar(
        title: Text(club!.name ?? 'Club Details'),
        actions: [
          if (!editable &&
              currentUser.accessLevel != null &&
              currentUser.accessLevel! >= 2)
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
        // Fill the screen even when the content is short.
        height: double.infinity,
        decoration: bckDecoration(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageTitleBlock(
                  title: club!.name ?? 'Unknown',
                  children: editable ? [_infoForm()] : _infoDisplay(),
                ),
                pageSectionGap,
                if (!editable)
                  MenuSection(
                    title: 'Manage',
                    rows: [
                      MenuRow(
                        icon: Icons.people,
                        title: 'Club Members',
                        subtitle: 'View all athletes in this club',
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
                      MenuRow(
                        icon: Icons.groups,
                        title: 'Club Teams',
                        subtitle: 'View and manage teams of this club',
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            TeamListView.routeName,
                            arguments: {
                              'clubId': club!.id,
                              'title': club!.name!
                            },
                          );
                        },
                      ),
                      MenuRow(
                        icon: Icons.analytics,
                        title: 'Club Statistics',
                        subtitle: 'View club statistics and breakdown',
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
            FloatingActionButton.extended(
              heroTag: "saveClubBtn",
              backgroundColor: primaryBlue,
              icon: const Icon(Icons.save, color: Colors.white),
              label:
                  const Text('Save', style: TextStyle(color: Colors.white)),
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
                        const SnackBar(
                            content: Text('Club updated successfully')),
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
            ),
            FloatingActionButton.extended(
              heroTag: "deleteClubBtn",
              backgroundColor: Colors.red,
              icon: const Icon(Icons.delete, color: Colors.white),
              label:
                  const Text('Delete', style: TextStyle(color: Colors.white)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Delete Club?'),
                      content: const Text(
                          'Are you sure you want to delete this club? This action cannot be undone.'),
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
                                Navigator.pop(context);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Club deleted successfully')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Failed to delete club: $e')),
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
            ),
          ],
        ),
      ),
    );
  }
}
