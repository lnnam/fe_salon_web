import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salonappweb/provider/booking.provider.dart';
import 'package:booking_calendar/booking_calendar.dart';
import 'package:salonappweb/constants.dart';
// Import SchedulePage
import 'summary.dart';
import 'package:salonappweb/api/api_manager.dart';

class BookingCalendarPage extends StatefulWidget {
  const BookingCalendarPage({super.key});

  @override
  _BookingCalendarPageState createState() => _BookingCalendarPageState();
}

class _BookingCalendarPageState extends State<BookingCalendarPage> {
  late BookingService mockBookingService;
  final now = DateTime.now();
  List<DateTimeRange> converted = [];

  @override
  void initState() {
    super.initState();
    mockBookingService = BookingService(
        serviceName: 'Mock Service',
        serviceDuration: 15,
        bookingEnd: DateTime(now.year, now.month, now.day, 18, 0),
        bookingStart: DateTime(now.year, now.month, now.day, 9, 0));
  }

  Stream<dynamic>? getBookingStreamMock(
      {required DateTime end, required DateTime start}) {
    return Stream.value([]);
  }

  Future<dynamic> uploadBookingMock(
      {required BookingService newBooking}) async {
    await Future.delayed(const Duration(seconds: 1));
    converted.add(DateTimeRange(
        start: newBooking.bookingStart, end: newBooking.bookingEnd));

    // Debug: Print what's in the booking
    print('=== CALENDAR BOOKING DATA ===');
    print('Booking Start: ${newBooking.bookingStart}');
    print('Booking End: ${newBooking.bookingEnd}');
    print('Service Name: ${newBooking.serviceName}');
    print('Service Duration: ${newBooking.serviceDuration}');
    print('toJson: ${newBooking.toJson()}');
    print('============================');

    // Create properly formatted schedule data with correct key
    final scheduleData = {
      'bookingStart': newBooking.bookingStart.toIso8601String(),
      'bookingEnd': newBooking.bookingEnd.toIso8601String(),
      'serviceName': newBooking.serviceName,
      'serviceDuration': newBooking.serviceDuration,
    };

    print('Formatted schedule data: $scheduleData');

    Provider.of<BookingProvider>(context, listen: false)
        .setSchedule(scheduleData);

    // Navigate to Summary page always
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SummaryPage()),
    );
  } /* List<DateTimeRange> convertStreamResultMock({required dynamic streamResult}) {
  return (streamResult as List)
      .map((item) => DateTimeRange(
            start: DateTime.parse(item['bookingstart']),
            end: DateTime.parse(item['bookingend']),
          ))
      .toList();
} */

  List<DateTimeRange> convertStreamResultMock({required dynamic streamResult}) {
    List<DateTimeRange> converted = [];

    if (streamResult is List) {
      for (var item in streamResult) {
        if (item is Map && item['available'] == false) {
          // Parse the busy slot into DateTimeRange
          final now = DateTime.now();
          final timeParts = (item['slot_time'] as String).split(':');
          final start = DateTime(
            now.year,
            now.month,
            now.day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );
          // assume each slot is 45 min service
          final end = start.add(const Duration(minutes: 45));
          converted.add(DateTimeRange(start: start, end: end));
        }
      }
    }

    return converted;
  }

  /*List<DateTimeRange> convertStreamResultMock({required dynamic streamResult}) {
    DateTime first = now;
    DateTime tomorrow = now.add(const Duration(days: 1));
    DateTime second = now.add(const Duration(minutes: 55));
    DateTime third = now.subtract(const Duration(minutes: 240));
    DateTime fourth = now.subtract(const Duration(minutes: 500));
    converted.add(
        DateTimeRange(start: first, end: now.add(const Duration(minutes: 30))));
    converted.add(DateTimeRange(
        start: second, end: second.add(const Duration(minutes: 23))));
    converted.add(DateTimeRange(
        start: third, end: third.add(const Duration(minutes: 15))));
    converted.add(DateTimeRange(
        start: fourth, end: fourth.add(const Duration(minutes: 50))));

    //book whole day example
    converted.add(DateTimeRange(
        start: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 5, 0),
        end: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 0)));
    return converted; 
    return [];
  }*/

  Stream<List<DateTimeRange>> getBookingStreamFromServer({
    required DateTime start,
    required DateTime end,
  }) async* {
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final staffKey = bookingProvider.bookingDetails['staffkey'] ?? 'any';

    final dynamic response = await apiManager.fetchAvailability(
      date: start,
      staffKey: staffKey,
      serviceDuration: 45,
    );

    print('fetchAvailability result: $response'); // Debug print

    final List<DateTimeRange> busySlots = [];
    final now = DateTime.now();

    if (response is List) {
      for (final slot in response) {
        if (slot is Map) {
          final timeParts = (slot['slot_time'] as String).split(':');
          final slotStart = DateTime(
            start.year,
            start.month,
            start.day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );
          final slotEnd = slotStart.add(const Duration(minutes: 15));

          // Mark as busy (red) if unavailable from API OR if slot is in the past
          if (slot['available'] == false || slotStart.isBefore(now)) {
            busySlots.add(DateTimeRange(start: slotStart, end: slotEnd));
            print(
                'Busy/grey slot: ${slotStart.toIso8601String()} - ${slotEnd.toIso8601String()}');
          }
        }
      }
    }

    yield busySlots;
  }

  List<DateTimeRange> generatePauseSlots() {
    return [
      DateTimeRange(
          start: DateTime(now.year, now.month, now.day, 12, 0),
          end: DateTime(now.year, now.month, now.day, 13, 0))
    ];
  }

  @override
  Widget build(BuildContext context) {
    const color = Color(COLOR_PRIMARY);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Calendar',
            style: TextStyle(color: Colors.white)),
        backgroundColor: color, // Set app bar color
      ),
      body: Center(
        child: BookingCalendar(
          bookingService: mockBookingService,
          convertStreamResultToDateTimeRanges: (
                  {required dynamic streamResult}) =>
              streamResult as List<DateTimeRange>,

          getBookingStream: (
                  {required DateTime start, required DateTime end}) =>
              getBookingStreamFromServer(start: start, end: end),
          // convertStreamResultToDateTimeRanges: convertStreamResultMock,
          // getBookingStream: getBookingStreamMock,
          uploadBooking: uploadBookingMock,
          pauseSlots: generatePauseSlots(),
          pauseSlotText: 'Disabled',
          hideBreakTime: false,
          loadingWidget: const Text('Fetching data...'),
          uploadingWidget: const CircularProgressIndicator(),
          locale: 'en_GB',
          // ✅ Start from the current day

          startingDayOfWeek: StartingDayOfWeek.monday,
          wholeDayIsBookedWidget:
              const Text('Sorry, for this day everything is booked'),
          //disabledDates: [DateTime(2023, 1, 20)],
          //disabledDays: [6, 7],
        ),
      ),
    );
  }
}
