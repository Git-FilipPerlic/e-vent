/// Vozilo kojim ekipa ide na događaj.
class Vehicle {
  const Vehicle({required this.id, required this.name});

  final String id;
  final String name;

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? '',
    );
  }
}
