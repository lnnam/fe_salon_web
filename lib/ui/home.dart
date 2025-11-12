import 'package:flutter/material.dart';
import 'package:salonappweb/ui/common/drawer_dashboard.dart';
import 'package:salonappweb/model/user.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {

   // final User user = ModalRoute.of(context)!.settings.arguments as User;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salon APP'),
        iconTheme: const IconThemeData(color: Colors.white)
      ),
      drawer: const AppDrawerDashboard(),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/dashboard');
          },
          child: const Text('Go to dashboard'),
        ),
      ),
    );
  }
}
