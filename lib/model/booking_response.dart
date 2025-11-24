class BookingResponse {
  final String token;
  final int bookingkey;
  final String customerkey;
  final String message;
  final String status;

  BookingResponse({
    required this.token,
    required this.bookingkey,
    required this.customerkey,
    this.message = '',
    this.status = '',
  });

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    return BookingResponse(
      token: json['token'] ?? '',
      bookingkey: json['bookingkey'] is int
          ? json['bookingkey']
          : int.tryParse(json['bookingkey']?.toString() ?? '0') ?? 0,
      customerkey: json['customerkey']?.toString() ?? '',
      message: json['message']?.toString() ?? json['msg']?.toString() ?? '',
      status: json['status']?.toString() ??
          json['booking_status']?.toString() ??
          json['status_text']?.toString() ??
          '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'bookingkey': bookingkey,
      'customerkey': customerkey,
      'message': message,
      'status': status,
    };
  }
}
