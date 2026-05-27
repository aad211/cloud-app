import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_app/core/models/hospital_record.dart';
import 'package:cloud_app/features/hospitals/data/location_service.dart';

class HospitalSearchException implements Exception {
  const HospitalSearchException(this.message);

  final String message;

  @override
  String toString() => message;
}

class HospitalSearchRepository {
  HospitalSearchRepository({http.Client? client, Uri? endpoint})
    : _client = client ?? http.Client(),
      _endpoint = endpoint ?? Uri.parse('https://photon.komoot.io/api/');

  final http.Client _client;
  final Uri _endpoint;

  Future<List<HospitalRecord>> searchNearbyHospitals(GeoPoint location) async {
    final uri = _endpoint.replace(
      queryParameters: <String, String>{
        'q': 'hospital',
        'lat': location.latitude.toString(),
        'lon': location.longitude.toString(),
        'limit': '12',
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw HospitalSearchException(
        'Failed to load nearby hospitals (${response.statusCode}).',
      );
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw const HospitalSearchException(
        'Unexpected hospital search response.',
      );
    }

    final features = body['features'];
    if (features is! List) {
      throw const HospitalSearchException(
        'Unexpected hospital search response.',
      );
    }

    final results = <HospitalRecord>[];
    for (final feature in features) {
      if (feature is! Map<String, dynamic>) {
        continue;
      }
      final parsed = _parseFeature(feature, location);
      if (parsed != null) {
        results.add(parsed);
      }
    }

    results.sort((left, right) => left.distanceKm.compareTo(right.distanceKm));
    return results;
  }

  HospitalRecord? _parseFeature(Map<String, dynamic> feature, GeoPoint origin) {
    final geometry = feature['geometry'];
    if (geometry is! Map<String, dynamic>) {
      return null;
    }

    final coordinates = geometry['coordinates'];
    if (coordinates is! List || coordinates.length < 2) {
      return null;
    }

    final lon = _toDouble(coordinates[0]);
    final lat = _toDouble(coordinates[1]);
    if (lon == null || lat == null) {
      return null;
    }

    final properties = feature['properties'];
    if (properties is! Map<String, dynamic>) {
      return null;
    }

    final name = _displayName(properties);
    if (name.isEmpty) {
      return null;
    }

    final address = _buildAddress(properties);
    if (address.isEmpty) {
      return null;
    }

    return HospitalRecord(
      name: name,
      distanceKm: _distanceKm(origin.latitude, origin.longitude, lat, lon),
      address: address,
      latitude: lat,
      longitude: lon,
      phone:
          _normalizeString(properties['phone']).isEmpty
              ? null
              : _normalizeString(properties['phone']),
    );
  }

  String _displayName(Map<String, dynamic> properties) {
    final name = _normalizeString(properties['name']);
    if (name.isNotEmpty) {
      return name;
    }

    final label = _normalizeString(properties['label']);
    if (label.isNotEmpty) {
      return label;
    }

    return _buildAddress(properties);
  }

  String _buildAddress(Map<String, dynamic> properties) {
    final parts =
        <String>[
          _normalizeString(properties['street']),
          _normalizeString(properties['housenumber']),
          _normalizeString(properties['city']),
          _normalizeString(properties['state']),
          _normalizeString(properties['postcode']),
          _normalizeString(properties['country']),
        ].where((part) => part.isNotEmpty).toList();

    return parts.join(', ');
  }

  static String _normalizeString(dynamic value) {
    if (value is String) {
      return value.trim();
    }
    return '';
  }

  static double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static double _distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a =
        (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            (math.sin(dLon / 2) * math.sin(dLon / 2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double degree) => degree * (math.pi / 180.0);
}

final hospitalSearchRepositoryProvider = Provider<HospitalSearchRepository>((
  ref,
) {
  final client = http.Client();
  ref.onDispose(client.close);
  return HospitalSearchRepository(client: client);
});
