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

   /*  // Send booking confirmation email
    if (customerEmail.isNotEmpty) {
      print('=== SENDING CONFIRMATION EMAIL ===');
      final emailSent = await apiManager.sendBookingConfirmationEmail(
        bookingKey: result.bookingkey.toString(),
        customerEmail: customerEmail,
        customerName: customerName,
      );

      if (emailSent) {
        print('✓ Booking confirmation email sent to $customerEmail');
      } else {
        print('✗ Failed to send booking confirmation email');
      }
    } else {
      print('⚠ No customer email provided, skipping confirmation email');
    } */

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

    final dialogMessage = (result.message.isNotEmpty)
        ? result.message
        : 'Booking Saved Successfully';

    final dialogTitle = (result.status.isNotEmpty) ? result.status : 'Success';

    // Map status to color for the dialog accent
    Color statusColor;
    final lower = result.status.toLowerCase();
    if (lower.contains('pending')) {
      statusColor = Colors.red;
    } else if (lower.contains('confirm') || lower.contains('confirmed')) {
      statusColor = Colors.green[700]!;
    } else if (lower.contains('cancel')) {
      statusColor = Colors.red;
    } else if (lower.contains('complete') ||
        lower == 'completed' ||
        lower == 'done') {
      statusColor = Colors.grey;
    } else if (lower.contains('upcom') || lower == 'upcoming') {
      statusColor = Colors.green[700]!;
    } else if (result.status.isEmpty) {
      statusColor = Colors.green[700]!;
    } else {
      statusColor = Colors.blueGrey;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor.withOpacity(0.12),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.check_circle_outline,
                          color: statusColor, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dialogTitle,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  dialogMessage,
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
                const SizedBox(height: 12),
                if (result.bookingkey != 0) ...[
                  Text('Booking ref: ${result.bookingkey}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 6),
                ],
                // Token intentionally not shown in UI for privacy/security
                // Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      print('=== NAVIGATING BACK TO HOME ===');
                      print(
                          'MyAppState.customerProfile before navigation: ${MyAppState.customerProfile}');
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CustomerHomeScreen()),
                        (route) => false,
                      );
                    },
                    child: const Text('OK',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  } else {
    appLog('SaveBooking returned null (save failed)');
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
