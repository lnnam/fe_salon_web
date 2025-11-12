class Staff {
  int staffkey;
  String fullname;
  String position;
  String photo;

  Staff({
    required this.staffkey,
    required this.fullname,
    required this.position,
    required this.photo,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      staffkey: json['pkey'] ?? 0,
      fullname: json['fullname'] ?? 'Unknown',
      position: json['position'] ?? 'Unknown',
      photo: json['photobase64'] != null && json['photobase64'] != '' ? json['photobase64'] : 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staffkey': staffkey,
      'fullname': fullname,
      'position': position,
      'photo': photo,
    };
  }
}
