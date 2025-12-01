import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salonappweb/provider/booking.provider.dart';
import 'package:booking_calendar/booking_calendar.dart';
import 'package:salonappweb/constants.dart';
import 'package:salonappweb/model/booking.dart';
// Import SchedulePage
import 'service.dart';
import 'package:salonappweb/api/api_manager.dart';

class BookingCalendarPage extends StatefulWidget {
  final Booking? booking;

  const BookingCalendarPage({super.key, this.booking});

  @override
  _BookingCalendarPageState createState() => _BookingCalendarPageState();
}

class _BookingCalendarPageState extends State<BookingCalendarPage> {
  late BookingService mockBookingService;
  final now = DateTime.now();
  List<DateTimeRange> converted = [];
  List<int> disabledDays = [];
  List<DateTime> disabledDates = [];

  @override
  void initState() {
    super.initState();
    print('========== CALENDAR PAGE INIT ==========');
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    print('📅 EditMode at Calendar: ${bookingProvider.onbooking.editMode}');
    print('=========================================');

    mockBookingService = BookingService(
        serviceName: 'Mock Service',
        serviceDuration: 15,
        bookingEnd: DateTime(now.year, now.month, now.day, 18, 0),
        bookingStart: DateTime(now.year, now.month, now.day, 9, 0));

    // Fetch booking settings from backend
    _fetchBookingSettings();
  }

  Future<void> _fetchBookingSettings() async {
    try {
      //   print('=== FETCH BOOKING SETTINGS START ===');
      //  appLog('=== FETCH BOOKING SETTINGS START ===');

      final response = await apiManager.fetchBookingSettings();

      if (response != null) {
        // print('✓ Response received: $response');
        // appLog('✓ Response received: $response');

        // Extract settings from nested structure
        Map<String, dynamic>? settingsData;

        if (response['settings'] != null &&
            response['settings'] is List &&
            (response['settings'] as List).isNotEmpty) {
          settingsData = response['settings'][0] as Map<String, dynamic>;
          print('✓ Extracted settings from settings[0]');
        } else {
          settingsData = response;
          print('✓ Using response directly as settings');
        }

        print('sundayoff value: ${settingsData['sundayoff']}');
        print('sundayoff type: ${settingsData['sundayoff'].runtimeType}');

        setState(() {
          // Check if sundayoff is true, then disable Sunday (7)
          if (settingsData != null &&
              (settingsData['sundayoff'] == true ||
                  settingsData['sundayoff'] == 'true')) {
            disabledDays = [7];
            print('✓ Sunday DISABLED (sundayoff=true)');
          } else {
            disabledDays = [];
            print('✓ Sunday ENABLED (sundayoff=false)');
          }

          // Parse listoffday (dayoff dates) if it exists
          disabledDates = [];
          if (settingsData != null && settingsData['listoffday'] != null) {
            try {
              final offDayString = settingsData['listoffday'] as String;
              // Split by comma to get individual dates
              final dateStrings = offDayString.split(',');
              for (final dateStr in dateStrings) {
                final trimmed = dateStr.trim();
                if (trimmed.isNotEmpty) {
                  try {
                    final date = DateTime.parse(trimmed);
                    disabledDates
                        .add(DateTime(date.year, date.month, date.day));
                    print('✓ Day OFF added: $trimmed');
                  } catch (e) {
                    print('⚠ Failed to parse date: $trimmed, error: $e');
                  }
                }
              }
              print('✓ Total disabled dates: ${disabledDates.length}');
            } catch (e) {
              print('⚠ Error parsing listoffday: $e');
            }
          }
        });
      } else {
        print('✗ Booking settings returned null');
      }
      //  print('=== FETCH BOOKING SETTINGS END ===');
      // appLog('=== FETCH BOOKING SETTINGS END ===');
    } catch (e, stackTrace) {
      print('✗ Error fetching booking settings: $e');
      print('Stack trace: $stackTrace');

      // Default to disabled if error
      setState(() {
        disabledDays = [7];
        print('⚠ Default to Sunday DISABLED due to error');
      });
    }
  }

  Stream<dynamic>? getBookingStreamMock(
      {required DateTime end, required DateTime start}) {
    return Stream.value([]);
  }

  Future<dynamic> uploadBookingMock(
      {required BookingService newBooking}) async {
    print('🟢 uploadBookingMock CALLED');
    // Check if the selected date is Sunday (7) and if it's disabled (sundayoff = true)
    if (newBooking.bookingStart.weekday == 7 &&
        disabledDays.isNotEmpty &&
        disabledDays.contains(7)) {
      print('🔴 Sunday disabled - returning early');
      return;
    }

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

    print('📤 Setting schedule in provider: $scheduleData');

    Provider.of<BookingProvider>(context, listen: false)
        .setSchedule(scheduleData);

    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final isEditMode = bookingProvider.onbooking.editMode;
    print('✅ EditMode after Calendar selection: $isEditMode');

    if (isEditMode) {
      // Editing mode: pop back to Summary page (don't push a new one)
      print('📋 Popping back to Summary (editMode=true)');
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      // New booking mode: go to Service page
      print('📋 Going to Service (editMode=false)');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ServicePage()),
      );
    }
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
    // Block entire day if Sunday is disabled (sundayoff = true)
    if (start.weekday == 7 &&
        disabledDays.isNotEmpty &&
        disabledDays.contains(7)) {
      // Return full-day busy slot to block all time slots
      yield [
        DateTimeRange(
          start: DateTime(start.year, start.month, start.day, 0, 0),
          end: DateTime(start.year, start.month, start.day, 23, 59),
        )
      ];
      return;
    }

    // Check if the date is in the disabled dates list (dayoff)
    final dateToCheck = DateTime(start.year, start.month, start.day);
    for (final disabledDate in disabledDates) {
      if (dateToCheck.year == disabledDate.year &&
          dateToCheck.month == disabledDate.month &&
          dateToCheck.day == disabledDate.day) {
        // Return full-day busy slot to block all time slots
        yield [
          DateTimeRange(
            start: DateTime(start.year, start.month, start.day, 0, 0),
            end: DateTime(start.year, start.month, start.day, 23, 59),
          )
        ];
        return;
      }
    }

    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final staffKey = bookingProvider.bookingDetails['staffkey'] ?? 'any';

    final dynamic response = await apiManager.fetchAvailability(
      date: start,
      staffKey: staffKey,
      serviceDuration: 45,
    );

    //print('fetchAvailability result: $response'); // Debug print

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
            // print( 'Busy/grey slot: ${slotStart.toIso8601String()} - ${slotEnd.toIso8601String()}');
          }
        }
      }
    }

    yield busySlots;
  }

  List<DateTimeRange> generatePauseSlots() {
    return [];
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
      body: SafeArea(
        child: SizedBox.expand(
          child: Builder(builder: (context) {
            const int crossAxisCount = 4;
            final bool compact = crossAxisCount >= 4;
            return Stack(
              children: [
                BookingCalendar(
                  bookingService: mockBookingService,
                  bookingExplanation: const SizedBox.shrink(),
                  bookingGridCrossAxisCount: crossAxisCount,
                  bookingGridChildAspectRatio: compact ? 1.2 : 1.5,
                  // When compact (many columns) hide the time text by using
                  // a zero-size text style to avoid clipped text.
                  // Use a smaller readable font in compact mode instead of hiding text
                  availableSlotTextStyle: compact
                      ? const TextStyle(fontSize: 12, height: 1)
                      : const TextStyle(fontSize: 14),
                  selectedSlotTextStyle: compact
                      ? const TextStyle(fontSize: 12, height: 1)
                      : const TextStyle(fontSize: 14),
                  bookedSlotTextStyle: compact
                      ? const TextStyle(fontSize: 12, height: 1)
                      : const TextStyle(fontSize: 14),
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
                  uploadingWidget: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Booking…',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  locale: 'en_GB',
                  // ✅ Start from the current day
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  wholeDayIsBookedWidget: const Text(
                    'Salon is closed on this day',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  //disabledDates: [DateTime(2023, 1, 20)],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
