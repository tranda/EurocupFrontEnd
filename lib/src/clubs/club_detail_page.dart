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

  String _initial(String? name) {
    if (name == null || name.isEmpty) return '?';
    return name.trim().substring(0, 1).toUpperCase();
  }

  Widget _statusBadge(bool active) {
    final color = active ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryBlue,
            primaryBlue.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _initial(club!.name),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  club!.name ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  club!.country ?? 'No country',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 10),
                _statusBadge(_isActive),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EDIT CLUB',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Required' : null,
            textCapitalization: TextCapitalization.words,
            decoration: buildStandardInputDecorationWithLabel('Club Name'),
            controller: nameController,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 16),
          TextFormField(
            textCapitalization: TextCapitalization.words,
            decoration: buildStandardInputDecorationWithLabel('Country'),
            controller: countryController,
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
            onChanged: (bool value) {
              setState(() {
                _isActive = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward,
                  color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
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
                _heroCard(),
                const SizedBox(height: 24),
                if (editable) ...[
                  _editForm(),
                  const SizedBox(height: 24),
                ],
                if (!editable) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _actionCard(
                          icon: Icons.people,
                          iconColor: primaryBlue,
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
                        _actionCard(
                          icon: Icons.analytics,
                          iconColor: Colors.teal,
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
              label: const Text('Save',
                  style: TextStyle(color: Colors.white)),
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
              label: const Text('Delete',
                  style: TextStyle(color: Colors.white)),
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
                                      content: Text(
                                          'Club deleted successfully')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Failed to delete club: $e')),
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
