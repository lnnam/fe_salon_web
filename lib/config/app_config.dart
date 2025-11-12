class AppConfig {
  static const api_url = 'http://localhost:8080';
  static const api_url_login = '$api_url/api/auth/signin';
  static const api_url_booking_home = '$api_url/api/booking/list';
  static const api_url_booking_staff = '$api_url/api/booking/staff';
  static const api_url_booking_service = '$api_url/api/booking/service';
  static const api_url_booking_customer = '$api_url/api/booking/customer';
  static const api_url_bookingweb_save = '$api_url/api/booking/websave';
  static const api_url_booking_del = '$api_url/api/booking/del';
  static const api_url_booking_getavailability =
      '$api_url/api/booking/getavailability';
}
