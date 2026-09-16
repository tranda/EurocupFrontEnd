import 'package:eurocup_frontend/src/api_helper.dart' as api;
import 'package:eurocup_frontend/src/clubs/club_athlete_list_view.dart';
import 'package:eurocup_frontend/src/clubs/club_details_view.dart';
import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/teams/team_list_view.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';

class ClubDetailPage extends StatefulWidget {
  const ClubDetailPage({super.key});

  static const routeName = '/club_detail_page';

  @override
  State<ClubDetailPage> createState() => _ClubDetailPageState();
}

class _ClubDetailPageState extends State<ClubDetailPage> {
  static const Color primaryBlue = Color.fromARGB(255, 0, 80, 150);

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
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      final int clubId = args['clubId'];

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

  Widget _countryChip() {
    if (club!.country == null || club!.country!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              '${getCountryFlag(club!.country)} ${getCountryCode(club!.country)}',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: primaryBlue),
          title: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(title, style: Theme.of(context).textTheme.displaySmall),
          ),
          subtitle: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 8.0),
            child: Text(subtitle),
          ),
          trailing: const Icon(Icons.arrow_forward),
          onTap: onTap,
        ),
        const Divider(height: 4),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || club == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Club Details')),
        body: const Center(child: CircularProgressIndicator()),
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
        decoration: bckDecoration(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 100),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!editable) _countryChip(),
                TextFormField(
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Required' : null,
                  textCapitalization: TextCapitalization.words,
                  decoration: buildStandardInputDecorationWithLabel('Club Name'),
                  controller: nameController,
                  enabled: editable,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  textCapitalization: TextCapitalization.words,
                  decoration: buildStandardInputDecorationWithLabel('Country'),
                  controller: countryController,
                  enabled: editable,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Active',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle:
                      Text(_isActive ? 'Club is active' : 'Club is inactive'),
                  value: _isActive,
                  activeColor: primaryBlue,
                  contentPadding: EdgeInsets.zero,
                  onChanged: editable
                      ? (bool value) {
                          setState(() {
                            _isActive = value;
                          });
                        }
                      : null,
                ),
                if (!editable) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 4),
                  _actionTile(
                    icon: Icons.people,
                    title: 'Club Members',
                    subtitle: 'View all athletes in this club',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        ClubAthleteListView.routeName,
                        arguments: {'clubId': club!.id, 'title': club!.name!},
                      );
                    },
                  ),
                  _actionTile(
                    icon: Icons.groups,
                    title: 'Club Teams',
                    subtitle: 'View and manage teams of this club',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        TeamListView.routeName,
                        arguments: {'clubId': club!.id, 'title': club!.name!},
                      );
                    },
                  ),
                  _actionTile(
                    icon: Icons.analytics,
                    title: 'Club Statistics',
                    subtitle: 'View club statistics and breakdown',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        ClubDetailView.routeName,
                        arguments: {'clubId': club!.id, 'title': club!.name!},
                      );
                    },
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
