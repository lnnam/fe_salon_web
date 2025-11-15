import 'package:flutter/material.dart';
import 'package:salonappweb/api/api_manager.dart';
import 'package:salonappweb/services/helper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'home.dart';
import 'package:salonappweb/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

Future<void> saveBooking(
  BuildContext context,
  int bookingKey,
  void Function(bool) setLoading, // <-- Accepts a bool
  String customerKey,
  String serviceKey,
  String staffKey,
  String bookingDate,
  String bookingTime,
  String note,
  String customerName,
  String staffName,
  String serviceName,
  String customerEmail,
  String customerPhone,
) async {
  setLoading(true);

  print({
    'bookingKey': bookingKey,
    'customerKey': customerKey,
    'serviceKey': serviceKey,
    'staffKey': staffKey,
    'bookingDate': bookingDate,
    'bookingTime': bookingTime,
    'note': note,
    'customerName': customerName,
    'staffName': staffName,
    'serviceName': serviceName,
    'customerEmail': customerEmail,
    'customerPhone': customerPhone,
  });

  final result = await apiManager.SaveBooking(
    bookingKey,
    customerKey,
    serviceKey,
    staffKey,
    bookingDate,
    bookingTime,
    note,
    customerName,
    staffName,
    serviceName,
    customerEmail,
    customerPhone,
  );

  if (result != null) {
    print('=== BOOKING SAVED SUCCESSFULLY ===');
    print('Token: ${result.token}');
    print('Booking Key: ${result.bookingkey}');
    print('Customer Key: ${result.customerkey}');

    // Fetch and cache customer profile
    final prefs = await SharedPreferences.getInstance();
    final profile = await apiManager.fetchCustomerProfile();

    if (profile != null) {
      print('=== CUSTOMER PROFILE AFTER SAVE ===');
      print(profile);

      // IMPORTANT: Merge with existing cached profile to preserve all data
      // The API might not return all fields (email, phone might be null)
      String? existingCache = prefs.getString('cached_customer_profile');
      Map<String, dynamic> finalProfile = profile;

      if (existingCache != null && existingCache.isNotEmpty) {
        try {
          final existingProfile =
              jsonDecode(existingCache) as Map<String, dynamic>;
          print('Merging with existing profile: $existingProfile');

          // Merge: keep existing values if new values are null
          finalProfile = {
            ...existingProfile, // Start with existing data
            ...profile, // Overlay with new data
            // Restore non-null fields from existing if new ones are null
            'email': profile['email'] ?? existingProfile['email'],
            'phone': profile['phone'] ?? existingProfile['phone'],
            'fullname': profile['fullname'] ?? existingProfile['fullname'],
            'dob': profile['dob'] ?? existingProfile['dob'],
          };
          print('Merged profile: $finalProfile');
        } catch (e) {
          print('Error merging profiles, using new profile: $e');
        }
      }

      // Store merged profile in MyAppState
      MyAppState.customerProfile = finalProfile;
      print('✓ Customer profile stored in MyAppState');

      // Cache merged profile in SharedPreferences
      await prefs.setString(
          'cached_customer_profile', jsonEncode(finalProfile));
      print('✓ Customer profile cached in SharedPreferences');

      // Verify
      final verifyCache = prefs.getString('cached_customer_profile');
      print(
          '✓ Verified cache exists: ${verifyCache != null && verifyCache.isNotEmpty}');
    } else {
      print('✗ Failed to fetch customer profile after booking save!');
    }

    // Fetch customer bookings
    final bookings = await apiManager.fetchCustomerBookings();
    print('=== CUSTOMER BOOKINGS ===');
    print('Total bookings: ${bookings.length}');

    setLoading(false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Success"),
          content: const Text("Booking Saved Successfully"),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  print('=== NAVIGATING BACK TO HOME ===');
                  print(
                      'MyAppState.customerProfile before navigation: ${MyAppState.customerProfile}');
                  Navigator.of(context).pop(); // Close dialog
                  // Use pushAndRemoveUntil to replace all screens and force refresh
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CustomerHomeScreen()),
                    (route) => false, // Remove all previous routes
                  );
                },
                child: const Text("OK"),
              ),
            ),
          ],
        );
      },
    );
  } else {
    setLoading(false);
    showAlertDialog(
      context,
      'Error : '.tr(),
      'Booking not saved. Contact support!'.tr(),
    );
  }
}

Future<void> deleteBookingAction(
  BuildContext context,
  bool isLoading,
  Function(bool) setLoading,
  dynamic booking, // Pass widget.booking here
) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cancel Booking'),
      content: const Text('Are you sure you want to cancel this booking?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Yes', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirm == true) {
    setLoading(true);

    bool success = true;
    if (booking != null) {
      success = await apiManager.deleteBooking(booking.pkey);
    }

    setLoading(false);

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
        (route) => false,
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Failed to cancel booking. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
