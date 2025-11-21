import 'package:salonappweb/ui/booking/customer_login.dart';

import 'constants.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:salonappweb/ui/login.dart';
import 'package:salonappweb/ui/logout.dart';
import 'package:salonappweb/ui/dashboard.dart';
import 'package:salonappweb/model/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salonappweb/ui/pos/home.dart';
import 'package:salonappweb/ui/booking/home.dart';
import 'package:flutter/rendering.dart';
import 'package:salonappweb/provider/booking.provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

void main() async {
  debugPaintBaselinesEnabled = true; // Enable debug paint

  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  //runApp(const MyApp());
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('vn')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      useFallbackTranslations: true,
      useOnlyLangCode: true,
      child: ChangeNotifierProvider(
        create: (context) => BookingProvider(),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static User? currentUser;
  static Map<String, dynamic>? customerProfile;
  // static Future<User> currentUser;

  @override
  void initState() {
    super.initState();
    _initializeCurrentUser();
    _initializeCustomerProfile();
  }

  Future<void> _initializeCurrentUser() async {
    final user = await _getUserInfo();
    setState(() {
      currentUser = user;
      print('Current user: $currentUser');
    });
  }

  Future<void> _initializeCustomerProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final customerToken = prefs.getString('customer_token');

    if (customerToken != null && customerToken.isNotEmpty) {
      print('Customer token found, loading profile at startup...');
      // Load customer profile from API
      try {
        final profile = await _fetchCustomerProfile(customerToken);
        setState(() {
          customerProfile = profile;
          print('Customer profile loaded: $customerProfile');
        });
      } catch (e) {
        print('Error loading customer profile at startup: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchCustomerProfile(String token) async {
    final response = await http.get(
      Uri.parse('http://83.136.248.80:8080/api/booking/customer/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<User> _getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('objuser') ?? '{}';
    final userJson = json.decode(userData);
    return User.fromJson(userJson);
  }

  @override
  Widget build(BuildContext context) {
    const color = Color(COLOR_PRIMARY);
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      title: 'SALON APP WEB',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: color, // Set default app bar background color
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'OpenSans',
                fontSize: 20,
                color: Colors.white,
              ),
        ),
      ),
      // home: AuthChecker(),
      home: const AppInitializer(),
      routes: {
        '/home': (context) => const CustomerLoginPage(),
        '/dashboard': (context) => const AuthChecker(),
        '/booking': (context) => const CustomerHomeScreen(),
        '/pos': (context) => const SaleScreen(),
        '/checkin': (context) => const CheckInScreen(),
        '/checkout': (context) => const CheckOutScreen(),
        '/login': (context) => const Login(),
        '/logout': (context) => const LogoutPage(),
      },
    );
  }
}

class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _determineInitialRoute(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          final route = snapshot.data ?? '/home';
          print('=== APP INITIALIZER ===');
          print('Determined initial route: $route');

          // Navigate to the determined route
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, route);
          });

          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }

  Future<String> _determineInitialRoute() async {
    final prefs = await SharedPreferences.getInstance();

    // Check for customer token first (guest booking)
    final String? customerToken = prefs.getString('customer_token');
    if (customerToken != null && customerToken.isNotEmpty) {
      print('✓ Customer token found, routing to /booking');
      return '/booking';
    }

    // Check for admin token (staff user)
    final String? adminToken = prefs.getString('token');
    if (adminToken != null && adminToken.isNotEmpty) {
      print('✓ Admin token found, routing to /dashboard');
      return '/dashboard';
    }

    // No token found, go to customer login page
    print('✗ No token found, routing to /home (customer login)');
    return '/home';
  }
}

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          if (snapshot.hasData && snapshot.data == true) {
            // Token is saved, proceed to main app
            // Update currentUser in MyAppState
            return const Dashboard();
          } else {
            // Token is not saved, navigate to login page
            return const Login();
          }
        }
      },
    );
  }

  Future<bool> _checkToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    return token != null;
  }
}
