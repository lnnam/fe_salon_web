import 'package:flutter/material.dart';
import 'package:salonappweb/model/booking.dart';
import 'package:salonappweb/model/customer.dart';
import 'package:salonappweb/api/api_manager.dart';
import 'package:salonappweb/constants.dart';
import 'package:intl/intl.dart';
import 'package:salonappweb/ui/booking/staff.dart';
import 'package:salonappweb/services/helper.dart';
import 'summary.dart';
import 'package:provider/provider.dart';
import 'package:salonappweb/provider/booking.provider.dart';
import 'package:salonappweb/main.dart';
import 'customer_set_member.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:salonappweb/services/app_logger.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  Customer? _currentCustomer;
  Future<List<Booking>> _bookingsFuture =
      Future.value([]); // Initialize with empty list
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    appLog('=== _initializeData START ===');

    // Load customer info first
    await _loadCustomerInfo();

    // Check if we have a customer token before trying to load bookings
    final prefs = await SharedPreferences.getInstance();
    final customerToken = prefs.getString('customer_token');

    appLog(
        'Customer token after _loadCustomerInfo: ${customerToken != null && customerToken.isNotEmpty ? "EXISTS" : "MISSING"}');
    appLog(
        'Current customer after _loadCustomerInfo: ${_currentCustomer?.fullname}');

    if (customerToken != null && customerToken.isNotEmpty) {
      // Then load bookings after customer profile is loaded
      appLog('✓ Customer token found, loading bookings...');
      setState(() {
        _bookingsFuture = apiManager.ListBookingsSmart();
        _isLoadingProfile = false;
      });
      appLog('=== _initializeData END (Token found) ===');
    } else {
      // No token, just mark loading as complete
      appLog('⚠ No customer token found, skipping bookings fetch');
      setState(() {
        _bookingsFuture = Future.value([]); // Empty list
        _isLoadingProfile = false;
      });
      appLog('=== _initializeData END (No token) ===');
    }
  }

  Future<void> _loadCustomerInfo() async {
    try {
      appLog('=== _loadCustomerInfo START ===');
      appLog('MyAppState.customerProfile value: ${MyAppState.customerProfile}');

      // First check if customer profile was already loaded at app startup
      if (MyAppState.customerProfile != null) {
        appLog('✓ Using preloaded customer profile from MyAppState');
        final profileData = MyAppState.customerProfile!;
        setState(() {
          if (profileData.containsKey('pkey') ||
              profileData.containsKey('photobase64')) {
            _currentCustomer = Customer.fromJson(profileData);
            appLog('✓ Created customer using fromJson');
          } else {
            _currentCustomer = Customer(
              customerkey: profileData['customerkey'] ?? 0,
              fullname: profileData['fullname'] ?? 'Guest',
              email: profileData['email'] ?? '',
              phone: profileData['phone'] ?? '',
              photo: profileData['photo'] ?? '',
              dob: profileData['dob'] ?? '',
            );
            appLog('✓ Created customer using direct mapping');
          }
          appLog(
              'Customer: ${_currentCustomer?.fullname}, ${_currentCustomer?.email}, ${_currentCustomer?.phone}, DOB: ${_currentCustomer?.dob}');
        });

        // Set customer data in BookingProvider for booking flow (after frame to avoid build conflict)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
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
            appLog('✓ Customer data set in BookingProvider (preloaded)');
          } catch (e) {
            print('Could not set customer details in BookingProvider: $e');
          }
        });

        appLog('=== _loadCustomerInfo END (Preloaded) ===');
        return;
      }

      // If not in MyAppState, try to restore from SharedPreferences cache
      final prefs = await SharedPreferences.getInstance();
      final cachedProfile = prefs.getString('cached_customer_profile');
      final customerToken = prefs.getString('customer_token');

      appLog('=== CHECKING SHARED PREFERENCES ===');
      appLog(
          'cached_customer_profile exists: ${cachedProfile != null && cachedProfile.isNotEmpty}');
      appLog(
          'customer_token exists: ${customerToken != null && customerToken.isNotEmpty}');
      if (customerToken != null) {
        appLog('customer_token value: ${customerToken.substring(0, 20)}...');
      }
      appLog('===================================');

      if (cachedProfile != null && cachedProfile.isNotEmpty) {
        try {
          appLog('✓ Found cached customer profile in SharedPreferences');
          final profileData = jsonDecode(cachedProfile) as Map<String, dynamic>;
          setState(() {
            if (profileData.containsKey('pkey') ||
                profileData.containsKey('photobase64')) {
              _currentCustomer = Customer.fromJson(profileData);
              appLog('✓ Created customer from cached profile using fromJson');
            } else {
              _currentCustomer = Customer(
                customerkey: profileData['customerkey'] ?? 0,
                fullname: profileData['fullname'] ?? 'Guest',
                email: profileData['email'] ?? '',
                phone: profileData['phone'] ?? '',
                photo: profileData['photo'] ?? '',
                dob: profileData['dob'] ?? '',
              );
              appLog(
                  '✓ Created customer from cached profile using direct mapping');
            }
            // Restore to MyAppState for other screens
            MyAppState.customerProfile = profileData;
            appLog(
                'Customer from cache: ${_currentCustomer?.fullname}, ${_currentCustomer?.email}, ${_currentCustomer?.phone}, DOB: ${_currentCustomer?.dob}');
          });

          // Set customer data in BookingProvider for booking flow (after frame to avoid build conflict)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              final bookingProvider =
                  Provider.of<BookingProvider>(context, listen: false);
              bookingProvider.setCustomerDetails({
                'pkey': profileData['pkey'] ?? profileData['customerkey'],
                'customerkey':
                    profileData['pkey'] ?? profileData['customerkey'],
                'fullname': profileData['fullname'] ?? 'Guest',
                'email': profileData['email'] ?? '',
                'phone': profileData['phone'] ?? '',
                'dob': profileData['dob'] ?? '',
              });
              appLog('✓ Customer data set in BookingProvider (cached)');
            } catch (e) {
              appLog('Could not set customer details in BookingProvider: $e');
            }
          });

          appLog('=== _loadCustomerInfo END (Cached) ===');
          return;
        } catch (e) {
          print('Error parsing cached profile: $e');
          // Continue to API fetch if cache parsing fails
        }
      }

      // If not preloaded and not cached, fetch from API
      final profileData = await apiManager.fetchCustomerProfile();

      if (profileData != null) {
        appLog('✓ Loaded customer profile from API: $profileData');

        // Store in SharedPreferences cache for persistence
        await prefs.setString(
            'cached_customer_profile', jsonEncode(profileData));
        appLog('✓ Customer profile cached in SharedPreferences');

        setState(() {
          // Use Customer.fromJson if the backend sends pkey/photobase64
          // Otherwise map directly
          if (profileData.containsKey('pkey') ||
              profileData.containsKey('photobase64')) {
            _currentCustomer = Customer.fromJson(profileData);
            appLog('✓ Created customer using fromJson');
          } else {
            _currentCustomer = Customer(
              customerkey: profileData['customerkey'] ?? 0,
              fullname: profileData['fullname'] ?? 'Guest',
              email: profileData['email'] ?? '',
              phone: profileData['phone'] ?? '',
              photo: profileData['photo'] ?? '',
              dob: profileData['dob'] ?? '',
            );
            appLog('✓ Created customer using direct mapping');
          }
          // Store in MyAppState for other screens
          MyAppState.customerProfile = profileData;
          appLog(
              'Customer: ${_currentCustomer?.fullname}, ${_currentCustomer?.email}, ${_currentCustomer?.phone}, DOB: ${_currentCustomer?.dob}');
        });

        // Set customer data in BookingProvider for booking flow (after frame to avoid build conflict)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
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
            appLog('✓ Customer data set in BookingProvider (API fetch)');
          } catch (e) {
            appLog('Could not set customer details in BookingProvider: $e');
          }
        });

        appLog('=== _loadCustomerInfo END (API) ===');
        return;
      }

      // Fallback to admin user
      appLog('No customer profile from API, checking admin user...');
      final user = MyAppState.currentUser;
      if (user != null) {
        appLog('✓ Loading customer info from admin user: ${user.username}');
        setState(() {
          _currentCustomer = Customer(
            customerkey: int.tryParse(user.userkey) ?? 0,
            fullname: user.username,
            email: user.email,
            phone: '',
            photo: user.profilephoto,
            dob: '',
          );
        });
        appLog('=== _loadCustomerInfo END (Admin) ===');
      } else {
        appLog('✗ No admin user found either!');
        appLog('=== _loadCustomerInfo END (No Data) ===');
      }
    } catch (e) {
      appLog('✗ Error loading customer info: $e');
      appLog('=== _loadCustomerInfo END (Error) ===');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reset booking when home page loads (after frame to avoid build conflict)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final bookingProvider =
            Provider.of<BookingProvider>(context, listen: false);
        bookingProvider.resetBooking();
      } catch (e) {
        appLog('Could not reset booking: $e');
      }
    });

    const color = Color(COLOR_PRIMARY);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildProfileSection(context, color),
                const SizedBox(height: 32),
                _buildBookingsSection(context, color),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Set customer details in BookingProvider before starting new booking
          if (_currentCustomer != null) {
            final bookingProvider =
                Provider.of<BookingProvider>(context, listen: false);
            bookingProvider.setCustomerDetails({
              'pkey': _currentCustomer!.customerkey,
              'customerkey': _currentCustomer!.customerkey,
              'fullname': _currentCustomer!.fullname,
              'email': _currentCustomer!.email,
              'phone': _currentCustomer!.phone,
            });
            print(
                '✓ Customer details set in BookingProvider: ${_currentCustomer!.fullname}');
          }

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StaffPage()),
          );
        },
        backgroundColor: color,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Booking', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, Color color) {
    if (_isLoadingProfile || _currentCustomer == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        // Title
        const Text(
          'My Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 12),
        // Profile Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                _currentCustomer!.fullname,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Email
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email, size: 18, color: Colors.grey[700]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _currentCustomer!.email,
                        style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Phone
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.phone, size: 18, color: Colors.grey[700]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _currentCustomer!.phone.isEmpty
                            ? 'No phone number'
                            : _currentCustomer!.phone,
                        style: TextStyle(
                          fontSize: 14,
                          color: _currentCustomer!.phone.isEmpty
                              ? Colors.grey[400]
                              : Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Date of Birth
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cake, size: 18, color: Colors.grey[700]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _currentCustomer!.dob.isEmpty
                            ? 'No date of birth'
                            : _currentCustomer!.dob,
                        style: TextStyle(
                          fontSize: 14,
                          color: _currentCustomer!.dob.isEmpty
                              ? Colors.grey[400]
                              : Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push<Customer?>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CustomerSetMemberPage(
                                customer: _currentCustomer!),
                          ),
                        );

                        if (result != null) {
                          setState(() {
                            _currentCustomer = result;
                          });

                          try {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Member account updated'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            appLog(
                                'Could not show snackbar after Set Member: $e');
                          }
                        }
                      },
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Set Member'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/logout');
                      },
                      icon:
                          Icon(Icons.logout, size: 16, color: Colors.red[400]),
                      label: Text(
                        'Logout',
                        style: TextStyle(color: Colors.red[400]),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(color: Colors.red[400]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsSection(BuildContext context, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Appointments',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Booking>>(
          future: _bookingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              appLog('✗ Error loading bookings: ${snapshot.error}');
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _bookingsFuture = apiManager.ListBookingsSmart();
                          });
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              appLog('✗ No bookings data');
              return _buildEmptyState();
            }

            // Log all bookings (individual short lines)
            for (var booking in snapshot.data!) {
              appLog(
                  'Booking: pkey=${booking.pkey}, customerkey=${booking.customerkey} (${booking.customerkey.runtimeType}), customer=${booking.customername}');
            }

            // Also emit a single JSON-style log with full booking details
            try {
              final detailed = snapshot.data!
                  .map((b) => {
                        'pkey': b.pkey,
                        'customerkey': b.customerkey,
                        'customername': b.customername,
                        'staffname': b.staffname,
                        'servicename': b.servicename,
                        'bookingdate': b.bookingdate,
                        'bookingstart': b.bookingstart.toIso8601String(),
                        'created_datetime':
                            b.created_datetime.toIso8601String(),
                        'note': b.note,
                        'status': b.status,
                      })
                  .toList();

              appLog('Booking list JSON: ${jsonEncode(detailed)}');
            } catch (e) {
              appLog('Could not serialize bookings for JSON log: $e');
            }

            // When using customer token API, bookings are already filtered by backend
            // No need to filter again - just use all returned bookings
            List<Booking> customerBookings;

            // Check if we need to filter (admin API returns all bookings)
            // If customerkey is "Unknown", it means customer API already filtered
            final needsFiltering =
                snapshot.data!.any((b) => b.customerkey != 'Unknown');

            if (needsFiltering && _currentCustomer != null) {
              // Admin API case: filter by customerkey
              appLog('Filtering bookings by customerkey (admin API)');
              customerBookings = snapshot.data!.where((booking) {
                final match = booking.customerkey ==
                    _currentCustomer!.customerkey.toString();
                appLog(
                    'Comparing: booking.customerkey="${booking.customerkey}" vs customer.customerkey="${_currentCustomer!.customerkey}" => $match');
                return match;
              }).toList();
            } else {
              // Customer API case: all bookings are already for this customer
              appLog(
                  'Using all bookings (already filtered by customer token API)');
              customerBookings = snapshot.data!;
            }

            appLog(
                '✓ Final result: ${customerBookings.length} bookings to display');

            if (customerBookings.isEmpty) {
              appLog('✗ No bookings match current customer');
              return _buildEmptyState();
            }

            // Sort bookings by date (newest first)
            customerBookings.sort((a, b) {
              final dateA = DateTime.parse(a.bookingdate);
              final dateB = DateTime.parse(b.bookingdate);
              return dateB.compareTo(dateA);
            });

            // Log only the bookings we will display for the current customer
            try {
              final customerKey = _currentCustomer != null
                  ? _currentCustomer!.customerkey.toString()
                  : 'guest';
              final custJson = customerBookings
                  .map((b) => {
                        'pkey': b.pkey,
                        'customerkey': b.customerkey,
                        'customername': b.customername,
                        'servicename': b.servicename,
                        'staffname': b.staffname,
                        'bookingdate': b.bookingdate,
                        'bookingstart': b.bookingstart.toIso8601String(),
                        'note': b.note,
                      })
                  .toList();
              appLog(
                  'Customer ($customerKey) bookings: ${jsonEncode(custJson)}');
            } catch (e) {
              appLog('Could not serialize customer bookings: $e');
            }

            return Column(
              children: customerBookings.map((booking) {
                return _buildBookingCard(booking, color, context);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No bookings yet',
            style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to create your first booking',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking, Color color, BuildContext context) {
    // Debug: log full booking data for inspection
    try {
      final b = {
        'pkey': booking.pkey,
        'customerkey': booking.customerkey,
        'customername': booking.customername,
        'staffname': booking.staffname,
        'servicename': booking.servicename,
        'bookingdate': booking.bookingdate,
        'bookingstart': booking.bookingstart.toIso8601String(),
        'bookingtime': booking.bookingtime.toIso8601String(),
        'created_datetime': booking.created_datetime.toIso8601String(),
        'note': booking.note,
        'status': booking.status,
      };
    //  appLog('Booking detail: ${jsonEncode(b)}');
    } catch (e) {
      appLog('Could not log booking detail: $e');
    }

    final isPast = isBookingInPast(booking);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPast ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isPast ? Colors.grey[300]! : color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPast ? Colors.grey[300] : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPast ? Icons.check_circle : Icons.schedule,
                  color: isPast ? Colors.grey[600] : color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            booking.servicename == 'N/A' ||
                                    booking.servicename == 'Unknown' ||
                                    booking.servicename == 'null' ||
                                    booking.servicename.isEmpty
                                ? 'Service Booking'
                                : booking.servicename,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isPast ? Colors.grey[600] : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Booking status chip — show backend status text verbatim when available
                        Builder(builder: (ctx) {
                          final rawStatus = booking.status.trim();
                          final lower = rawStatus.toLowerCase();

                          // Decide color using simple keyword matching, but
                          // display the backend text exactly as returned when present.
                          Color statusColor;
                          if (lower.contains('pending')) {
                            // Backend 'pending' -> red
                            statusColor = Colors.red;
                          } else if (lower.contains('confirm') ||
                              lower.contains('confirmed')) {
                            // Backend 'confirm'/'confirmed' -> green (confirmed)
                            statusColor = Colors.green[700]!;
                          } else if (lower.contains('cancel')) {
                            // cancelled stays red (explicit cancellation)
                            statusColor = Colors.red;
                          } else if (lower.contains('complete') ||
                              lower == 'completed' ||
                              lower == 'done') {
                            statusColor = Colors.grey;
                          } else if (lower.contains('upcom') ||
                              lower == 'upcoming') {
                            statusColor = Colors.green[700]!;
                          } else if (rawStatus.isEmpty) {
                            // No backend status — fallback to note/isPast
                            final note = booking.note.toLowerCase();
                            if (note.contains('cancel')) {
                              statusColor = Colors.red;
                            } else if (isPast) {
                              statusColor = Colors.grey;
                            } else {
                              statusColor = Colors.green[700]!;
                            }
                          } else {
                            // Unknown backend status text: use neutral color
                            statusColor = Colors.blueGrey;
                          }

                          final label = rawStatus.isNotEmpty
                              ? rawStatus
                              : (booking.note.toLowerCase().contains('cancel')
                                  ? 'Cancelled'
                                  : (isPast ? 'Completed' : 'Upcoming'));

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: statusColor.withOpacity(0.2)),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatBookingTime(booking.bookingtime)} : ${_formatDate(DateTime.parse(booking.bookingdate))}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isPast ? Colors.grey[500] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isPast)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                  onSelected: (value) {
                    if (value == 'change') {
                      _handleChangeBooking(booking, context);
                    } else if (value == 'cancel') {
                      _handleCancelBooking(booking, context);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'change',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Change'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'cancel',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Cancel'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Staff: ${booking.staffname}',
                style: TextStyle(
                  fontSize: 14,
                  color: isPast ? Colors.grey[600] : Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.spa, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Service: ${booking.servicename == 'N/A' || booking.servicename == 'Unknown' || booking.servicename == 'null' || booking.servicename.isEmpty ? 'Not specified' : booking.servicename}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isPast ? Colors.grey[600] : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_month, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Scheduled: ${_formatDateTime(booking.created_datetime)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          if (!isPast) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _handleChangeBooking(booking, context);
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Change'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: color),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _handleCancelBooking(booking, context);
                    },
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _handleChangeBooking(Booking booking, BuildContext context) {
    // Navigate to edit booking
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SummaryPage(booking: booking),
      ),
    );
  }

  void _handleCancelBooking(Booking booking, BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: const Text('Are you sure you want to cancel this booking?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Close confirmation dialog
                Navigator.pop(dialogContext);

                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (loadingContext) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  // Call API to cancel booking
                  final success =
                      await apiManager.cancelCustomerBooking(booking.pkey);

                  // Check if widget is still mounted
                  if (!mounted) {
                    Navigator.of(context, rootNavigator: true).pop();
                    return;
                  }

                  // Close loading dialog
                  Navigator.of(context, rootNavigator: true).pop();

                  // Show result and refresh list
                  if (success) {
                    // Refresh the booking list first
                    setState(() {
                      _bookingsFuture = apiManager.ListBookingsSmart();
                    });

                    // Try to show success message
                    try {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Booking cancelled successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      appLog('Could not show success snackbar: $e');
                    }
                  } else {
                    try {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Failed to cancel booking. Please try again.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } catch (e) {
                      appLog('Could not show error snackbar: $e');
                    }
                  }
                } catch (e) {
                  if (!mounted) {
                    Navigator.of(context, rootNavigator: true).pop();
                    return;
                  }

                  // Close loading dialog
                  Navigator.of(context, rootNavigator: true).pop();

                  // Try to show error
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } catch (e) {
                    print('Could not show error snackbar: $e');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('EEEE, d MMMM yyyy').format(dateTime);
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm, EEEE, d MMMM').format(dateTime);
  }

  bool isBookingInPast(Booking booking) {
    final date = DateTime.parse(booking.bookingdate);
    final bookingDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      booking.bookingtime.hour,
      booking.bookingtime.minute,
    );
    return bookingDateTime.isBefore(DateTime.now());
  }
}
