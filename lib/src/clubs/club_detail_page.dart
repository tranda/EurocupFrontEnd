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

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: primaryBlue,
        ),
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _countryChip() {
    if (club!.country == null || club!.country!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
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
    );
  }

  Widget _infoDisplay() {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          club!.name ?? 'Unknown',
          style: textTheme.displaySmall,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _countryChip(),
            if (club!.country != null && club!.country!.isNotEmpty)
              const SizedBox(width: 8),
            Text(
              club!.country ?? 'No country',
              style: textTheme.headlineMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              _isActive ? Icons.check_circle : Icons.cancel,
              size: 18,
              color: _isActive ? Colors.green.shade600 : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              _isActive ? 'Active' : 'Inactive',
              style: textTheme.bodyLarge?.copyWith(
                color: _isActive ? Colors.green.shade700 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _infoForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          validator: (value) =>
              (value == null || value.isEmpty) ? 'Required' : null,
          textCapitalization: TextCapitalization.words,
          decoration: buildStandardInputDecorationWithLabel('Club Name'),
          controller: nameController,
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 12),
        TextFormField(
          textCapitalization: TextCapitalization.words,
          decoration: buildStandardInputDecorationWithLabel('Country'),
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

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: primaryBlue),
      title: Text(title, style: Theme.of(context).textTheme.displaySmall),
      subtitle:
          Text(subtitle, style: Theme.of(context).textTheme.headlineMedium),
      trailing: const Icon(Icons.arrow_forward),
      onTap: onTap,
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('CLUB INFO'),
                _card(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: editable ? _infoForm() : _infoDisplay(),
                ),
                if (!editable) ...[
                  const SizedBox(height: 24),
                  _sectionLabel('MANAGE'),
                  _card(
                    child: Column(
                      children: [
                        _actionTile(
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
                        Divider(
                            height: 1,
                            color: Colors.grey.shade200,
                            indent: 16,
                            endIndent: 16),
                        _actionTile(
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
                        Divider(
                            height: 1,
                            color: Colors.grey.shade200,
                            indent: 16,
                            endIndent: 16),
                        _actionTile(
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
