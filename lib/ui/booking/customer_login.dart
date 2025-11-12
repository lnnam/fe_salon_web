import 'package:flutter/material.dart';
import 'guest_login.dart';

class CustomerLoginPage extends StatefulWidget {
  const CustomerLoginPage({super.key});

  @override
  _CustomerLoginPageState createState() => _CustomerLoginPageState();
}

class _CustomerLoginPageState extends State<CustomerLoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo or Title
                const SizedBox(height: 40),
                const Text(
                  'Salon App',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 40),

                // Username TextField
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.person),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),

                // Password TextField
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      if (_usernameController.text.isNotEmpty &&
                          _passwordController.text.isNotEmpty) {
                        print(
                            'Login: ${_usernameController.text}, ${_passwordController.text}');
                        // Add login API call here
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Please enter username and password')),
                        );
                      }
                    },
                    child: const Text(
                      'LOGIN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Sub Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Register Button
                    TextButton(
                      onPressed: () {
                        print('Navigate to Register');
                        // Add navigation to register page
                      },
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Divider
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.grey[300],
                    ),
                    // Guest Booking Button
                    TextButton(
                      onPressed: () {
                        // Navigate to Guest Login page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const GuestLoginPage()),
                        );
                      },
                      child: const Text(
                        'Guest Booking',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Divider
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.grey[300],
                    ),
                    // Forgot Password Button
                    TextButton(
                      onPressed: () {
                        print('Forgot Password');
                        // Add navigation to forgot password page
                      },
                      child: const Text(
                        'Forgot?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
