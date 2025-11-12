import 'package:flutter/material.dart';
import 'package:salonapp/services/helper.dart';
import 'package:salonapp/constants.dart';


class AppDrawerDashboard extends StatelessWidget {
  const AppDrawerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color:  Color(COLOR_PRIMARY),
            ),
            child: Text(
              'Salon name ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            title: const Text('Profile'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/profile');
            },
          ),
          ListTile(
            title: const Text('Setting'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/setting');
            },
          ),
          ListTile(
            title: const Text('Logout'),
            onTap: () {
              logout(context);
            },
          ),
        ],
      ),
    );
  }
}
