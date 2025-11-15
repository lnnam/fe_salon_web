import 'package:flutter/material.dart';
import 'guest_login.dart';
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
  final TextEditingController _usernameController =
      TextEditingController(text: 'le160483@gmail.com');
  final TextEditingController _passwordController =
      TextEditingController(text: '111111');
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Don't clear data automatically - only clear on explicit logout
    // This prevents losing customer token on page refresh (F5)
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
                        _showRegisterDialog(context);
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
          print('✓ Customer profile loaded and stored in MyAppState');

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

  void _showRegisterDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final dobController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool _obscurePassword = true;
    bool _obscureConfirmPassword = true;
    String? _errorMessage;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Register New Account'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create your member account to book appointments and manage your profile.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: dobController,
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth (YYYY-MM-DD)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cake),
                        hintText: '1990-01-01',
                      ),
                      keyboardType: TextInputType.datetime,
                      onTap: () async {
                        // Show date picker when field is tapped
                        FocusScope.of(context).requestFocus(FocusNode());
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: dobController.text.isNotEmpty
                              ? DateTime.tryParse(dobController.text) ??
                                  DateTime.now()
                              : DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          dobController.text =
                              '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Set Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Error message banner at bottom
                    if (_errorMessage != null) ...[
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
                                _errorMessage!,
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
                    const Text(
                      '* Required fields',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Clear previous error
                    setDialogState(() {
                      _errorMessage = null;
                    });

                    // Validate inputs
                    if (nameController.text.trim().isEmpty) {
                      setDialogState(() {
                        _errorMessage = 'Please enter your name';
                      });
                      return;
                    }
                    if (emailController.text.trim().isEmpty) {
                      setDialogState(() {
                        _errorMessage = 'Please enter your email';
                      });
                      return;
                    }
                    if (passwordController.text.isEmpty) {
                      setDialogState(() {
                        _errorMessage = 'Please set a password';
                      });
                      return;
                    }
                    if (passwordController.text.length < 6) {
                      setDialogState(() {
                        _errorMessage =
                            'Password must be at least 6 characters';
                      });
                      return;
                    }
                    if (passwordController.text !=
                        confirmPasswordController.text) {
                      setDialogState(() {
                        _errorMessage = 'Passwords do not match';
                      });
                      return;
                    }

                    // Show loading indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    );

                    try {
                      // Call API to register new customer (public registration, no token required)
                      final result = await apiManager.registerNewCustomer(
                        fullname: nameController.text.trim(),
                        email: emailController.text.trim(),
                        phone: phoneController.text.trim(),
                        password: passwordController.text,
                        dob: dobController.text.trim(),
                      );

                      print('Register customer result: $result');

                      // If registration successful and returns token, auto-login
                      if (result['token'] != null) {
                        // Fetch full customer profile using the token
                        final profileData =
                            await apiManager.fetchCustomerProfile();

                        if (profileData != null) {
                          // Store customer profile in MyAppState
                          MyAppState.customerProfile = profileData;
                          print('✓ Customer profile loaded after registration');

                          // Cache profile in SharedPreferences for persistence
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('cached_customer_profile',
                              jsonEncode(profileData));
                          print('✓ Customer profile cached after registration');

                          // Set customer data in BookingProvider for booking flow
                          final bookingProvider = Provider.of<BookingProvider>(
                              context,
                              listen: false);
                          bookingProvider.setCustomerDetails({
                            'pkey': profileData['pkey'] ??
                                profileData['customerkey'],
                            'customerkey': profileData['pkey'] ??
                                profileData['customerkey'],
                            'fullname': profileData['fullname'] ?? 'Guest',
                            'email': profileData['email'] ?? '',
                            'phone': profileData['phone'] ?? '',
                            'dob': profileData['dob'] ?? '',
                          });
                          print(
                              '✓ Customer data set in BookingProvider after registration');
                        }

                        // Close loading dialog
                        Navigator.pop(context);
                        // Close register dialog
                        Navigator.pop(dialogContext);

                        // Navigate to customer home/profile page
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CustomerHomeScreen()),
                        );
                      } else {
                        // If no token returned, just show success message and stay on login page
                        // Close loading dialog
                        Navigator.pop(context);
                        // Close register dialog
                        Navigator.pop(dialogContext);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Account created successfully! Please login with your email and password.',
                            ),
                            duration: Duration(seconds: 4),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      print('Error registering member: $e');

                      // Close loading dialog
                      Navigator.pop(context);

                      // Show error in dialog
                      setDialogState(() {
                        _errorMessage = 'Failed to create account: $e';
                      });
                    }
                  },
                  child: const Text('Register'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
