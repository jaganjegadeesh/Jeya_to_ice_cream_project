// ignore_for_file: deprecated_member_use

import 'package:aj_maintain/view/view.dart';
import 'package:flutter/material.dart';
import 'package:aj_maintain/theme/theme.dart';
import 'package:aj_maintain/constant/constant.dart';
import 'package:aj_maintain/service/service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // ignore: non_constant_identifier_names
  String? login_user_role;

  @override
  void initState() {
    super.initState();
    _initLoginUserRole();
  }

  void logout() async {
    await Db.clearDb();
    Navigator.pushReplacement(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (context) => const Login()),
    );
  }

  Future<void> _initLoginUserRole() async {
    login_user_role = await Constants.login_user_role;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(color: AppTheme.appTheme.indicatorColor),
        ),
        backgroundColor: AppTheme.appTheme.primaryColor,
        leading: IconButton(
          icon: Icon(Icons.menu, color: AppTheme.appTheme.indicatorColor),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(color: AppTheme.appTheme.primaryColor),
              height: 70,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  "Menu",
                  style: TextStyle(
                    fontSize: 30,
                    color: AppTheme.appTheme.indicatorColor,
                  ),
                ),
              ),
            ),
            if (login_user_role == 'Super Admin')
              // Product with nested menu
              ExpansionTile(
                leading: const Icon(Icons.add_moderator_outlined),
                title: const Text('Admin'),
                children: [
                  ListTile(
                    leading: const Icon(Icons.business_outlined),
                    title: const Text("Company"),
                    onTap: () {
                      Navigator.pop(context);
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(builder: (context) => const SalesProductScreen()),
                      // );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.supervised_user_circle_rounded),
                    title: const Text("User"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserList(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ExpansionTile(
              leading: const Icon(Icons.production_quantity_limits),
              title: const Text('Creation'),
              children: [
                ListTile(
                  leading: const Icon(Icons.shopping_bag),
                  title: const Text("Product"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProductList(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.boy_rounded),
                  title: const Text("Retailer"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RetailerList(),
                      ),
                    );
                  },
                ),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.production_quantity_limits),
              title: const Text('Assign Product'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AssignProductList(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.currency_rupee),
              title: const Text('Receipt'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReceiptList()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.reset_tv_rounded),
              title: const Text('Return Product'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReturnProductList(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                logout();
              },
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text('Dashboard Content', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
