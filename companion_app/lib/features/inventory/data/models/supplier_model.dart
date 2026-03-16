class Supplier {
  final String id;
  final String name;
  final String? contactPerson;

  Supplier({
    required this.id,
    required this.name,
    this.contactPerson,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'],
      name: json['name'],
      contactPerson: json['contactPerson'],
    );
  }
}
