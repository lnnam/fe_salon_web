import 'package:flutter/material.dart';
import 'package:salonappweb/model/customer.dart';
import 'package:salonappweb/api/api_manager.dart';
import 'package:salonappweb/services/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:salonappweb/main.dart';

class CustomerSetMemberPage extends StatefulWidget {
  final Customer customer;
  const CustomerSetMemberPage({super.key, required this.customer});

  @override
  _CustomerSetMemberPageState createState() => _CustomerSetMemberPageState();
}

class _CustomerSetMemberPageState extends State<CustomerSetMemberPage> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController dobController;
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  String? errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.customer.fullname);
    emailController = TextEditingController(text: widget.customer.email);
    phoneController = TextEditingController(text: widget.customer.phone);
    dobController = TextEditingController(text: widget.customer.dob);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    dobController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() {
      errorMessage = null;
    });

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final dob = dobController.text.trim();
    final password = passwordController.text;
    final confirm = confirmPasswordController.text;

    if (name.isEmpty) {
      setState(() => errorMessage = 'Please enter your name');
      return;
    }
    if (email.isEmpty) {
      setState(() => errorMessage = 'Please enter your email');
      return;
    }
    if (password.isEmpty || password.length < 6) {
      setState(() => errorMessage = 'Password must be at least 6 characters');
      return;
    }
    if (password != confirm) {
      setState(() => errorMessage = 'Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? customerToken = prefs.getString('customer_token');

      Map<String, dynamic> result;

      if (customerToken != null && customerToken.isNotEmpty) {
        appLog(
            'Calling registerMember for customer ${widget.customer.customerkey}');
        result = await apiManager.registerMember(
          customerkey: widget.customer.customerkey,
          fullname: name,
          email: email,
          phone: phone,
          password: password,
          dob: dob,
        );
      } else {
        appLog(
            'No customer token found — calling registerNewCustomer (public)');
        result = await apiManager.registerNewCustomer(
          fullname: name,
          email: email,
          phone: phone,
          password: password,
          dob: dob,
        );

        // If backend returned a token for new registration, persist it
        if (result['token'] != null) {
          await prefs.setString('customer_token', result['token']);
          if (result['customerkey'] != null) {
            await prefs.setString(
                'customer_key', result['customerkey'].toString());
          }
          appLog('Stored new customer token from public registration');
        }
      }

      appLog('Register result: ${result.toString()}');

      // Create updated customer locally and return it to caller
      final updated = Customer(
        customerkey: widget.customer.customerkey,
        fullname: name,
        email: email,
        phone: phone,
        photo: widget.customer.photo,
        dob: dob,
      );

      // Optionally update cached profile if backend returned profile data
      try {
        if (result.containsKey('customer') && result['customer'] is Map) {
          final cached = result['customer'] as Map<String, dynamic>;
          await prefs.setString('cached_customer_profile', jsonEncode(cached));
          MyAppState.customerProfile = cached;
          appLog('Updated cached customer profile from register result');
        }
      } catch (e) {
        appLog('Could not update cached profile: $e');
      }

      if (!mounted) return;
      Navigator.pop(context, updated);
    } catch (e) {
      appLog('Error saving member: $e');
      setState(() => errorMessage = 'Failed to create member account: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Member Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Complete your profile and set a password to create your member account for future logins.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                if (errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Text(errorMessage!,
                        style: const TextStyle(color: Colors.red)),
                  ),
                ],
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                      labelText: 'Email *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone)),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                // Make DOB field read-only and open date picker on tap
                TextField(
                  controller: dobController,
                  readOnly: true,
                  decoration: const InputDecoration(
                      labelText: 'Date of Birth (YYYY-MM-DD)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cake)),
                  onTap: () async {
                    DateTime initial = DateTime.now();
                    try {
                      if (dobController.text.isNotEmpty) {
                        initial = DateTime.parse(dobController.text);
                      } else {
                        initial = DateTime.now()
                            .subtract(const Duration(days: 365 * 20));
                      }
                    } catch (_) {
                      initial = DateTime.now()
                          .subtract(const Duration(days: 365 * 20));
                    }

                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );

                    if (picked != null) {
                      final formatted =
                          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      setState(() {
                        dobController.text = formatted;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => obscurePassword = !obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(() =>
                          obscureConfirmPassword = !obscureConfirmPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Save Member'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
