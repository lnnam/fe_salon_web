class Service {
  int pkey;
  String name;
  double price;
  String category;

  Service({
    required this.pkey,
    required this.name,
    required this.price,
    required this.category,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      pkey: json['pkey'] ?? 0,
      name: json['name'] ?? 'Unknown',
      price: (json['price'] ?? 0).toDouble(),
      category: json['category'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'servicekey' : pkey,
      'name': name,
      'price': price,
      'category': category,
    };
  }
}