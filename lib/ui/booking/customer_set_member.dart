import 'package:flutter/material.dart';
import 'package:salonappweb/model/customer.dart';
import 'package:salonappweb/api/api_manager.dart';

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
      await apiManager.registerMember(
        customerkey: widget.customer.customerkey,
        fullname: name,
        email: email,
        phone: phone,
        password: password,
        dob: dob,
      );

      // Create updated customer locally and return it to caller
      final updated = Customer(
        customerkey: widget.customer.customerkey,
        fullname: name,
        email: email,
        phone: phone,
        photo: widget.customer.photo,
        dob: dob,
      );

      if (!mounted) return;
      Navigator.pop(context, updated);
    } catch (e) {
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
                TextField(
                  controller: dobController,
                  decoration: const InputDecoration(
                      labelText: 'Date of Birth (YYYY-MM-DD)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cake)),
                  keyboardType: TextInputType.datetime,
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
