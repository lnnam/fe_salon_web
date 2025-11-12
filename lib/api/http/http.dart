import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:salonapp/config/app_config.dart';
import 'package:salonapp/model/user.dart';
import 'package:salonapp/model/booking.dart';
import 'package:salonapp/model/staff.dart';
import 'package:salonapp/model/service.dart';
import 'package:salonapp/model/customer.dart';
import 'package:salonapp/services/helper.dart';

class MyHttp {
  /// @param username user salonkey
  /// @param password user username
  /// @param password user password
  Future<dynamic> salonLogin(
      String salonkey, String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.api_url_login),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'salonkey': salonkey,
          'username': username,
          'password': password,
        }),
      );

      // Map<String, dynamic> response = {};

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        // then throw an exception.
        //throw Exception('Login Fail !');
        return null;
      }
    } catch (e) {
      // debugPrint(e.toString() + '$s');
      return e;
    }
  }

  Future<dynamic> fetchFromServer(String apiEndpoint) async {
    // Constructing options for HTTP request
    final Uri uri = Uri.parse(apiEndpoint);

    final User currentUser = await getCurrentUser();

    final String token = currentUser.token;

    final Map<String, String> headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // Making the HTTP GET request
    final http.Response response = await http.get(uri, headers: headers);

    // Handling response
    if (response.statusCode == 200) {
      // Request successful, parse and return response data
      return json.decode(response.body);
    } else {
      // Request failed, throw error
      if (response.statusCode == 401) {
        throw 'Your session has expired. Please log in again.';
      } else {
        throw 'Request failed with status: ${response.statusCode}';
      }
    }
  }

  Future<List<Booking>> ListBooking() async {
    try {
      final response = await fetchFromServer(AppConfig.api_url_booking_home);
      // print('url test: ${response}');
      List<dynamic> data = response;
      return data.map<Booking>((item) => Booking.fromJson(item)).toList();
    } catch (error) {
      // Handle error
      rethrow;
    }
  }

  Future<List<Staff>> ListStaff() async {
    try {
      final response = await fetchFromServer(AppConfig.api_url_booking_staff);
      List<dynamic> data = response;
      return data.map<Staff>((item) => Staff.fromJson(item)).toList();
    } catch (error) {
      // Handle error
      print(error);

      rethrow;
    }
  }

  Future<List<Customer>> ListCustomer() async {
    try {
      final response =
          await fetchFromServer(AppConfig.api_url_booking_customer);
      List<dynamic> data = response;
      return data.map<Customer>((item) => Customer.fromJson(item)).toList();
    } catch (error) {
      // Handle error
      print(error);

      rethrow;
    }
  }

  Future<List<Service>> ListServices() async {
    try {
      final response = await fetchFromServer(AppConfig.api_url_booking_service);
      List<dynamic> data = response;
      return data.map<Service>((item) => Service.fromJson(item)).toList();
    } catch (error) {
      // Handle error
      print(error);
      rethrow;
    }
  }

  //BOOKING

  Future<dynamic> SaveBooking(
    int bookingKey,
    String customerKey,
    String serviceKey,
    String staffKey,
    String date,
    String schedule,
    String note,
    String customerName,
    String staffName,
    String serviceName,
  ) async {
    //  print('url test: ${AppConfig.api_url_booking_add}');
    try {
      final response = await http.post(
        Uri.parse(AppConfig.api_url_booking_save),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'bookingkey': bookingKey.toString(),
          'customerkey': customerKey,
          'servicekey': serviceKey,
          'staffkey': staffKey,
          'date': date,
          'datetime': schedule,
          'note': note,
          'customername': customerName,
          'staffname': staffName,
          'servicename': serviceName,
          'userkey': '1',
        }),
      );

      if (response.statusCode == 201) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        //return null;  // Booking failed
        print('Error: ${response.statusCode}, Response: ${response.body}');
      }
    } catch (e) {
      return e; // Return error for debugging
    }
  }

  Future<bool> deleteBooking(int bookingId) async {
    try {
      // Get current user and token
      final User currentUser = await getCurrentUser();
      final String token = currentUser.token;

      final response = await http.delete(
        Uri.parse('${AppConfig.api_url_booking_del}/$bookingId'),
        headers: <String, String>{
          'Authorization': 'Bearer $token', // <-- Add token here
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Successfully deleted
        return true;
      } else {
        print('Delete failed: ${response.statusCode}, ${response.body}');
        return false;
      }
    } catch (e) {
      print('Delete error: $e');
      return false;
    }
  }

// MyHttp: returns list of simple maps (slot_time, available, available_staffs)
  Future<List<Map<String, dynamic>>> fetchAvailability({
    required DateTime date,
    String staffKey = 'any',
    int serviceDuration = 45,
  }) async {
    try {
      final User currentUser = await getCurrentUser();
      final String token = currentUser.token;

      final String formattedDate = date.toIso8601String().substring(0, 10);
      final Uri uri = Uri.parse(
        '${AppConfig.api_url_booking_getavailability}?date=$formattedDate&staffkey=$staffKey&service_duration=$serviceDuration',
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        // print('Raw API data: $data');

        // If the response is a List, return as before
        if (data is List) {
          return data
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        }

        // If the response is a Map, extract 'slots' as a list
        if (data is Map && data['slots'] != null) {
          final slotsData = data['slots'];
          if (slotsData is List) {
            return slotsData
                .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        }

        // fallback
        return [];
      } else {
        print('Fetch availability failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching availability: $e');
      return [];
    }
  }
}
