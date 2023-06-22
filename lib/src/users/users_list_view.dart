import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/users/user_detail_view.dart';
import 'package:eurocup_frontend/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

class UserListView extends StatefulWidget {
  const UserListView({Key? key}) : super(key: key);

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
        // currentAthlete = Athlete();
        Navigator.pushNamed(context, UserDetailView.routeName, arguments: null)
            .then((value) {
          setState(() {});
        });
      }, title: 'User List', icon: Icons.add),
      body: Container(
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/images/bck.jpg'), fit: BoxFit.cover)),
        child: FutureBuilder(
          future: api.getUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData) {
              final users = snapshot.data!;
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (BuildContext context, int index) {
                  return Column(
                    children: [
                      ListTile(
                          // tileColor: Colors.blue,
                          // leading: Text(users[index].clubId.toString()),
                          title: Text(
                            '${users[index].name!} (access level: ${users[index].accessLevel})',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          onTap: () {
                            // currentAthlete = athlete;
                            Navigator.pushNamed(
                                    context, UserDetailView.routeName,
                                    arguments: users[index])
                                .then((value) {
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
}
