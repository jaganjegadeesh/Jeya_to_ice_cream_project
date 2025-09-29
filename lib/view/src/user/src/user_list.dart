// ignore_for_file: deprecated_member_use, non_constant_identifier_names

import 'package:aj_maintain/model/model.dart';
import 'package:aj_maintain/view/view.dart';
import 'package:flutter/material.dart';
import 'package:aj_maintain/service/service.dart';
import 'package:aj_maintain/theme/src/theme.dart';

class UserList extends StatefulWidget {
  const UserList({super.key});

  @override
  State<UserList> createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  final UserService _service = UserService();
  late Future<List<UserModel>> _futureUser;

  @override
  void initState() {
    super.initState();

    _futureUser = _service.getUser();
  }

  void _refresh() {
    setState(() {
      _futureUser = _service.getUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: AppTheme
              .appTheme
              .indicatorColor, // ✅ This changes the back button color
        ),
        backgroundColor: AppTheme.appTheme.primaryColor,
        title: Text(
          'User',
          style: TextStyle(color: AppTheme.appTheme.indicatorColor),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppTheme.appTheme.indicatorColor),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserCreate()),
              );
              if (result == true) _refresh();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _futureUser,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final UserList = snapshot.data!;
            return ListView.builder(
              itemCount: UserList.length,
              itemBuilder: (context, index) {
                final s = UserList[index];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(s.name),
                  subtitle: Text('Phone: ${s.phone}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserUpdate(userId: s.userId),
                            ),
                          );
                          if (result == true) _refresh();
                        },
                      ),
                      if (s.role != 'Super Admin')
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await _service.deleteUser(s.userId);
                            _refresh();
                          },
                        ),
                    ],
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
