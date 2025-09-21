import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/model/user.dart';
import 'package:eurocup_frontend/src/users/user_detail_view.dart';
import 'package:eurocup_frontend/src/widgets.dart';
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
              return const Center(child: Text('No users found'));
            }

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (BuildContext context, int index) {
                final user = users[index];
                print('Displaying user $index: ${user.name}');

                return Column(
                  children: [
                    ListTile(
                      title: Text(
                        '${user.name ?? 'Unknown'} (${user.username ?? 'no username'}, access level: ${user.accessLevel ?? 'N/A'})',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
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
                      trailing: const Icon(Icons.arrow_forward)
                    ),
                    const Divider(height: 4),
                    const Divider(height: smallSpace)
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
