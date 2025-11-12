class Customer {
  int customerkey;
  String fullname;
  String email;
  String phone;
  String photo;

  Customer({
    required this.customerkey,
    required this.fullname,
    required this.email,
    required this.phone,
    required this.photo,

  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      customerkey: json['pkey'] ?? 0,
      fullname: json['fullname'] ?? 'Unknown',
      email: json['email'] ?? 'Unknown',
      phone: json['phone'] ?? 'Unknown',
      photo: json['photobase64'] != null && json['photobase64'] != '' ? json['photobase64'] : 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerkey': customerkey,
      'fullname': fullname,
      'email': email,
      'phone': phone,
      'photo': photo,
    };
  }
}