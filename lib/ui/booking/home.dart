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
import 'package:easy_localization/easy_localization.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  Customer? _currentCustomer;
  late Future<List<Booking>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _loadCustomerInfo();
    _bookingsFuture = apiManager.ListBookingsSmart();
  }

  Future<void> _loadCustomerInfo() async {
    try {
      print('=== _loadCustomerInfo START ===');

      // First check if customer profile was already loaded at app startup
      if (MyAppState.customerProfile != null) {
        print('✓ Using preloaded customer profile from MyAppState');
        final profileData = MyAppState.customerProfile!;
        setState(() {
          if (profileData.containsKey('pkey') ||
              profileData.containsKey('photobase64')) {
            _currentCustomer = Customer.fromJson(profileData);
            print('✓ Created customer using fromJson');
          } else {
            _currentCustomer = Customer(
              customerkey: profileData['customerkey'] ?? 0,
              fullname: profileData['fullname'] ?? 'Guest',
              email: profileData['email'] ?? '',
              phone: profileData['phone'] ?? '',
              photo: profileData['photo'] ?? '',
            );
            print('✓ Created customer using direct mapping');
          }
          print(
              'Customer: ${_currentCustomer?.fullname}, ${_currentCustomer?.email}, ${_currentCustomer?.phone}');
        });
        print('=== _loadCustomerInfo END (Preloaded) ===');
        return;
      }

      // If not preloaded, fetch from API
      final profileData = await apiManager.fetchCustomerProfile();

      if (profileData != null) {
        print('✓ Loaded customer profile from API: $profileData');
        setState(() {
          // Use Customer.fromJson if the backend sends pkey/photobase64
          // Otherwise map directly
          if (profileData.containsKey('pkey') ||
              profileData.containsKey('photobase64')) {
            _currentCustomer = Customer.fromJson(profileData);
            print('✓ Created customer using fromJson');
          } else {
            _currentCustomer = Customer(
              customerkey: profileData['customerkey'] ?? 0,
              fullname: profileData['fullname'] ?? 'Guest',
              email: profileData['email'] ?? '',
              phone: profileData['phone'] ?? '',
              photo: profileData['photo'] ?? '',
            );
            print('✓ Created customer using direct mapping');
          }
          print(
              'Customer: ${_currentCustomer?.fullname}, ${_currentCustomer?.email}, ${_currentCustomer?.phone}');
        });
        print('=== _loadCustomerInfo END (API) ===');
        return;
      }

      // Fallback to admin user
      print('No customer profile from API, checking admin user...');
      final user = MyAppState.currentUser;
      if (user != null) {
        print('✓ Loading customer info from admin user: ${user.username}');
        setState(() {
          _currentCustomer = Customer(
            customerkey: int.tryParse(user.userkey) ?? 0,
            fullname: user.username,
            email: user.email,
            phone: '',
            photo: user.profilephoto,
          );
        });
        print('=== _loadCustomerInfo END (Admin) ===');
      } else {
        print('✗ No admin user found either!');
        print('=== _loadCustomerInfo END (No Data) ===');
      }
    } catch (e) {
      print('✗ Error loading customer info: $e');
      print('=== _loadCustomerInfo END (Error) ===');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reset booking when home page loads
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    bookingProvider.resetBooking();

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
                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.red[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/logout');
                    },
                    icon: Icon(Icons.logout, color: Colors.red[400]),
                    label: Text(
                      'LOGOUT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[400],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
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
    if (_currentCustomer == null) {
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showEditProfileDialog(context);
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Profile'),
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
            print('=== BOOKINGS FUTURE BUILDER ===');
            print('Connection state: ${snapshot.connectionState}');
            print('Has error: ${snapshot.hasError}');
            print('Error: ${snapshot.error}');
            print('Has data: ${snapshot.hasData}');
            print('Data length: ${snapshot.data?.length}');

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              print('✗ Error loading bookings: ${snapshot.error}');
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
              print('✗ No bookings data');
              return _buildEmptyState();
            }

            print('✓ Received ${snapshot.data!.length} bookings');
            print(
                'Current customer key: ${_currentCustomer?.customerkey} (${_currentCustomer?.customerkey.runtimeType})');

            // Log all bookings
            for (var booking in snapshot.data!) {
              print(
                  'Booking: pkey=${booking.pkey}, customerkey=${booking.customerkey} (${booking.customerkey.runtimeType}), customer=${booking.customername}');
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
              print('Filtering bookings by customerkey (admin API)');
              customerBookings = snapshot.data!.where((booking) {
                final match = booking.customerkey ==
                    _currentCustomer!.customerkey.toString();
                print(
                    'Comparing: booking.customerkey="${booking.customerkey}" vs customer.customerkey="${_currentCustomer!.customerkey}" => $match');
                return match;
              }).toList();
            } else {
              // Customer API case: all bookings are already for this customer
              print(
                  'Using all bookings (already filtered by customer token API)');
              customerBookings = snapshot.data!;
            }

            print(
                '✓ Final result: ${customerBookings.length} bookings to display');

            if (customerBookings.isEmpty) {
              print('✗ No bookings match current customer');
              return _buildEmptyState();
            }

            // Sort bookings by date (newest first)
            customerBookings.sort((a, b) {
              final dateA = DateTime.parse(a.bookingdate);
              final dateB = DateTime.parse(b.bookingdate);
              return dateB.compareTo(dateA);
            });

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
                    Text(
                      booking.servicename,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isPast ? Colors.grey[600] : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(DateTime.parse(booking.bookingdate)),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                formatBookingTime(booking.bookingstart),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isPast ? Colors.grey[600] : Colors.black87,
                ),
              ),
            ],
          ),
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
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: const Text('Are you sure you want to cancel this booking?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement API call to cancel booking
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Booking cancelled successfully')),
                );
                setState(() {}); // Refresh the list
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

  void _showEditProfileDialog(BuildContext context) {
    final nameController =
        TextEditingController(text: _currentCustomer?.fullname);
    final emailController =
        TextEditingController(text: _currentCustomer?.email);
    final phoneController =
        TextEditingController(text: _currentCustomer?.phone);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
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
              onPressed: () {
                // TODO: Implement API call to update customer profile
                setState(() {
                  _currentCustomer = Customer(
                    customerkey: _currentCustomer!.customerkey,
                    fullname: nameController.text,
                    email: emailController.text,
                    phone: phoneController.text,
                    photo: _currentCustomer!.photo,
                  );
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully')),
                );
              },
              child: const Text('Save'),
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
