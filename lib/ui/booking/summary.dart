import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salonappweb/api/api_manager.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:salonappweb/model/booking.dart';
import 'package:salonappweb/provider/booking.provider.dart';
import 'package:salonappweb/main.dart'; // For MyAppState

import 'home.dart';
import 'calendar.dart'; // ⬅️ Replace with actual path
import 'staff.dart'; // ⬅️ Replace with actual path
// ⬅️ Replace with actual path
import 'service.dart'; // ⬅️ Replace with actual path
import 'booking_actions.dart';

class SummaryPage extends StatefulWidget {
  final Booking? booking;

  const SummaryPage({super.key, this.booking});

  @override
  _SummaryPageState createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  bool isLoading = false;
  String note = '';

  late String customerKey;
  late String serviceKey;
  late String staffKey;
  late String bookingDate;
  late String bookingTime;
  late String customerName;
  late String staffName;
  late String serviceName;
  late int bookingkey;
  late String customerEmail;
  late String customerPhone;
  late TextEditingController noteController;

  @override
  void dispose() {
    // Don't call provider methods in dispose - causes "framework locked" error
    // Note is already saved via TextField onChanged callback
    noteController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    //print('bookingDetails: ${bookingProvider.bookingDetails}');

    // ✅ Set edit mode to true
    //  bookingProvider.setEditMode(true);
    // Schedule provider update after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<BookingProvider>(context, listen: false);
      provider.setEditMode(true);

      // Also set booking key and model after build if editing
      if (widget.booking != null) {
        provider.setBookingKey(bookingkey);
        provider.setBookingFromModel(widget.booking!);
      }
    });

    if (widget.booking != null) {
      print('widget');

      final booking = widget.booking!;
      // print('Booking from widget: ${booking.toJson()}');

      bookingkey = booking.pkey;
      customerKey = booking.customerkey;

      print('=== SUMMARY INIT - EDITING BOOKING ===');
      print('Initial customerKey from booking: $customerKey');
      print('BookingProvider.customer: ${bookingProvider.onbooking.customer}');
      print('MyAppState.customerProfile: ${MyAppState.customerProfile}');

      // Fix: If customerKey is "Unknown", get it from MyAppState or BookingProvider
      // Note: API returns 'pkey' field, not 'customerkey'
      if (customerKey == 'Unknown' || customerKey.isEmpty) {
        // Try MyAppState first (always loaded at app start)
        if (MyAppState.customerProfile != null) {
          // Check for 'pkey' first (from API), then 'customerkey' (normalized)
          final pkeyValue = MyAppState.customerProfile!['pkey'];
          final customerKeyValue = MyAppState.customerProfile!['customerkey'];

          if (pkeyValue != null) {
            customerKey = pkeyValue.toString();
            print('✓ Got customerKey from MyAppState.pkey: $customerKey');
          } else if (customerKeyValue != null) {
            customerKey = customerKeyValue.toString();
            print(
                '✓ Got customerKey from MyAppState.customerkey: $customerKey');
          }
        }
        // Fallback to BookingProvider
        else if (bookingProvider.onbooking.customer != null) {
          final pkeyValue = bookingProvider.onbooking.customer!['pkey'];
          final customerKeyValue =
              bookingProvider.onbooking.customer!['customerkey'];

          if (pkeyValue != null) {
            customerKey = pkeyValue.toString();
            print('✓ Got customerKey from BookingProvider.pkey: $customerKey');
          } else if (customerKeyValue != null) {
            customerKey = customerKeyValue.toString();
            print(
                '✓ Got customerKey from BookingProvider.customerkey: $customerKey');
          }
        }

        if (customerKey == 'Unknown' || customerKey.isEmpty) {
          print('✗ WARNING: customerKey is still Unknown/empty!');
        }
      }
      print('Final customerKey: $customerKey');
      print('====================================');

      serviceKey = booking.servicekey;
      staffKey = booking.staffkey;
      bookingDate = booking.bookingdate;
      bookingTime = DateFormat('HH:mm, dd/MM/yyyy').format(booking.bookingtime);
      customerName = booking.customername;
      staffName = booking.staffname;
      serviceName = booking.servicename;
      note = booking.note;

      print('=== SUMMARY INIT - GETTING EMAIL/PHONE ===');
      // Get email and phone from MyAppState first (always loaded), then BookingProvider
      if (MyAppState.customerProfile != null) {
        customerEmail = MyAppState.customerProfile!['email']?.toString() ?? '';
        customerPhone = MyAppState.customerProfile!['phone']?.toString() ?? '';
        print(
            '✓ Got email/phone from MyAppState: $customerEmail / $customerPhone');
      } else if (bookingProvider.onbooking.customer != null) {
        customerEmail =
            bookingProvider.onbooking.customer!['email']?.toString() ?? '';
        customerPhone =
            bookingProvider.onbooking.customer!['phone']?.toString() ?? '';
        print('✓ Got email/phone from BookingProvider');
      } else {
        customerEmail = ''; // Default for existing bookings
        customerPhone = ''; // Default for existing bookings
        print('⚠ No email/phone source available');
      }
      print('==========================================');

      // Moved to addPostFrameCallback to avoid setState during build
      // bookingProvider.setBookingKey(bookingkey);
      // bookingProvider.setBookingFromModel(booking);
    } else {
      print('bookingProvider');

      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      final bookingDetails = bookingProvider.bookingDetails;
      //   print('Booking : ${bookingDetails}');
      bookingkey = bookingDetails['bookingkey'] ?? 0;
      customerKey = bookingDetails['customerkey'] ?? '';
      serviceKey = bookingDetails['servicekey'] ?? '';
      staffKey = bookingDetails['staffkey'] ?? '';
      bookingDate = bookingDetails['date'] ?? '';
      bookingTime = bookingDetails['formattedschedule'] ?? '';
      customerName = bookingDetails['customername'] ?? 'Unknown';
      staffName = bookingDetails['staffname'] ?? 'Unknown';
      serviceName = bookingDetails['servicename'] ?? 'Unknown';
      note = bookingDetails['note'] ?? '';

      // For logged-in customers, get email/phone from customer details
      // For guest bookings, use guestemail/guestphone
      if (bookingDetails['guestemail'] != null &&
          bookingDetails['guestemail'].toString().isNotEmpty) {
        customerEmail = bookingDetails['guestemail'] ?? '';
        customerPhone = bookingDetails['guestphone'] ?? '';
      } else {
        // Use customer details from BookingProvider
        customerEmail = bookingProvider.onbooking.customer?['email'] ?? '';
        customerPhone = bookingProvider.onbooking.customer?['phone'] ?? '';
      }

      noteController = TextEditingController(text: note);
    }

    noteController = TextEditingController(text: note);
  }

  Future<void> _deleteBooking(BuildContext context) async {
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
      setState(() {
        isLoading = true;
      });

      bool success = true;
      // Only call API if this is an old booking (already saved)
      if (widget.booking != null) {
        // Use the booking's primary key or ID as required by your API
        success = await apiManager.deleteBooking(widget.booking!.pkey);
      }

      setState(() {
        isLoading = false;
      });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Summary Booking'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.white),
            tooltip: 'Cancel',
            onPressed: isLoading
                ? null
                : () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CustomerHomeScreen()),
                      (route) => false,
                    );
                  },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildInfoRow(
              context,
              label: 'Schedule',
              value:
                  '${_formatDate(bookingDate)} at ${_formatTime(bookingTime)}',
              icon: Icons.schedule,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BookingCalendarPage())),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              label: 'Staff',
              value: staffName,
              icon: Icons.people,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const StaffPage())),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              label: 'Service',
              value: serviceName,
              icon: Icons.star,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ServicePage())),
            ),
            const SizedBox(height: 12),
            const Text(
              'Note:',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: 'Enter any notes here...',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1),
                ),
              ),
              maxLines: 3,
              onChanged: (value) {
                note = value;
                Provider.of<BookingProvider>(context, listen: false)
                    .setNote(value);
              },
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          print('=== SUMMARY PAGE - BEFORE SAVE ===');
                          print('customerKey: $customerKey');
                          print('customerEmail: $customerEmail');
                          print('customerPhone: $customerPhone');
                          print('serviceKey: $serviceKey');
                          print('staffKey: $staffKey');
                          print('================================');

                          saveBooking(
                            context,
                            bookingkey,
                            (bool val) => setState(
                                () => isLoading = val), // <-- Accepts a bool
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
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Booking',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                ),
                const SizedBox(height: 12),
                if (widget.booking != null)
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => deleteBookingAction(
                              context,
                              isLoading,
                              (val) => setState(() => isLoading = val),
                              widget.booking,
                            ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context,
      {required String label,
      required String value,
      required IconData icon,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$label: $value',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('d MMMM').format(parsed); // e.g., 10 April
    } catch (e) {
      return date;
    }
  }

  String _formatTime(String time) {
    try {
      final parsed = DateFormat('HH:mm').parse(time);
      return DateFormat('HH:mm').format(parsed); // 24h format
    } catch (e) {
      return time;
    }
  }
}
