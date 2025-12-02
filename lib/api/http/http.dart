import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:salonappweb/config/app_config.dart';
import 'package:salonappweb/model/user.dart';
import 'package:salonappweb/model/booking.dart';
import 'package:salonappweb/model/booking_response.dart';
import 'package:salonappweb/model/staff.dart';
import 'package:salonappweb/model/service.dart';
import 'package:salonappweb/model/customer.dart';
import 'package:salonappweb/services/helper.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';

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

    // Try to get customer token first
    final prefs = await SharedPreferences.getInstance();
    final String? customerToken = prefs.getString('customer_token');

    String? token;
    if (customerToken != null && customerToken.isNotEmpty) {
      token = customerToken;
    } else {
      // Fallback to admin token if available
      final User currentUser = await getCurrentUser();
      token = currentUser.token;
    }

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

  // Smart method that uses customer token by default
  Future<List<Booking>> ListBookingsSmart() async {
    try {
      // Check if customer token exists
      final prefs = await SharedPreferences.getInstance();
      final String? customerToken = prefs.getString('customer_token');

      if (customerToken != null && customerToken.isNotEmpty) {
        // Use customer bookings API
        final bookings = await fetchCustomerBookings();
        return bookings;
      } else {
        // No customer token - return empty list or throw error
        throw 'Please log in to view bookings';
      }
    } catch (error) {
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
      rethrow;
    }
  }

  //BOOKING

  Future<BookingResponse?> SaveBooking(
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
    String customerEmail,
    String customerPhone,
  ) async {
    //  print('url test: ${AppConfig.api_url_booking_add}');
    try {
      final bookingData = <String, String>{
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
        'customeremail': customerEmail,
        'customerphone': customerPhone,
        'userkey': '1',
      };

      final response = await http.post(
        Uri.parse(AppConfig.api_url_bookingweb_save),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(bookingData),
      );

      // Debug: log full response body to the `app` channel so it appears in applog during development
      try {
        // Send to `app` log channel (visible via developer tools/applog)
        developer.log(
            '=== FETCH CUSTOMER BOOKINGS RESPONSE ===\nStatus: ${response.statusCode}\n${response.body}\n=== END FETCH CUSTOMER BOOKINGS RESPONSE ===',
            name: 'app');
        // Also print simple raw response to console for immediate visibility
        // (unconditional so you can see it even in builds where kDebugMode is false)
        print('FETCH CUSTOMER BOOKINGS RAW: ${response.body}');
      } catch (_) {}

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final bookingResponse = BookingResponse.fromJson(responseData);

        // Store token in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('customer_token', bookingResponse.token);
        await prefs.setString('customer_key', bookingResponse.customerkey);

        return bookingResponse;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Send booking confirmation email
  Future<bool> sendBookingConfirmationEmail({
    required String bookingKey,
    required String customerEmail,
    required String customerName,
  }) async {
    try {
      final emailData = <String, String>{
        'bookingkey': bookingKey,
        'customeremail': customerEmail,
        'customername': customerName,
      };

      final response = await http.post(
        Uri.parse(AppConfig.api_url_booking_send_confirmation),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(emailData),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
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
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Fetch customer profile using customer token
  Future<Map<String, dynamic>?> fetchCustomerProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('customer_token');

      if (token == null || token.isEmpty) {
        return null;
      }

      final response = await http.get(
        Uri.parse(AppConfig.api_url_customer_profile),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Fetch customer bookings using customer token
  Future<List<Booking>> fetchCustomerBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('customer_token');

      if (token == null || token.isEmpty) {
        return [];
      }

      final response = await http.get(
        Uri.parse(AppConfig.api_url_customer_bookings),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);

        List<dynamic> data;
        if (responseData is List) {
          data = responseData;
        } else if (responseData is Map && responseData['bookings'] != null) {
          data = responseData['bookings'] as List;
        } else if (responseData is Map && responseData['data'] != null) {
          data = responseData['data'] as List;
        } else {
          return [];
        }

        // Get customerkey from stored profile for customer API bookings
        final cachedProfile = prefs.getString('cached_customer_profile');
        int? storedCustomerKey;
        if (cachedProfile != null && cachedProfile.isNotEmpty) {
          try {
            final profileData =
                jsonDecode(cachedProfile) as Map<String, dynamic>;
            storedCustomerKey =
                profileData['customerkey'] ?? profileData['pkey'];
          } catch (e) {}
        }

        // Add customerkey to each booking if missing
        final bookingsWithCustomerKey = data.map((item) {
          if (item is Map<String, dynamic>) {
            // If customerkey is missing or null, add it from stored profile
            if (item['customerkey'] == null && storedCustomerKey != null) {
              item['customerkey'] = storedCustomerKey;
            }
          }
          return item;
        }).toList();

        final bookings = bookingsWithCustomerKey
            .map<Booking>((item) => Booking.fromJson(item))
            .toList();
        return bookings;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Cancel booking using customer token
  Future<Map<String, dynamic>> cancelCustomerBooking(int bookingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? customerToken = prefs.getString('customer_token');

      if (customerToken == null || customerToken.isEmpty) {
        return {'success': false, 'message': 'No customer token found'};
      }

      final requestBody = {
        'bookingkey': bookingId.toString(),
      };

      final response = await http.post(
        Uri.parse(AppConfig.api_url_booking_del),
        headers: <String, String>{
          'Authorization': 'Bearer $customerToken',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true, 'message': 'Booking cancelled successfully'};
      } else {
        // Try to extract message from response body
        try {
          final Map<String, dynamic> body = json.decode(response.body);
          final String msg = body['message']?.toString() ?? response.body;
          return {'success': false, 'message': msg};
        } catch (e) {
          return {
            'success': false,
            'message': 'Cancel failed: ${response.statusCode}'
          };
        }
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Fetch booking settings (sundayoff, etc.)
  /// Note: No token required - this is a public endpoint
  Future<Map<String, dynamic>?> fetchBookingSettings() async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.api_url_booking_settings),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Customer login with email or phone
  /// Returns token and customer info on success
  Future<Map<String, dynamic>?> customerLogin({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      final loginData = {
        'emailOrPhone': emailOrPhone,
        'password': password,
      };

      final response = await http.post(
        Uri.parse(AppConfig.api_url_customer_login),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(loginData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        // Store customer token
        if (responseData['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('customer_token', responseData['token']);
          await prefs.setString(
              'customer_key', responseData['customerkey']?.toString() ?? '');
        }

        return responseData;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Register customer as a member with password
  /// Updates customer profile and sets login credentials
  Future<Map<String, dynamic>> registerMember({
    required int customerkey,
    required String fullname,
    required String email,
    required String phone,
    required String password,
    String? dob,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? customerToken = prefs.getString('customer_token');

      if (customerToken == null || customerToken.isEmpty) {
        throw 'Customer token not found. Please login again.';
      }

      final memberData = <String, dynamic>{
        'customerkey': customerkey,
        'fullname': fullname,
        'email': email,
        'phone': phone,
        'password': password,
        'dob': dob ?? '',
      };

      final response = await http.post(
        Uri.parse(AppConfig.api_url_customer_register_member),
        headers: <String, String>{
          'Authorization': 'Bearer $customerToken',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(memberData),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(response.body);
        return result;
      } else if (response.statusCode == 401) {
        throw 'Your session has expired. Please log in again.';
      } else if (response.statusCode == 400) {
        final Map<String, dynamic> errorResult = json.decode(response.body);
        throw errorResult['message'] ?? 'Invalid data provided';
      } else if (response.statusCode == 409) {
        throw 'This email is already registered as a member';
      } else {
        throw 'Failed to register member. Status: ${response.statusCode}';
      }
    } catch (error) {
      rethrow;
    }
  }

  // Public registration - no authentication required
  Future<Map<String, dynamic>> registerNewCustomer({
    required String fullname,
    required String email,
    required String phone,
    required String password,
    String? dob,
  }) async {
    try {
      final customerData = <String, dynamic>{
        'fullname': fullname,
        'email': email,
        'phone': phone,
        'password': password,
        'dob': dob ?? '',
      };

      final response = await http.post(
        Uri.parse(AppConfig.api_url_customer_register),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(customerData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> result = json.decode(response.body);

        // Store token if returned by backend
        if (result['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('customer_token', result['token']);
          if (result['customerkey'] != null) {
            await prefs.setString(
                'customer_key', result['customerkey'].toString());
          }
        }

        return result;
      } else if (response.statusCode == 400) {
        final Map<String, dynamic> errorResult = json.decode(response.body);
        throw errorResult['message'] ?? 'Invalid data provided';
      } else if (response.statusCode == 409) {
        throw 'This email is already registered';
      } else {
        throw 'Failed to register. Status: ${response.statusCode}';
      }
    } catch (error) {
      rethrow;
    }
  }

  /// Public endpoint to reset customer password (sends new password to email)
  Future<bool> resetCustomerPassword({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.api_url_customer_reset_password),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{'email': email}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
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
      // Try to get customer token first
      final prefs = await SharedPreferences.getInstance();
      final String? customerToken = prefs.getString('customer_token');

      String? token;
      if (customerToken != null && customerToken.isNotEmpty) {
        token = customerToken;
      } else {
        // Fallback to admin token if available
        final User currentUser = await getCurrentUser();
        token = currentUser.token;
      }

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
        print('===== FETCH AVAILABILITY DATA =====');
        print('Raw API response: $data');
        print('Response type: ${data.runtimeType}');

        // If the response is a List, return as before
        if (data is List) {
          print('Response is List with ${data.length} items');
          final result = data
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
          print('Final slots data: ${jsonEncode(result)}');
          print('====================================');
          return result;
        }

        // If the response is a Map, extract 'slots' as a list
        if (data is Map && data['slots'] != null) {
          final slotsData = data['slots'];
          print('Response is Map with slots key');
          print('Slots type: ${slotsData.runtimeType}');
          if (slotsData is List) {
            print('Slots is List with ${slotsData.length} items');
            final result = slotsData
                .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
                .toList();
            print('Final slots data: ${jsonEncode(result)}');
            print('====================================');
            return result;
          }
        }

        // fallback
        print('No valid slots found - returning empty list');
        print('====================================');
        return [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
