import 'package:flutter/material.dart';
import 'guest_login.dart';
import 'customer_register.dart';
import 'package:salonappweb/api/api_manager.dart';
import 'package:salonappweb/main.dart';
import 'home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:salonappweb/provider/booking.provider.dart';

class CustomerLoginPage extends StatefulWidget {
  const CustomerLoginPage({super.key});

  @override
  _CustomerLoginPageState createState() => _CustomerLoginPageState();
}

class _CustomerLoginPageState extends State<CustomerLoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Don't clear data automatically - only clear on explicit logout
    // This prevents losing customer token on page refresh (F5)
  }

  void _showResetPasswordDialog() {
    final emailController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter your account email. A new password will be sent to this email when you submit.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    setDialogState(() {
                      errorMessage = null;
                    });

                    final email = emailController.text.trim();
                    if (email.isEmpty) {
                      setDialogState(() {
                        errorMessage = 'Please enter your email';
                      });
                      return;
                    }
                    if (!email.contains('@')) {
                      setDialogState(() {
                        errorMessage = 'Please enter a valid email';
                      });
                      return;
                    }

                    // Show loading indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    );

                    try {
                      final success =
                          await apiManager.resetCustomerPassword(email: email);

                      // Remove loading
                      Navigator.pop(context);

                      if (success) {
                        Navigator.pop(dialogContext);
                        if (!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'A new password has been sent to your email.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        setDialogState(() {
                          errorMessage =
                              'Failed to reset password. Please try again later.';
                        });
                      }
                    } catch (e) {
                      // Remove loading
                      Navigator.pop(context);
                      setDialogState(() {
                        errorMessage = 'Error: $e';
                      });
                    }
                  },
                  child: const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );
  }

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
                    labelText: 'Email or Phone',
                    hintText: 'Enter your email or phone number',
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
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const CustomerRegisterPage()),
                        );
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
                        _showResetPasswordDialog();
                      },
                      child: const Text(
                        'Forgot Password?',
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

  Future<void> _handleLogin() async {
    // Validate inputs
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email/phone and password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Call customer login API
      final result = await apiManager.customerLogin(
        emailOrPhone: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result != null && result['token'] != null) {
        print('✓ Login successful, token stored');

        // Fetch full customer profile using the token
        final profileData = await apiManager.fetchCustomerProfile();

        if (profileData != null) {
          // Store customer profile in MyAppState
          MyAppState.customerProfile = profileData;
        //  print('✓ Customer profile loaded and stored in MyAppState');

          // Cache profile in SharedPreferences for persistence across page reloads
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              'cached_customer_profile', jsonEncode(profileData));
          print('✓ Customer profile cached in SharedPreferences');

          // Set customer data in BookingProvider for booking flow
          if (!mounted) return;
          final bookingProvider =
              Provider.of<BookingProvider>(context, listen: false);
          bookingProvider.setCustomerDetails({
            'pkey': profileData['pkey'] ?? profileData['customerkey'],
            'customerkey': profileData['pkey'] ?? profileData['customerkey'],
            'fullname': profileData['fullname'] ?? 'Guest',
            'email': profileData['email'] ?? '',
            'phone': profileData['phone'] ?? '',
            'dob': profileData['dob'] ?? '',
          });
          print(
              '✓ Customer data set in BookingProvider: ${profileData['fullname']}');
        } else {
          print('⚠ Could not load customer profile, using login data');
          // Fallback: use login result as profile
          MyAppState.customerProfile = result;

          // Cache the login result as profile
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cached_customer_profile', jsonEncode(result));

          // Set customer data in BookingProvider from login result
          if (!mounted) return;
          final bookingProvider =
              Provider.of<BookingProvider>(context, listen: false);
          bookingProvider.setCustomerDetails({
            'pkey': result['pkey'] ?? result['customerkey'],
            'customerkey': result['pkey'] ?? result['customerkey'],
            'fullname': result['fullname'] ?? 'Guest',
            'email': result['email'] ?? '',
            'phone': result['phone'] ?? '',
          });
          print('✓ Customer data set in BookingProvider from login result');
        }

        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to customer home/profile page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CustomerHomeScreen()),
        );
      } else {
        // Login failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid email/phone or password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
