import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_app/core/models/hospital_record.dart';
import 'package:cloud_app/features/hospitals/data/hospital_search_repository.dart';
import 'package:cloud_app/features/hospitals/data/location_service.dart';
import 'package:cloud_app/features/hospitals/presentation/hospitals_screen.dart';
import 'package:cloud_app/features/hospitals/presentation/hospitals_controller.dart';

class _CompleterLocationService implements LocationService {
  _CompleterLocationService() : completer = Completer<GeoPoint>();

  final Completer<GeoPoint> completer;

  @override
  Future<GeoPoint> getCurrentLocation() => completer.future;
}

class _FakeLocationService implements LocationService {
  _FakeLocationService({this.location, this.error});

  final GeoPoint? location;
  final Object? error;

  @override
  Future<GeoPoint> getCurrentLocation() async {
    if (error != null) {
      throw error!;
    }
    return location!;
  }
}

class _FakeHospitalSearchRepository extends HospitalSearchRepository {
  _FakeHospitalSearchRepository({this.results = const []})
    : super(client: http.Client());

  final List<HospitalRecord> results;

  @override
  Future<List<HospitalRecord>> searchNearbyHospitals(GeoPoint location) async {
    return results;
  }
}

Widget _buildHarness({
  required LocationService locationService,
  required HospitalSearchRepository repository,
}) {
  final router = GoRouter(
    initialLocation: '/hospitals',
    routes: [
      GoRoute(path: '/hospitals', builder: (_, __) => const HospitalsScreen()),
      GoRoute(
        path: '/home',
        builder:
            (_, __) =>
                const Scaffold(body: Center(child: Text('Home Destination'))),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      locationServiceProvider.overrideWithValue(locationService),
      hospitalSearchRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('shows a loading state while location is pending', (
    tester,
  ) async {
    final locationService = _CompleterLocationService();
    final repository = _FakeHospitalSearchRepository();

    await tester.pumpWidget(
      _buildHarness(locationService: locationService, repository: repository),
    );
    await tester.pump();

    expect(find.text('Finding nearby hospitals'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders live results and hides call when phone is missing', (
    tester,
  ) async {
    final locationService = _FakeLocationService(
      location: const GeoPoint(latitude: 1, longitude: 1),
    );
    final repository = _FakeHospitalSearchRepository(
      results: const [
        HospitalRecord(
          name: 'City General Hospital',
          distanceKm: 1.2,
          address: '123 Main St, Downtown',
          latitude: 1.001,
          longitude: 1.001,
          phone: '+1 555-0101',
        ),
        HospitalRecord(
          name: 'Riverside Hospital',
          distanceKm: 2.5,
          address: '321 River St, Westside',
          latitude: 1.02,
          longitude: 1.02,
        ),
      ],
    );

    await tester.pumpWidget(
      _buildHarness(locationService: locationService, repository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nearby Hospitals (2)'), findsOneWidget);
    expect(find.text('City General Hospital'), findsOneWidget);
    expect(find.text('Riverside Hospital'), findsOneWidget);
    expect(find.text('Call'), findsOneWidget);
    expect(find.text('Directions'), findsNWidgets(2));
  });

  testWidgets('filters live results by search query', (tester) async {
    final locationService = _FakeLocationService(
      location: const GeoPoint(latitude: 1, longitude: 1),
    );
    final repository = _FakeHospitalSearchRepository(
      results: const [
        HospitalRecord(
          name: 'City General Hospital',
          distanceKm: 1.2,
          address: '123 Main St, Downtown',
          latitude: 1.001,
          longitude: 1.001,
        ),
        HospitalRecord(
          name: 'Riverside Hospital',
          distanceKm: 2.5,
          address: '321 River St, Westside',
          latitude: 1.02,
          longitude: 1.02,
        ),
      ],
    );

    await tester.pumpWidget(
      _buildHarness(locationService: locationService, repository: repository),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Search hospital...'),
      'westside',
    );
    await tester.pump();

    expect(find.text('City General Hospital'), findsNothing);
    expect(find.text('Riverside Hospital'), findsOneWidget);
    expect(find.text('No matching hospitals'), findsNothing);
  });

  testWidgets('shows an error state when location access fails', (
    tester,
  ) async {
    final locationService = _FakeLocationService(
      error: const LocationServiceException(
        'Location permission is required to find nearby hospitals.',
      ),
    );
    final repository = _FakeHospitalSearchRepository();

    await tester.pumpWidget(
      _buildHarness(locationService: locationService, repository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load nearby hospitals'), findsOneWidget);
    expect(
      find.text('Location permission is required to find nearby hospitals.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('routes home from parity back button', (tester) async {
    final locationService = _FakeLocationService(
      location: const GeoPoint(latitude: 1, longitude: 1),
    );
    final repository = _FakeHospitalSearchRepository(results: const []);

    await tester.pumpWidget(
      _buildHarness(locationService: locationService, repository: repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Home Destination'), findsOneWidget);
  });
}
