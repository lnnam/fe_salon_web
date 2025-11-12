import 'package:flutter/material.dart';
import 'package:salonappweb/api/api_manager.dart';
import 'package:salonappweb/services/helper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'home.dart';

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

  setLoading(false);

  if (result != null) {
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
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CustomerHomeScreen()),
                  );
                },
                child: const Text("OK"),
              ),
            ),
          ],
        );
      },
    );
    setLoading(false);
  } else {
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
