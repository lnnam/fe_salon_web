import 'package:flutter/material.dart';
import 'package:salonapp/model/booking.dart';
import 'package:salonapp/api/api_manager.dart';
import 'package:salonapp/constants.dart';
import 'package:intl/intl.dart';
import 'package:salonapp/ui/common/drawer_booking.dart';
import 'package:salonapp/ui/booking/staff.dart';
import 'package:salonapp/services/helper.dart';
import 'summary.dart'; // Import Home
import 'package:provider/provider.dart';
import 'package:salonapp/provider/booking.provider.dart';
import 'package:salonapp/services/helper.dart';

class BookingHomeScreen extends StatelessWidget {
  const BookingHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Set editMode to false when home page loads
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    //bookingProvider.onbooking.editMode = false;
    bookingProvider.resetBooking();
    print('editMode is now: ${bookingProvider.onbooking.editMode}');

    const color = Color(COLOR_PRIMARY);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment', style: TextStyle(color: Colors.white)),
        backgroundColor: color,
      ),
      drawer: const AppDrawerBooking(),
      body: FutureBuilder<List<Booking>>(
        future: apiManager.ListBooking(),
        builder: (context, snapshot) {
          print('Calling ListBooking...');
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            print('No data or empty list: ${snapshot.data}');
            return const Center(child: Text('No bookings available.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No bookings available.'));
          } else {
            final groupedBookings = _groupBookingsByDate(snapshot.data!);
            final sortedDates = groupedBookings.keys.toList();
            sortedDates.sort((a, b) => a.compareTo(b));

            return ListView.builder(
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                final bookings = groupedBookings[date]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      color: color.withOpacity(0.2),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      child: Text(
                        _formatDate(date),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    Column(
                      children: bookings.map((booking) {
                        ImageProvider imageProvider;
                        try {
                          imageProvider = getImage(booking.customerphoto) ??
                              const AssetImage('assets/default_avatar.png');
                        } catch (e) {
                          print('Error loading image: $e');
                          imageProvider =
                              const AssetImage('assets/default_avatar.png');
                        }
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          elevation: 4.0,
                          color: isBookingInPast(booking)
                              ? Colors.grey[300]
                              : Colors.white, // <-- Highlight past
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16.0),
                            leading: CircleAvatar(
                              backgroundImage: imageProvider,
                              child: imageProvider is AssetImage
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(
                              '${formatBookingTime(booking.bookingstart)}: ${booking.customername}, ${booking.servicename}, Staff: ${booking.staffname} (10)',
                              style: TextStyle(
                                color: isBookingInPast(booking)
                                    ? Colors.grey
                                    : color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Scheduled: ${_formatDateTime(booking.created_datetime)}',
                              style: TextStyle(
                                color: isBookingInPast(booking)
                                    ? Colors.grey
                                    : color,
                              ),
                            ),
                            onTap: () {
                              // Handle onTap event
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SummaryPage(
                                      booking: booking), // 👈 Pass booking
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StaffPage()),
          );
        },
        backgroundColor: color,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Find',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_week),
            label: 'Week',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Log',
          ),
        ],
        selectedItemColor: color,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
  }

  static Map<DateTime, List<Booking>> _groupBookingsByDate(
      List<Booking> bookings) {
    Map<DateTime, List<Booking>> groupedBookings = {};
    for (var booking in bookings) {
      final date = DateTime.parse(booking.bookingdate);
      if (groupedBookings.containsKey(date)) {
        groupedBookings[date]!.add(booking);
      } else {
        groupedBookings[date] = [booking];
      }
    }
    return groupedBookings;
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
