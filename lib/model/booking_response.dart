class BookingResponse {
  final String token;
  final int bookingkey;
  final String customerkey;

  BookingResponse({
    required this.token,
    required this.bookingkey,
    required this.customerkey,
  });

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    return BookingResponse(
      token: json['token'] ?? '',
      bookingkey: json['bookingkey'] is int
          ? json['bookingkey']
          : int.tryParse(json['bookingkey']?.toString() ?? '0') ?? 0,
      customerkey: json['customerkey']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'bookingkey': bookingkey,
      'customerkey': customerkey,
    };
  }
}
