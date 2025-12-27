class AppConfig {
  static const api_url = 'https://apiclient.greatyarmouthnails.com';
  //static const api_url = 'http://localhost:8080';
  static const api_url_login = '$api_url/api/auth/signin';
  //static const api_url_booking_home = '$api_url/api/booking/list';
  static const api_url_booking_staff = '$api_url/api/booking/staff';
  static const api_url_booking_service = '$api_url/api/booking/service';
  static const api_url_booking_customer = '$api_url/api/booking/customer';
  static const api_url_bookingweb_save = '$api_url/api/booking/websave';
  static const api_url_booking_del = '$api_url/api/booking/customer/cancel';
  static const api_url_booking_getavailability =
      '$api_url/api/booking/getavailability';
  static const api_url_customer_profile =
      '$api_url/api/booking/customer/profile';
  static const api_url_customer_reset_password =
      '$api_url/api/booking/customer/reset-password';
  static const api_url_customer_bookings =
      '$api_url/api/booking/customer/bookings';
  static const api_url_customer_login = '$api_url/api/booking/customer/login';
  static const api_url_customer_cancel_booking =
      '$api_url/api/booking/customer/cancel';
  static const api_url_customer_register_member =
      '$api_url/api/booking/customer/register-member';
  static const api_url_customer_register =
      '$api_url/api/booking/customer/register';
  static const api_url_booking_send_confirmation =
      '$api_url/api/booking/send-confirmation';
  static const api_url_booking_settings = '$api_url/api/booking/setting';
  // Application display name
  static const appName = 'USA NAILS GT-YARMOUTH';
}
