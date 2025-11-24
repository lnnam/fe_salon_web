import 'package:intl/intl.dart';

class Booking {
  final int pkey; // <-- Add this line as int
  final String customerkey;
  final String customername;
  final DateTime datetimebooking;
  final String staffkey;
  final String staffname;
  final String servicename;
  final String servicekey;
  final String numbooked;
  final String customertype;
  final DateTime created_datetime;
  final String bookingdate;
  final DateTime bookingtime;
  final DateTime bookingstart;
  final String customerphoto;
  final String note;
  final String status;

  Booking({
    required this.pkey, // <-- Add this line
    required this.customerkey,
    required this.customername,
    required this.datetimebooking,
    required this.staffkey,
    required this.staffname,
    required this.servicename,
    required this.servicekey,
    required this.numbooked,
    required this.customertype,
    required this.created_datetime,
    required this.bookingstart,
    required this.bookingdate,
    required this.bookingtime,
    required this.customerphoto,
    required this.note,
    this.status = '',
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    DateTime bookingDateTime;
    String formattedBookingDate = '';
    // ignore: unused_local_variable
    String formattedBookingTime = '';

    if (json['bookingstart'] != null && json['bookingstart'] != '') {
      bookingDateTime = DateTime.parse(json['bookingstart']);
      formattedBookingDate = DateFormat('yyyy-MM-dd').format(bookingDateTime);
      formattedBookingTime = DateFormat('HH:mm').format(bookingDateTime);
    } else {
      bookingDateTime =
          json['dateactivated'] != null && json['dateactivated'] != ''
              ? DateTime.parse(json['dateactivated'])
              : DateTime.now();
      formattedBookingDate = DateFormat('yyyy-MM-dd').format(bookingDateTime);
      formattedBookingTime = '';
    }

    DateTime createdDateTime =
        json['dateactivated'] != null && json['dateactivated'] != ''
            ? DateTime.parse(json['dateactivated'])
            : DateTime.now();

    return Booking(
      pkey: json['pkey'] is int
          ? json['pkey']
          : int.tryParse(json['pkey']?.toString() ?? '') ??
              0, // <-- Parse as int
      customername: json['customername'] ?? 'Unknown',
      customerkey: json['customerkey']?.toString() ?? 'Unknown',
      staffkey: json['staffkey']?.toString() ?? 'Unknown',
      datetimebooking: bookingDateTime,
      staffname: json['staffname'] ?? 'N/A',
      servicename: json['servicename'] ?? 'N/A',
      servicekey: json['servicekey']?.toString() ?? 'Unknown',
      numbooked: json['pkey']?.toString() ?? 'Unknown',
      customertype: json['customertype'] ?? 'N/A',
      created_datetime: createdDateTime,
      bookingdate: formattedBookingDate,
      bookingtime: bookingDateTime,
      bookingstart: json['bookingstart'] != null && json['bookingstart'] != ''
          ? DateTime.parse(json['bookingstart'])
          : DateTime.now(),
      customerphoto: json['photobase64'] != null && json['photobase64'] != ''
          ? json['photobase64']
          : 'Unknown',
      note: json['note'] ?? '',
      status: json['status'] ?? json['booking_status'] ?? '',
    );
  }
}

class OnBooking {
  Map<String, dynamic>? staff;
  Map<String, dynamic>? customer;
  Map<String, dynamic>? service;
  Map<String, dynamic>? schedule;
  bool editMode;
  String note;
  int bookingkey;
  String guestemail;
  String guestphone;

  OnBooking({
    this.staff,
    this.customer,
    this.service,
    this.schedule,
    this.editMode = false, // default to false
    this.note = '',
    this.bookingkey = 0,
    this.guestemail = '',
    this.guestphone = '',
  });
}
