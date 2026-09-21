import 'package:flutter/material.dart';
import 'package:salonappweb/api/api_manager.dart';
import 'package:salonappweb/services/helper.dart';
import 'package:salonappweb/services/app_logger.dart';
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
  int numbooking,
) async {
  appLog('\n╔════════════════════════════════════════════════╗');
  appLog('║  🔄 SAVE BOOKING - SUBMITTING DATA TO API     ║');
  appLog('╚════════════════════════════════════════════════╝');
  appLog('📌 bookingKey: $bookingKey');
  appLog('─────────────────────────────────────────────────');
  appLog('👤 CUSTOMER:');
  appLog('   key: $customerKey');
  appLog('   name: $customerName');
  appLog('   email: $customerEmail');
  appLog('   phone: $customerPhone');
  appLog('─────────────────────────────────────────────────');
  appLog('👨‍💼 STAFF:');
  appLog('   key: $staffKey');
  appLog('   name: $staffName');
  appLog('─────────────────────────────────────────────────');
  appLog('💅 SERVICE:');
  appLog('   key: $serviceKey');
  appLog('   name: $serviceName');
  appLog('─────────────────────────────────────────────────');
  appLog('📅 SCHEDULE:');
  appLog('   date: $bookingDate');
  appLog('   time: $bookingTime');
  appLog('─────────────────────────────────────────────────');
  appLog('📝 NOTES: ${note.isEmpty ? "(empty)" : note}');
  appLog('👥 NUMBER PERSON: $numbooking');
  appLog('╚════════════════════════════════════════════════╝\n');

  setLoading(true);

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
    numbooking,
  );

  if (result != null) {
    appLog('\n╔════════════════════════════════════════════════╗');
    appLog('║     ✅ BOOKING SAVED SUCCESSFULLY             ║');
    appLog('╚════════════════════════════════════════════════╝');
    appLog('📌 Booking Key (Response): ${result.bookingkey}');
    appLog('🔑 Token: ${result.token}');
    appLog('👤 Customer Key: ${result.customerkey}');
    appLog('╚════════════════════════════════════════════════╝\n');
    try {
      appLog('SaveBooking response: ${jsonEncode(result.toJson())}');
    } catch (e) {
      appLog('Could not JSON-encode SaveBooking result: $e');
    }

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

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700], size: 28),
              const SizedBox(width: 10),
              const Text('Booking Submitted'),
            ],
          ),
          content: const Text(
            'Your booking request has been sent to the salon and is awaiting confirmation.',
            style: TextStyle(fontSize: 15, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const CustomerHomeScreen(),
      ),
      (route) => false,
    );

    // End of saveBooking
  }
}
