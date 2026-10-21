import 'package:eurocup_frontend/src/model/user.dart';
import 'package:eurocup_frontend/src/users/user_detail_view.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:eurocup_frontend/src/widgets/page_template.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

class UserListView extends StatefulWidget {
  const UserListView({super.key});

  static const routeName = '/users_list';

  @override
  State<UserListView> createState() => ListViewState();
}

class ListViewState extends State<UserListView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWithAction(() {
        Navigator.pushNamed(context, UserDetailView.routeName, arguments: null)
            .then((value) {
          setState(() {});
        });
      }, title: 'User List', icon: Icons.add),
      body: Container(
        decoration: bckDecoration(),
        child: FutureBuilder<List<User>>(
          future: api.getUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              print('Error in FutureBuilder: ${snapshot.error}');
              return Center(
                child: Text(
                  'Error loading users: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('No data available'));
            }

            final users = snapshot.data!;
            print('Number of users loaded: ${users.length}');

            if (users.isEmpty) {
              return ListView(
                children: const [
                  PageTitleBlock(title: 'Users (0)'),
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No users found')),
                  ),
                ],
              );
            }

            // Group by access level, highest first; unknown level last.
            final Map<int?, List<User>> groups = {};
            for (final user in users) {
              groups.putIfAbsent(user.accessLevel, () => []).add(user);
            }
            final levels = groups.keys.toList()
              ..sort((a, b) {
                if (a == null) return b == null ? 0 : 1;
                if (b == null) return -1;
                return b.compareTo(a);
              });

            final children = <Widget>[
              PageTitleBlock(title: 'Users (${users.length})'),
            ];
            for (final level in levels) {
              final group = groups[level]!;
              children.add(ColoredPageHeader(
                  title: '${_accessLevelName(level)} (${group.length})'));
              children.add(const Divider(height: 4));
              for (final user in group) {
                children.add(PageListItem(
                  onTap: () {
                    print('ListTile tapped for user: ${user.name}');
                    print('User object: $user');
                    print('User id: ${user.id}, name: ${user.name}, username: ${user.username}');

                    Navigator.pushNamed(
                      context,
                      UserDetailView.routeName,
                      arguments: user
                    ).then((value) {
                      print('Returned from UserDetailView');
                      setState(() {});
                    });
                  },
                  child: ListTile(
                    title: Text(
                      user.name ?? 'Unknown',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    subtitle: Text(_userSubtitle(user)),
                    trailing: const Icon(Icons.arrow_forward),
                  ),
                ));
              }
              children.add(pageSectionGap);
            }

            return ListView(children: children);
          },
        ),
      ),
    );
  }

  String _accessLevelName(int? level) {
    if (level == null) return 'No access level';
    if (level == 3) return 'Admins';
    if (level == 2) return 'Organisers';
    if (level == 1) return 'Judges';
    if (level == 0) return 'Club users';
    if (level == -1) return 'Disabled';
    return 'Access level $level';
  }

  String _userSubtitle(User user) {
    final username = user.username ?? 'no username';
    final email = user.email;
    if (email != null && email.isNotEmpty && email != username) {
      return '$username · $email';
    }
    return username;
  }
}
