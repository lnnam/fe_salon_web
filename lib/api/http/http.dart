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
      print('✓ Using customer token for API call');
    } else {
      // Fallback to admin token if available
      final User currentUser = await getCurrentUser();
      token = currentUser.token;
      print('✓ Using admin token for API call');
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

  // Smart method that uses customer token by default
  Future<List<Booking>> ListBookingsSmart() async {
    try {
      print('=== ListBookingsSmart START ===');

      // Check if customer token exists
      final prefs = await SharedPreferences.getInstance();
      final String? customerToken = prefs.getString('customer_token');

      print(
          'Customer token exists: ${customerToken != null && customerToken.isNotEmpty}');

      if (customerToken != null && customerToken.isNotEmpty) {
        // Use customer bookings API
        print('✓ Using customer bookings API');
        final bookings = await fetchCustomerBookings();
        print('✓ Customer API returned ${bookings.length} bookings');
        return bookings;
      } else {
        // No customer token - return empty list or throw error
        print('✗ No customer token found');
        throw 'Please log in to view bookings';
      }
    } catch (error) {
      print('✗ Error in ListBookingsSmart: $error');
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

      print('=== SUBMITTING BOOKING ===');
      print('URL: ${AppConfig.api_url_bookingweb_save}');
      print('Data being posted:');
      print(jsonEncode(bookingData));
      print('========================');

      final response = await http.post(
        Uri.parse(AppConfig.api_url_bookingweb_save),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(bookingData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final bookingResponse = BookingResponse.fromJson(responseData);

        // Store token in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('customer_token', bookingResponse.token);
        await prefs.setString('customer_key', bookingResponse.customerkey);

        print('Token stored: ${bookingResponse.token}');
        print('Customer key: ${bookingResponse.customerkey}');
        print('Booking key: ${bookingResponse.bookingkey}');

        return bookingResponse;
      } else {
        print('Error: ${response.statusCode}, Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception during SaveBooking: $e');
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
      print('=== SENDING BOOKING CONFIRMATION EMAIL ===');
      print('Booking key: $bookingKey');
      print('Customer email: $customerEmail');
      print('Customer name: $customerName');

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

      print('Email response status: ${response.statusCode}');
      print('Email response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✓ Booking confirmation email sent successfully');
        return true;
      } else {
        print('✗ Failed to send confirmation email: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('✗ Exception sending confirmation email: $e');
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
        print('Delete failed: ${response.statusCode}, ${response.body}');
        return false;
      }
    } catch (e) {
      print('Delete error: $e');
      return false;
    }
  }

  // Fetch customer profile using customer token
  Future<Map<String, dynamic>?> fetchCustomerProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('customer_token');

      print('=== FETCH CUSTOMER PROFILE START ===');
      print('Customer token exists: ${token != null && token.isNotEmpty}');

      if (token == null || token.isEmpty) {
        print('No customer token found in SharedPreferences');
        return null;
      }

      print('Using token: ${token.substring(0, 20)}...');
      print('Calling: ${AppConfig.api_url_customer_profile}');

      final response = await http.get(
        Uri.parse(AppConfig.api_url_customer_profile),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('=== FETCH CUSTOMER PROFILE END ===');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Fetch profile failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Fetch profile error: $e');
      return null;
    }
  }

  // Fetch customer bookings using customer token
  Future<List<Booking>> fetchCustomerBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('customer_token');

      print('=== FETCH CUSTOMER BOOKINGS START ===');
      print('Customer token exists: ${token != null && token.isNotEmpty}');

      if (token == null || token.isEmpty) {
        print('No customer token found in SharedPreferences');
        return [];
      }

      print('Using token: ${token.substring(0, 20)}...');
      print('Calling: ${AppConfig.api_url_customer_bookings}');

      final response = await http.get(
        Uri.parse(AppConfig.api_url_customer_bookings),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('=== FETCH CUSTOMER BOOKINGS END ===');

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        print('Response data type: ${responseData.runtimeType}');

        List<dynamic> data;
        if (responseData is List) {
          data = responseData;
        } else if (responseData is Map && responseData['bookings'] != null) {
          data = responseData['bookings'] as List;
        } else if (responseData is Map && responseData['data'] != null) {
          data = responseData['data'] as List;
        } else {
          print('✗ Unexpected response format: $responseData');
          return [];
        }

        print('Parsed ${data.length} bookings from response');
        
        // Get customerkey from stored profile for customer API bookings
        final cachedProfile = prefs.getString('cached_customer_profile');
        int? storedCustomerKey;
        if (cachedProfile != null && cachedProfile.isNotEmpty) {
          try {
            final profileData = jsonDecode(cachedProfile) as Map<String, dynamic>;
            storedCustomerKey = profileData['customerkey'] ?? profileData['pkey'];
            print('✓ Stored customer key from profile: $storedCustomerKey');
          } catch (e) {
            print('Could not parse cached profile for customerkey: $e');
          }
        }
        
        // Add customerkey to each booking if missing
        final bookingsWithCustomerKey = data.map((item) {
          if (item is Map<String, dynamic>) {
            // If customerkey is missing or null, add it from stored profile
            if (item['customerkey'] == null && storedCustomerKey != null) {
              item['customerkey'] = storedCustomerKey;
              print('✓ Added missing customerkey=$storedCustomerKey to booking pkey=${item['pkey']}');
            }
          }
          return item;
        }).toList();
        
        final bookings = bookingsWithCustomerKey
            .map<Booking>((item) => Booking.fromJson(item))
            .toList();
        print('✓ Successfully created ${bookings.length} Booking objects');
        return bookings;
      } else {
        print('Fetch bookings failed: ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      print('Fetch bookings error: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // Cancel booking using customer token
  Future<bool> cancelCustomerBooking(int bookingId) async {
    try {
      print('=== CANCEL CUSTOMER BOOKING START ===');
      print('Booking ID: $bookingId');

      final prefs = await SharedPreferences.getInstance();
      final String? customerToken = prefs.getString('customer_token');

      if (customerToken == null || customerToken.isEmpty) {
        print('✗ No customer token found');
        return false;
      }

      print('✓ Using customer token');
      print('Calling: ${AppConfig.api_url_booking_del}');

      final requestBody = {
        'bookingkey': bookingId,
      };

      print('Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(AppConfig.api_url_booking_del),
        headers: <String, String>{
          'Authorization': 'Bearer $customerToken',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('=== CANCEL CUSTOMER BOOKING END ===');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✓ Booking cancelled successfully');
        return true;
      } else {
        print('✗ Cancel failed: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      print('✗ Cancel booking error: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Customer login with email or phone
  /// Returns token and customer info on success
  Future<Map<String, dynamic>?> customerLogin({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      print('=== CUSTOMER LOGIN START ===');
      print('Email/Phone: $emailOrPhone');

      final loginData = {
        'emailOrPhone': emailOrPhone,
        'password': password,
      };

      print('Calling: ${AppConfig.api_url_customer_login}');
      print('Request body: ${jsonEncode(loginData)}');

      final response = await http.post(
        Uri.parse(AppConfig.api_url_customer_login),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(loginData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('=== CUSTOMER LOGIN END ===');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        // Store customer token
        if (responseData['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('customer_token', responseData['token']);
          await prefs.setString(
              'customer_key', responseData['customerkey']?.toString() ?? '');
          print('✓ Customer token stored');
        }

        return responseData;
      } else {
        print('✗ Login failed: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      print('✗ Customer login error: $e');
      print('Stack trace: $stackTrace');
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
      print('=== registerMember START ===');

      final prefs = await SharedPreferences.getInstance();
      final String? customerToken = prefs.getString('customer_token');

      if (customerToken == null || customerToken.isEmpty) {
        print('✗ No customer token found');
        throw 'Customer token not found. Please login again.';
      }

      print('✓ Customer token found');

      final memberData = <String, dynamic>{
        'customerkey': customerkey,
        'fullname': fullname,
        'email': email,
        'phone': phone,
        'password': password,
        'dob': dob ?? '',
      };

      print(
          'Registering member at: ${AppConfig.api_url_customer_register_member}');
      print('Data: ${jsonEncode(memberData)}');

      final response = await http.post(
        Uri.parse(AppConfig.api_url_customer_register_member),
        headers: <String, String>{
          'Authorization': 'Bearer $customerToken',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(memberData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✓ Member registered successfully');
        final Map<String, dynamic> result = json.decode(response.body);
        print('=== registerMember END ===');
        return result;
      } else if (response.statusCode == 401) {
        print('✗ Unauthorized - token may be expired');
        throw 'Your session has expired. Please log in again.';
      } else if (response.statusCode == 400) {
        print('✗ Bad request - validation error');
        final Map<String, dynamic> errorResult = json.decode(response.body);
        throw errorResult['message'] ?? 'Invalid data provided';
      } else if (response.statusCode == 409) {
        print('✗ Conflict - email already registered');
        throw 'This email is already registered as a member';
      } else {
        print('✗ Request failed with status: ${response.statusCode}');
        throw 'Failed to register member. Status: ${response.statusCode}';
      }
    } catch (error) {
      print('✗ Error in registerMember: $error');
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
      print('=== registerNewCustomer START ===');

      final customerData = <String, dynamic>{
        'fullname': fullname,
        'email': email,
        'phone': phone,
        'password': password,
        'dob': dob ?? '',
      };

      print(
          'Registering new customer at: ${AppConfig.api_url_customer_register}');
      print('Data: ${jsonEncode(customerData)}');

      final response = await http.post(
        Uri.parse(AppConfig.api_url_customer_register),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(customerData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✓ Customer registered successfully');
        final Map<String, dynamic> result = json.decode(response.body);

        // Store token if returned by backend
        if (result['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('customer_token', result['token']);
          if (result['customerkey'] != null) {
            await prefs.setString(
                'customer_key', result['customerkey'].toString());
          }
          print('✓ Customer token stored: ${result['token']}');
        }

        print('=== registerNewCustomer END ===');
        return result;
      } else if (response.statusCode == 400) {
        print('✗ Bad request - validation error');
        final Map<String, dynamic> errorResult = json.decode(response.body);
        throw errorResult['message'] ?? 'Invalid data provided';
      } else if (response.statusCode == 409) {
        print('✗ Conflict - email already registered');
        throw 'This email is already registered';
      } else {
        print('✗ Request failed with status: ${response.statusCode}');
        throw 'Failed to register. Status: ${response.statusCode}';
      }
    } catch (error) {
      print('✗ Error in registerNewCustomer: $error');
      rethrow;
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
        print('✓ Using customer token for availability');
      } else {
        // Fallback to admin token if available
        final User currentUser = await getCurrentUser();
        token = currentUser.token;
        print('✓ Using admin token for availability');
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
