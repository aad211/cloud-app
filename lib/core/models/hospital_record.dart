class HospitalRecord {
  const HospitalRecord({
    required this.name,
    required this.distanceKm,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
  });

  final String name;
  final double distanceKm;
  final String address;
  final double latitude;
  final double longitude;
  final String? phone;
}
