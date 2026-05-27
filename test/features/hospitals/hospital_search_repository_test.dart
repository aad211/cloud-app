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
      expect(request.url.queryParameters.containsKey('countrycode'), isFalse);
      expect(
        request.url.queryParameters['bbox'],
        '0.775388,0.775422,1.224612,1.224578',
      );
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

  test('falls back to the proxy when Photon returns 403', () async {
    var directCalls = 0;
    var proxyCalls = 0;
    final client = MockClient((request) async {
      if (request.url.host == 'photon.komoot.io') {
        directCalls += 1;
        return http.Response('forbidden', 403);
      }

      if (request.url.host == 'r.jina.ai') {
        proxyCalls += 1;
        return http.Response('''
Title:

URL Source: http://photon.komoot.io/api/?q=hospital&bbox=0.775388,0.775422,1.224612,1.224578&limit=100

Markdown Content:
{"type":"FeatureCollection","features":[{"geometry":{"coordinates":[1.001,1.001]},"properties":{"name":"Proxy Hospital","street":"Proxy St","city":"Proxy City"}}]}
''', 200);
      }

      throw StateError('Unexpected host ${request.url.host}');
    });
    addTearDown(client.close);

    final repository = HospitalSearchRepository(client: client);
    final hospitals = await repository.searchNearbyHospitals(
      const GeoPoint(latitude: 1, longitude: 1),
    );

    expect(directCalls, 1);
    expect(proxyCalls, 1);
    expect(hospitals, hasLength(1));
    expect(hospitals.single.name, 'Proxy Hospital');
  });
}
