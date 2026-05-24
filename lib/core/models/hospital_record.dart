class HospitalRecord {
  const HospitalRecord({
    required this.name,
    required this.distanceKm,
    required this.rating,
    required this.address,
    required this.phone,
  });

  final String name;
  final double distanceKm;
  final double rating;
  final String address;
  final String phone;
}
