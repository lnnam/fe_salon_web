import 'package:flutter/material.dart';
import 'package:salonappweb/constants.dart';
import 'package:salonappweb/main.dart';
import 'package:salonappweb/ui/common/drawer_dashboard.dart';


class Dashboard extends StatelessWidget {
  const Dashboard({super.key});


  @override
  Widget build(BuildContext context) {
    const color = Color(COLOR_PRIMARY);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
       // iconTheme: IconThemeData(color: Colors.white),
        
       // backgroundColor: color, // Set app bar color
      ),
      drawer: const AppDrawerDashboard(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, salon name ${MyAppState.currentUser!.salonname}!',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('User: ${MyAppState.currentUser!.username}'),
              ],
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              children: [
                _buildDashboardButton(context, 'Appointment', Icons.event,
                    color, '/booking'),
                _buildDashboardButton(context, 'Go Sale', Icons.shopping_cart,
                    color, '/pos'),
                _buildDashboardButton(context, 'Go Check-in',
                    Icons.check_circle, color, '/checkin'),
                _buildDashboardButton(context, 'Go Check-out',
                    Icons.check_circle_outline, color, '/checkout'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: color,
        child: SizedBox(
          height: 56.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () {
                 
                },
                icon: const Icon(Icons.event, color: Colors.white),
              ),
              IconButton(
                onPressed: () {
                  
                },
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
              ),
              IconButton(
                onPressed: () {
                  
                },
                icon: const Icon(Icons.check_circle, color: Colors.white),
              ),
              IconButton(
                onPressed: () {
                  
                },
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              ),
            ],
          ),
        ),
      ), 
    );
  }

  Widget _buildDashboardButton(BuildContext context, String title,
      IconData icon, Color color, String route) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
         // Navigator.push( context, MaterialPageRoute(builder: (context) => screen));
          Navigator.pushReplacementNamed(context, route);
        },
        child: Card(
          elevation: 3,
          color: color,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class CheckInScreen extends StatelessWidget {
  const CheckInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in'),
        backgroundColor: Colors.blue, // Set app bar color
      ),
      body: const Center(
        child: Text('Check-in Screen'),
      ),
    );
  }
}

class CheckOutScreen extends StatelessWidget {
  const CheckOutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-out'),
        backgroundColor: Colors.blue, // Set app bar color
      ),
      body: const Center(
        child: Text('Check-out Screen'),
      ),
    );
  }
}
