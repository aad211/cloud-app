import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_app/core/models/hospital_record.dart';
import 'package:cloud_app/features/hospitals/data/hospital_search_repository.dart';
import 'package:cloud_app/features/hospitals/data/location_service.dart';
import 'package:cloud_app/features/hospitals/presentation/hospitals_controller.dart';

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

void main() {
  test(
    'loadNearbyHospitals stores live results and search filters locally',
    () async {
      final container = ProviderContainer(
        overrides: [
          locationServiceProvider.overrideWithValue(
            _FakeLocationService(
              location: const GeoPoint(latitude: 1, longitude: 1),
            ),
          ),
          hospitalSearchRepositoryProvider.overrideWithValue(
            _FakeHospitalSearchRepository(
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
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(hospitalsControllerProvider.notifier);
      await notifier.loadNearbyHospitals();

      expect(
        container.read(hospitalsControllerProvider).status,
        NearbyHospitalsStatus.ready,
      );
      expect(
        container.read(hospitalsControllerProvider).hospitals,
        hasLength(2),
      );
      expect(
        container.read(hospitalsControllerProvider).filteredHospitals,
        hasLength(2),
      );

      notifier.updateSearchQuery('river');

      expect(
        container.read(hospitalsControllerProvider).filteredHospitals,
        hasLength(1),
      );
      expect(
        container
            .read(hospitalsControllerProvider)
            .filteredHospitals
            .single
            .name,
        'Riverside Hospital',
      );
    },
  );

  test('loadNearbyHospitals surfaces location permission failures', () async {
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(
          _FakeLocationService(
            error: const LocationServiceException(
              'Location permission is required to find nearby hospitals.',
            ),
          ),
        ),
        hospitalSearchRepositoryProvider.overrideWithValue(
          _FakeHospitalSearchRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(hospitalsControllerProvider.notifier);
    await notifier.loadNearbyHospitals();

    expect(
      container.read(hospitalsControllerProvider).status,
      NearbyHospitalsStatus.error,
    );
    expect(
      container.read(hospitalsControllerProvider).errorMessage,
      'Location permission is required to find nearby hospitals.',
    );
  });

  test('loadNearbyHospitals surfaces empty results', () async {
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(
          _FakeLocationService(
            location: const GeoPoint(latitude: 1, longitude: 1),
          ),
        ),
        hospitalSearchRepositoryProvider.overrideWithValue(
          _FakeHospitalSearchRepository(results: const []),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(hospitalsControllerProvider.notifier);
    await notifier.loadNearbyHospitals();

    expect(
      container.read(hospitalsControllerProvider).status,
      NearbyHospitalsStatus.empty,
    );
    expect(
      container.read(hospitalsControllerProvider).errorMessage,
      'No nearby hospitals were found for your location.',
    );
  });

  test('updateSearchQuery filters by name and address', () async {
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(
          _FakeLocationService(
            location: const GeoPoint(latitude: 1, longitude: 1),
          ),
        ),
        hospitalSearchRepositoryProvider.overrideWithValue(
          _FakeHospitalSearchRepository(
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
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(hospitalsControllerProvider.notifier);
    await notifier.loadNearbyHospitals();

    notifier.updateSearchQuery('westside');
    expect(
      container.read(hospitalsControllerProvider).filteredHospitals,
      hasLength(1),
    );
    expect(
      container.read(hospitalsControllerProvider).filteredHospitals.single.name,
      'Riverside Hospital',
    );
  });
}
