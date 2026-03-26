import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salonappweb/provider/booking.provider.dart';
import 'package:booking_calendar/booking_calendar.dart';
import 'package:salonappweb/constants.dart';
import 'package:salonappweb/model/booking.dart';
// Import SchedulePage
import 'summary.dart';
import 'package:salonappweb/api/api_manager.dart';

class BookingCalendarPage extends StatefulWidget {
  final Booking? booking;

  const BookingCalendarPage({super.key, this.booking});

  @override
  _BookingCalendarPageState createState() => _BookingCalendarPageState();
}

class _BookingCalendarPageState extends State<BookingCalendarPage> {
  late BookingService mockBookingService;
  bool isSettingsLoaded = false;
  final now = DateTime.now();
  List<DateTimeRange> converted = [];
  List<int> disabledDays = [];
  List<DateTime> disabledDates = [];
  int time_open = 9;
  int time_close = 18;
  int bookingLeadTimeMinutes = 0;

  int _parseLeadTimeMinutes(dynamic rawValue) {
    if (rawValue == null) return 0;

    if (rawValue is num) {
      return rawValue.toInt() < 0 ? 0 : rawValue.toInt();
    }

    final value = rawValue.toString().trim();
    if (value.isEmpty) return 0;

    // Support formats like "60" or "01:00" or "01:00:00".
    if (value.contains(':')) {
      final parts = value.split(':');
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      final total = (hours * 60) + minutes;
      return total < 0 ? 0 : total;
    }

    final asInt = int.tryParse(value) ?? 0;
    return asInt < 0 ? 0 : asInt;
  }

  @override
  void initState() {
    super.initState();
    print(time_close);
    mockBookingService = BookingService(
        serviceName: 'Mock Service',
        serviceDuration: 15,
        bookingEnd: DateTime(now.year, now.month, now.day, time_close, 0),
        bookingStart: DateTime(now.year, now.month, now.day, time_open, 0));

    // Fetch booking settings from backend
    _fetchBookingSettings();
  }

  Future<void> _fetchBookingSettings() async {
    try {
      final response = await apiManager.fetchBookingSettings();

      if (response != null) {
        // Extract settings from nested structure
        Map<String, dynamic>? settingsData;

        if (response['settings'] != null &&
            response['settings'] is List &&
            (response['settings'] as List).isNotEmpty) {
          settingsData = response['settings'][0] as Map<String, dynamic>;
        } else {
          settingsData = response;
        }

        setState(() {
          // Check if sundayoff is true, then disable Sunday (7)
          if (settingsData != null &&
              (settingsData['sundayoff'] == true ||
                  settingsData['sundayoff'] == 'true')) {
            disabledDays = [7];
          } else {
            disabledDays = [];
          }
          if (settingsData != null && settingsData['time_open'] != null) {
            try {
              // Parse 'hh.mm.ss' format and extract hour
              final timeOpenStr = settingsData['time_open'].toString();
              final parts = timeOpenStr.split(':');
              if (parts.isNotEmpty) {
                time_open = int.parse(parts[0]);
              } else {
                time_open = 9; // default
              }
            } catch (e) {
              time_open = 9; // default
            }
          }
          if (settingsData != null && settingsData['time_close'] != null) {
            try {
              // Parse 'hh.mm.ss' format and extract hour
              final timeCloseStr = settingsData['time_close'].toString();
              final parts = timeCloseStr.split(':');
              if (parts.isNotEmpty) {
                time_close = int.parse(parts[0]);
              } else {
                time_close = 18; // default
              }
            } catch (e) {
              time_close = 18; // default
            }
          }

          if (settingsData != null) {
            bookingLeadTimeMinutes =
                _parseLeadTimeMinutes(settingsData['booking_lead_time']);
            print('booking_lead_time (minutes): $bookingLeadTimeMinutes');
          }

          // Update mockBookingService with new time_open and time_close
          mockBookingService = BookingService(
            serviceName: 'Mock Service',
            serviceDuration: 15,
            bookingEnd: DateTime(now.year, now.month, now.day, time_close, 0),
            bookingStart: DateTime(now.year, now.month, now.day, time_open, 0),
          );
          isSettingsLoaded = true;
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
                  } catch (e) {}
                }
              }
            } catch (e) {}
          }
        });
      }
    } catch (e) {
      // Default to disabled if error
      setState(() {
        disabledDays = [7];
      });
    }
  }

  Stream<dynamic>? getBookingStreamMock(
      {required DateTime end, required DateTime start}) {
    return Stream.value([]);
  }

  Future<dynamic> uploadBookingMock(
      {required BookingService newBooking}) async {
    // Check if the selected date is Sunday (7) and if it's disabled (sundayoff = true)
    if (newBooking.bookingStart.weekday == 7 &&
        disabledDays.isNotEmpty &&
        disabledDays.contains(7)) {
      print('🔴 Sunday disabled - returning early');
      return;
    }

    final earliestBookable =
        DateTime.now().add(Duration(minutes: bookingLeadTimeMinutes));
    if (newBooking.bookingStart.isBefore(earliestBookable)) {
      print('🔴 Lead time restriction - earliest booking is $earliestBookable');
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
      // New booking mode: go to Summary page
      print('📋 Going to Summary (editMode=false)');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SummaryPage()),
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
    final serviceKeyRaw = bookingProvider.bookingDetails['servicekey'];
    final serviceKey = int.tryParse(serviceKeyRaw?.toString() ?? '') ?? 0;

    final dynamic response = await apiManager.fetchAvailability(
      date: start,
      staffKey: staffKey,
      serviceKey: serviceKey,
    );

    // Print first and last time slots
    printFirstAndLastTimeSlot(response);

    //print('fetchAvailability result: $response'); // Debug print

    final List<DateTimeRange> busySlots = [];
    final now = DateTime.now();
    final earliestBookable = now.add(Duration(minutes: bookingLeadTimeMinutes));

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

          // Mark as busy if unavailable from API, past, or within lead-time window.
          if (slot['available'] == false ||
              slotStart.isBefore(earliestBookable)) {
            busySlots.add(DateTimeRange(start: slotStart, end: slotEnd));
            // print( 'Busy/grey slot: ${slotStart.toIso8601String()} - ${slotEnd.toIso8601String()}');
          }
        }
      }
    }

    yield busySlots;
  }

  void printFirstAndLastTimeSlot(dynamic response) {
    if (response is List && response.isNotEmpty) {
      // Get first slot
      final firstSlot = response.first;
      final firstTimeSlot = firstSlot is Map ? firstSlot['slot_time'] : 'N/A';

      // Get last slot
      final lastSlot = response.last;
      final lastTimeSlot = lastSlot is Map ? lastSlot['slot_time'] : 'N/A';

      print('🕐 First time slot: $firstTimeSlot');
      print('🕐 Last time slot: $lastTimeSlot');
    } else {
      print('⚠️ No slots available in response');
    }
  }

  List<DateTimeRange> generatePauseSlots() {
    return [];
  }

  @override
  Widget build(BuildContext context) {
    const color = Color(COLOR_PRIMARY);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final EdgeInsetsGeometry zeroPadding = EdgeInsets.zero;
    final EdgeInsetsGeometry defaultPadding = const EdgeInsets.all(16.0);
    final EdgeInsetsGeometry padding = isMobile ? zeroPadding : defaultPadding;
    final EdgeInsetsGeometry margin =
        isMobile ? EdgeInsets.zero : EdgeInsets.zero;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Calendar',
            style: TextStyle(color: Colors.white)),
        backgroundColor: color,
      ),
      body: isSettingsLoaded
          ? Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bg.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(
                child: Container(
                  color: Colors.white,
                  margin: margin,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: SafeArea(
                      child: Padding(
                        padding: padding,
                        child: Builder(builder: (context) {
                          const int crossAxisCount = 4;
                          final bool compact = crossAxisCount >= 4;
                          return SizedBox(
                            height: 700,
                            child: BookingCalendar(
                              bookingService: mockBookingService,
                              bookingExplanation: const SizedBox.shrink(),
                              bookingGridCrossAxisCount: crossAxisCount,
                              bookingGridChildAspectRatio: compact ? 1.2 : 1.5,
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
                                      {required DateTime start,
                                      required DateTime end}) =>
                                  getBookingStreamFromServer(
                                      start: start, end: end),
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
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
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
                              startingDayOfWeek: StartingDayOfWeek.monday,
                              wholeDayIsBookedWidget: const Text(
                                'No time slot available, try to change different staff or day',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
