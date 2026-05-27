import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:cloud_app/features/hospitals/data/hospital_search_repository.dart';
import 'package:cloud_app/features/hospitals/data/location_service.dart';

void main() {
  test('maps Photon features into sorted hospital records', () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'photon.komoot.io');
      expect(request.url.path, '/api/');
      expect(request.url.queryParameters['q'], 'hospital');
      return http.Response(
        jsonEncode({
          'features': [
            {
              'geometry': {
                'coordinates': [1.02, 1.02],
              },
              'properties': {
                'name': 'Far Hospital',
                'street': 'Far St',
                'city': 'Far City',
                'phone': '+1 555-0202',
              },
            },
            {
              'geometry': {
                'coordinates': [1.001, 1.001],
              },
              'properties': {
                'label': 'Central Hospital',
                'street': 'Main St',
                'city': 'Downtown',
              },
            },
          ],
        }),
        200,
      );
    });
    addTearDown(client.close);

    final repository = HospitalSearchRepository(client: client);
    final hospitals = await repository.searchNearbyHospitals(
      const GeoPoint(latitude: 1, longitude: 1),
    );

    expect(hospitals, hasLength(2));
    expect(hospitals.first.name, 'Central Hospital');
    expect(hospitals.first.address, 'Main St, Downtown');
    expect(hospitals.first.phone, isNull);
    expect(hospitals.first.distanceKm, lessThan(hospitals.last.distanceKm));
    expect(hospitals.last.phone, '+1 555-0202');
    expect(hospitals.last.address, 'Far St, Far City');
  });

  test('returns an empty list when the API returns no features', () async {
    final client = MockClient((request) async {
      return http.Response(jsonEncode({'features': []}), 200);
    });
    addTearDown(client.close);

    final repository = HospitalSearchRepository(client: client);
    final hospitals = await repository.searchNearbyHospitals(
      const GeoPoint(latitude: 1, longitude: 1),
    );

    expect(hospitals, isEmpty);
  });

  test('throws when the API returns a non-200 response', () async {
    final client = MockClient((request) async {
      return http.Response('server error', 500);
    });
    addTearDown(client.close);

    final repository = HospitalSearchRepository(client: client);

    expect(
      () => repository.searchNearbyHospitals(
        const GeoPoint(latitude: 1, longitude: 1),
      ),
      throwsA(isA<HospitalSearchException>()),
    );
  });
}
