import 'package:flutter/material.dart';
import 'package:salonappweb/model/booking.dart';
import 'package:salonappweb/model/customer.dart';
import 'package:salonappweb/api/api_manager.dart';
import 'package:salonappweb/constants.dart';
import 'package:intl/intl.dart';
import 'package:salonappweb/services/helper.dart';
import 'summary.dart';
import 'package:provider/provider.dart';
import 'package:salonappweb/provider/booking.provider.dart';
import 'package:salonappweb/main.dart';
import 'customer_set_member.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:salonappweb/services/app_logger.dart';
import 'service.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen>
    with WidgetsBindingObserver {
  Customer? _currentCustomer;
  Future<List<Booking>> _bookingsFuture =
      Future.value([]); // Initialize with empty list
  bool _isLoadingProfile = true;
  Timer? _pollingTimer;
  bool _isPollingFetch = false;
  String? _lastBookingsFingerprint;
  bool _isPageActive = true; // Track if page is visible

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause polling when app is paused, resume when resumed
    if (state == AppLifecycleState.paused) {
      appLog('⏸ App paused - stopping bookings polling');
      _pollingTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      appLog('▶ App resumed - restarting bookings polling');
      if (_isPageActive) {
        _startPollingBookings();
      }
    }
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
      _startPollingBookings();
      appLog('=== _initializeData END (Token found) ===');
    } else {
      // No token, just mark loading as complete
      appLog('⚠ No customer token found, skipping bookings fetch');
      setState(() {
        _bookingsFuture = Future.value([]); // Empty list
        _isLoadingProfile = false;
      });
      // Still start polling for admin user if present
      _startPollingBookings();
      appLog('=== _initializeData END (No token) ===');
    }
  }

  void _startPollingBookings() {
    // Cancel existing if any
    _pollingTimer?.cancel();

    // Poll every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;
      if (_isPollingFetch) return; // avoid overlap
      _isPollingFetch = true;
      try {
        final prefs = await SharedPreferences.getInstance();
        final String? customerToken = prefs.getString('customer_token');

        List<Booking> latest = [];

        if (customerToken != null && customerToken.isNotEmpty) {
          // Customer logged in — use customer bookings API
          latest = await apiManager.ListBookingsSmart();
        } else {
          latest = [];
        }

        if (!mounted) return;

        // Compute fingerprint for displayed bookings (pkey:status pairs)
        List<Booking> displayed = latest;
        try {
          if (MyAppState.currentUser != null && _currentCustomer != null) {
            displayed = latest
                .where((b) =>
                    b.customerkey == _currentCustomer!.customerkey.toString())
                .toList();
          }
        } catch (_) {
          // ignore
        }

        final fingerprint = displayed
            .map((b) => '${b.pkey}:${b.status.replaceAll(',', '')}')
            .join('|');

        // Only update UI if fingerprint changed
        if (fingerprint != _lastBookingsFingerprint) {
          _lastBookingsFingerprint = fingerprint;
          setState(() {
            _bookingsFuture = Future.value(latest);
          });
        }
      } catch (e) {
        appLog('✗ Polling error: $e');
      } finally {
        _isPollingFetch = false;
      }
    });
  }

  Future<void> _refreshCustomerProfileFromCache() async {
    try {
      appLog('=== _refreshCustomerProfileFromCache START ===');
      final prefs = await SharedPreferences.getInstance();
      final cachedProfile = prefs.getString('cached_customer_profile');

      if (cachedProfile != null && cachedProfile.isNotEmpty) {
        final profileData = jsonDecode(cachedProfile) as Map<String, dynamic>;

        // Only update if the profile data is different from current
        if (_currentCustomer != null) {
          final currentFullname = _currentCustomer!.fullname;
          final newFullname = profileData['fullname'] ?? 'Unknown';

          if (currentFullname != newFullname) {
            appLog('✓ Cached profile has changed, refreshing UI');
            setState(() {
              if (profileData.containsKey('pkey') ||
                  profileData.containsKey('photobase64')) {
                _currentCustomer = Customer.fromJson(profileData);
              } else {
                _currentCustomer = Customer(
                  customerkey: profileData['customerkey'] ?? 0,
                  fullname: profileData['fullname'] ?? 'Guest',
                  email: profileData['email'] ?? '',
                  phone: profileData['phone'] ?? '',
                  photo: profileData['photo'] ?? '',
                  dob: profileData['dob'] ?? '',
                );
              }
            });
            MyAppState.customerProfile = profileData;
            appLog(
                '✓ Customer profile refreshed: ${_currentCustomer?.fullname}');
          }
        }
      }
      appLog('=== _refreshCustomerProfileFromCache END ===');
    } catch (e) {
      appLog('✗ Error refreshing customer profile from cache: $e');
    }
  }

  Future<void> _loadCustomerInfo() async {
    try {
      appLog('=== _loadCustomerInfo START ===');
      // appLog('MyAppState.customerProfile value: ${MyAppState.customerProfile}');

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

      // If API returned a profile, normalize and store it just like the
      // cached/preloaded branches above.
      if (profileData != null && profileData.isNotEmpty) {
        try {
          setState(() {
            if (profileData.containsKey('pkey') ||
                profileData.containsKey('photobase64')) {
              _currentCustomer = Customer.fromJson(profileData);
              appLog('✓ Created customer from API using fromJson');
            } else {
              _currentCustomer = Customer(
                customerkey: profileData['customerkey'] ?? 0,
                fullname: profileData['fullname'] ?? 'Guest',
                email: profileData['email'] ?? '',
                phone: profileData['phone'] ?? '',
                photo: profileData['photo'] ?? '',
                dob: profileData['dob'] ?? '',
              );
              appLog('✓ Created customer from API using direct mapping');
            }

            // Persist to shared global state for other screens
            MyAppState.customerProfile = profileData;
            appLog(
                'Customer from API: ${_currentCustomer?.fullname}, ${_currentCustomer?.email}, ${_currentCustomer?.phone}, DOB: ${_currentCustomer?.dob}');
          });

          // Set customer data in BookingProvider for booking flow (after
          // frame to avoid build conflicts)
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
              appLog('✓ Customer data set in BookingProvider (API)');
            } catch (e) {
              appLog('Could not set customer details in BookingProvider: $e');
            }
          });

          appLog('=== _loadCustomerInfo END (Admin) ===');
          return;
        } catch (e) {
          appLog('Error parsing profileData from API: $e');
          // fall through to no-data branch below
        }
      }

      appLog('✗ No admin user found either!');
      appLog('=== _loadCustomerInfo END (No Data) ===');
    } catch (e) {
      appLog('✗ Error loading customer info: $e');
      appLog('=== _loadCustomerInfo END (Error) ===');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This is called when the widget's dependencies change (e.g., during navigation)
    // Use ModalRoute to check if this page is the active route
    final isActive = ModalRoute.of(context)?.isCurrent ?? false;

    if (isActive && !_isPageActive) {
      // Page became active (user navigated back to home)
      appLog('📍 Home page is now active - starting polling');
      _isPageActive = true;
      _startPollingBookings();

      // Refresh customer profile from cache in case it was updated elsewhere
      _refreshCustomerProfileFromCache();
    } else if (!isActive && _isPageActive) {
      // Page became inactive (user navigated away)
      appLog('📍 Home page is no longer active - stopping polling');
      _isPageActive = false;
      _pollingTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    const color = Color(COLOR_PRIMARY);
    return Scaffold(
      // AppBar replaced by an inline header to match requested layout.
      body: Stack(
        children: [
          // Top header (replaces AppBar)
          SafeArea(
            child: Container(
              height: kToolbarHeight,
              color: color,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  // Home button on the top-left
                  TextButton.icon(
                    onPressed: () {
                      try {
                        html.window.open(
                            'https://www.greatyarmouthnails.com', '_blank');
                      } catch (e) {
                        appLog('Could not open external link: $e');
                      }
                    },
                    icon: const Icon(Icons.home, color: Colors.white),
                    label: const Text('Home',
                        style: TextStyle(color: Colors.white)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Spacer(),
                  // Top-right profile/menu
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _buildTopMenu(),
                  ),
                ],
              ),
            ),
          ),

          // Main page content sits below the header
          Padding(
            padding: const EdgeInsets.only(top: kToolbarHeight),
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  // reduce vertical padding to avoid large bottom gap
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  constraints: const BoxConstraints(maxWidth: 700),
                  // Use a Stack so the menu can be positioned relative to the centered container
                  child: Stack(
                    children: [
                      Column(
                        // align content to the top so it doesn't get vertically centered
                        // which causes a larger bottom gap when content is short
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _buildProfileSection(context, color),
                          const SizedBox(height: 32),
                          _buildBookingsSection(context, color),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // RESET booking for new bookings
          final bookingProvider =
              Provider.of<BookingProvider>(context, listen: false);
          bookingProvider.resetBooking();
          print('✓ Booking reset for new booking');

          // Set editMode to false for new booking
          bookingProvider.setEditMode(false);
          print('✏️ EditMode set to false for new booking');

          // Set customer details in BookingProvider before starting new booking
          if (_currentCustomer != null) {
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

          // Navigate to Service page (first step of booking flow for logged-in customers)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ServicePage()),
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
        padding: EdgeInsets.all(10.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        Text(
          'USA NAILs Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 16),
        // Profile Card with menu positioned at its top-right
        Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10.0),
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
                  // Name row (with menu aligned to the row)
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
                        Icon(Icons.person, size: 18, color: Colors.grey[700]),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _currentCustomer!.fullname,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[800]),
                          ),
                        ),
                      ],
                    ),
                  ),

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

                  // Date of Birth removed per request
                  const SizedBox.shrink(),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBookingsSection(BuildContext context, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Appointments',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
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
                padding: const EdgeInsets.all(10.0),
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

            // Also emit a single JSON-style log with full booking details
            try {
              // appLog('Booking list JSON: ${jsonEncode(snapshot.data)}');
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
              // customerBookings to be displayed
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
      //    appLog('Booking detail: ${booking.pkey}');
    } catch (e) {
      appLog('Could not log booking detail: $e');
    }

    final isPast = isBookingInPast(booking);
    final statusCategory =
        _statusCategoryFromStrings(booking.status, booking.note);
    final isCancelled = statusCategory == 'cancelled';
    // Treat cancelled bookings as archived (same styling as past bookings)
    final isArchived = isPast || isCancelled;

    // Decide whether to show actions based on status categories rather than
    // solely on whether the booking time is in the past. This makes the UI
    // responsive to backend status values like 'pending' or 'confirmed'.
    final allowedActionStatuses = <String>{
      'pending',
      'confirmed',
      'upcoming',
      'other'
    };
    final showActions = !isCancelled &&
        !isPast &&
        allowedActionStatuses.contains(statusCategory);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isArchived ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isArchived ? Colors.grey[300]! : color.withOpacity(0.3)),
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
                  color: isArchived ? Colors.grey[300] : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  // show cancel icon for cancelled bookings, check for past, otherwise schedule
                  isCancelled
                      ? Icons.cancel
                      : (isPast ? Icons.check_circle : Icons.schedule),
                  color: isCancelled
                      ? Colors.red
                      : (isArchived ? Colors.grey[600] : color),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    // Booking time moved above the status chip
                    Text(
                      '${formatBookingTime(booking.bookingtime)} : ${_formatDate(DateTime.parse(booking.bookingdate))}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isArchived ? Colors.grey[500] : Colors.grey[700],
                      ),
                    ),

                    const SizedBox(height: 4),
                    // Status chip moved below the time (left-aligned)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(builder: (ctx) {
                          final rawStatus = booking.status.trim();
                          final lower = rawStatus.toLowerCase();

                          Color statusColor;
                          String label;

                          // Prioritize explicit cancel markers in status or note
                          if (lower.contains('cancel') ||
                              booking.note.toLowerCase().contains('cancel')) {
                            statusColor = Colors.red;
                            label = 'Cancelled';
                          } else if (lower.contains('pending')) {
                            statusColor = Colors.red;
                            label =
                                rawStatus.isNotEmpty ? rawStatus : 'Pending';
                          } else if (lower.contains('confirm')) {
                            // If confirmed but booking time is in the past,
                            // present it as Completed (muted color)
                            if (isPast) {
                              statusColor = Colors.grey;
                              label = 'Completed';
                            } else {
                              statusColor = Colors.green[700]!;
                              label = rawStatus.isNotEmpty
                                  ? rawStatus
                                  : 'Confirmed';
                            }
                          } else if (lower.contains('complete') ||
                              lower.contains('done')) {
                            statusColor = Colors.grey;
                            label =
                                rawStatus.isNotEmpty ? rawStatus : 'Completed';
                          } else if (lower.contains('upcom') ||
                              lower == 'upcoming') {
                            statusColor = Colors.green[700]!;
                            label =
                                rawStatus.isNotEmpty ? rawStatus : 'Upcoming';
                          } else if (rawStatus.isEmpty) {
                            if (booking.note.toLowerCase().contains('cancel')) {
                              statusColor = Colors.red;
                              label = 'Cancelled';
                            } else if (isPast) {
                              statusColor = Colors.grey;
                              label = 'Completed';
                            } else {
                              statusColor = Colors.green[700]!;
                              label = 'Upcoming';
                            }
                          } else {
                            statusColor = Colors.blueGrey;
                            label = rawStatus;
                          }

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
                  ],
                ),
              ),
              if (showActions)
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
                          Icon(Icons.edit,
                              size: 20, color: Color(COLOR_PRIMARY)),
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
          if (showActions) ...[
            const SizedBox(height: 12),
            Builder(builder: (_) {
              // If pending: show only the Delete button.
              if (statusCategory == 'pending') {
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _handleCancelBooking(booking, context);
                        },
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Delete'),
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
                );
              }

              // If confirmed (or any other non-pending status): show both Change and Delete.
              return Row(
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
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete'),
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
              );
            }),
          ],
        ],
      ),
    );
  }

  void _handleChangeBooking(Booking booking, BuildContext context) {
    // Set editMode to true before navigating to edit booking
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    bookingProvider.setEditMode(true);
    print('✏️ EditMode set to true for editing existing booking');
    print('📝 Editing booking: ${booking.pkey}');

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
                  final result =
                      await apiManager.cancelCustomerBooking(booking.pkey);

                  // Check if widget is still mounted
                  if (!mounted) {
                    Navigator.of(context, rootNavigator: true).pop();
                    return;
                  }

                  // Close loading dialog
                  Navigator.of(context, rootNavigator: true).pop();

                  // Show result and refresh list
                  if (result['success'] == true) {
                    // Refresh the booking list first
                    setState(() {
                      _bookingsFuture = apiManager.ListBookingsSmart();
                    });

                    // Try to show success message
                    try {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['message']?.toString() ??
                              'Booking cancelled successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      appLog('Could not show success snackbar: $e');
                    }
                  } else {
                    final msg = result['message']?.toString() ??
                        'Failed to cancel booking. Please try again.';
                    try {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } catch (e) {
                      appLog('Could not show error snackbar: $e');
                    }
                  }
                } catch (e) {
                  // If API call itself threw, handle here
                  if (!mounted) {
                    Navigator.of(context, rootNavigator: true).pop();
                    return;
                  }

                  // Close loading dialog
                  Navigator.of(context, rootNavigator: true).pop();

                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } catch (e) {
                    appLog('Could not show error snackbar: $e');
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

  // Normalize backend status and notes into a simple category
  String _statusCategoryFromStrings(String status, String note) {
    final s = status.toLowerCase().trim();
    final n = note.toLowerCase();

    if (s.contains('cancel') || n.contains('cancel')) return 'cancelled';
    if (s.contains('pending')) return 'pending';
    if (s.contains('confirm')) return 'confirmed';
    if (s.contains('complete') || s.contains('done')) return 'completed';
    if (s.contains('upcom') || s.contains('upcoming')) return 'upcoming';
    return 'other';
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

  Widget _buildTopMenu() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.account_circle, size: 34, color: Colors.white),
      onSelected: (value) async {
        if (value == 'setmember') {
          try {
            if (_currentCustomer == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('No customer loaded'),
              ));
            } else {
              final updatedCustomer = await Navigator.push<Customer>(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CustomerSetMemberPage(customer: _currentCustomer!),
                ),
              );

              // If customer was updated in the Set Member page, refresh the profile
              if (updatedCustomer != null) {
                appLog('✓ Received updated customer from Set Member page');

                // Create the updated profile object
                final updatedProfile = {
                  'pkey': updatedCustomer.customerkey,
                  'customerkey': updatedCustomer.customerkey,
                  'fullname': updatedCustomer.fullname,
                  'email': updatedCustomer.email,
                  'phone': updatedCustomer.phone,
                  'photobase64': updatedCustomer.photo,
                  'birthday': updatedCustomer.dob,
                };

                // Update all caches and state
                setState(() {
                  _currentCustomer = updatedCustomer;
                });

                // Update the global MyAppState
                MyAppState.customerProfile = updatedProfile;

                // Update BookingProvider
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  try {
                    final bookingProvider =
                        Provider.of<BookingProvider>(context, listen: false);
                    bookingProvider.setCustomerDetails({
                      'pkey': updatedCustomer.customerkey,
                      'customerkey': updatedCustomer.customerkey,
                      'fullname': updatedCustomer.fullname,
                      'email': updatedCustomer.email,
                      'phone': updatedCustomer.phone,
                      'dob': updatedCustomer.dob,
                    });
                    appLog(
                        '✓ BookingProvider updated with new customer details');
                  } catch (e) {
                    appLog('Could not update BookingProvider: $e');
                  }
                });

                // Cache the updated profile to SharedPreferences
                try {
                  final prefs = await SharedPreferences.getInstance();
                  final encodedProfile = jsonEncode(updatedProfile);
                  await prefs.setString(
                      'cached_customer_profile', encodedProfile);
                  appLog(
                      '✓ Updated cached customer profile in SharedPreferences');
                  appLog(
                      'Updated profile: ${updatedCustomer.fullname}, ${updatedCustomer.email}, ${updatedCustomer.phone}');
                } catch (e) {
                  appLog('Could not cache updated profile: $e');
                }
              }
            }
          } catch (e) {
            appLog('Could not open Set Member: $e');
          }
        } else if (value == 'logout') {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('customer_token');
            await prefs.remove('cached_customer_profile');
            MyAppState.customerProfile = null;
            Navigator.pushReplacementNamed(context, '/home');
          } catch (e) {
            appLog('Logout failed: $e');
          }
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'setmember',
          child: Row(
            children: [
              Icon(Icons.group, size: 20, color: Color(COLOR_PRIMARY)),
              SizedBox(width: 8),
              Text('Set Member'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20, color: Colors.red),
              SizedBox(width: 8),
              Text('Logout'),
            ],
          ),
        ),
      ],
    );
  }
}
