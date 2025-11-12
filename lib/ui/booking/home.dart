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

  @override
  void initState() {
    super.initState();
    _loadCustomerInfo();
  }

  Future<void> _loadCustomerInfo() async {
    // Load customer info from current user
    final user = MyAppState.currentUser;
    if (user != null) {
      // In a real scenario, fetch customer details from API
      // For now, create a temporary customer from user data
      setState(() {
        _currentCustomer = Customer(
          customerkey: int.tryParse(user.userkey) ?? 0,
          fullname: user.username,
          email: user.email,
          phone: '', // Would come from API
          photo: user.profilephoto,
        );
      });
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
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
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

    ImageProvider imageProvider;
    try {
      imageProvider = getImage(_currentCustomer!.photo) ??
          const AssetImage('assets/default_avatar.png');
    } catch (e) {
      imageProvider = const AssetImage('assets/default_avatar.png');
    }

    return Column(
      children: [
        // Title
        const Text(
          'My Profile',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 24),
        // Profile Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
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
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: imageProvider,
                child: imageProvider is AssetImage
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                _currentCustomer!.fullname,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Email
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email, size: 20, color: Colors.grey[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _currentCustomer!.email,
                        style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Phone
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.phone, size: 20, color: Colors.grey[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _currentCustomer!.phone.isEmpty ? 'No phone number' : _currentCustomer!.phone,
                        style: TextStyle(
                          fontSize: 16, 
                          color: _currentCustomer!.phone.isEmpty ? Colors.grey[400] : Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showEditProfileDialog(context);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
          future: apiManager.ListBooking(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            // Filter bookings for current customer
            final customerBookings = snapshot.data!.where((booking) {
              return _currentCustomer != null &&
                  booking.customerkey == _currentCustomer!.customerkey;
            }).toList();

            if (customerBookings.isEmpty) {
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
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w600),
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
        border: Border.all(color: isPast ? Colors.grey[300]! : color.withOpacity(0.3)),
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
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SummaryPage(booking: booking),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: color),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'View Details',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
                  const SnackBar(content: Text('Booking cancelled successfully')),
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
    final nameController = TextEditingController(text: _currentCustomer?.fullname);
    final emailController = TextEditingController(text: _currentCustomer?.email);
    final phoneController = TextEditingController(text: _currentCustomer?.phone);

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
