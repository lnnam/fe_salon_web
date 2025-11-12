import 'package:salonappweb/ui/booking/customer_login.dart';

import 'constants.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:salonappweb/ui/login.dart';
import 'package:salonappweb/ui/dashboard.dart';
import 'package:salonappweb/model/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salonappweb/ui/pos/home.dart';
import 'package:salonappweb/ui/booking/home.dart';
import 'package:flutter/rendering.dart';
import 'package:salonappweb/provider/booking.provider.dart';
import 'package:provider/provider.dart';

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
  // static Future<User> currentUser;

  @override
  void initState() {
    super.initState();
    _initializeCurrentUser();
  }

  Future<void> _initializeCurrentUser() async {
    final user = await _getUserInfo();
    setState(() {
      currentUser = user;
      print('Current user: $currentUser');
    });
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
      initialRoute: '/',
      routes: {
        '/': (context) => const CustomerLoginPage(),
        '/dashboard': (context) => const AuthChecker(),
        '/booking': (context) => const CustomerHomeScreen(),
        '/pos': (context) => const SaleScreen(),
        '/checkin': (context) => const CheckInScreen(),
        '/checkout': (context) => const CheckOutScreen(),
        '/login': (context) => const Login(),
        '/logout': (context) => const Login(),
      },
    );
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
