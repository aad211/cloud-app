import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_app/core/models/hospital_record.dart';
import 'package:cloud_app/features/hospitals/data/hospital_search_repository.dart';
import 'package:cloud_app/features/hospitals/data/location_service.dart';

enum NearbyHospitalsStatus {
  loadingLocation,
  loadingHospitals,
  ready,
  empty,
  error,
}

class HospitalsState {
  const HospitalsState({
    this.status = NearbyHospitalsStatus.loadingLocation,
    this.location,
    this.hospitals = const [],
    this.filteredHospitals = const [],
    this.searchQuery = '',
    this.errorMessage = '',
  });

  final NearbyHospitalsStatus status;
  final GeoPoint? location;
  final List<HospitalRecord> hospitals;
  final List<HospitalRecord> filteredHospitals;
  final String searchQuery;
  final String errorMessage;

  HospitalsState copyWith({
    NearbyHospitalsStatus? status,
    GeoPoint? location,
    List<HospitalRecord>? hospitals,
    List<HospitalRecord>? filteredHospitals,
    String? searchQuery,
    String? errorMessage,
  }) {
    return HospitalsState(
      status: status ?? this.status,
      location: location ?? this.location,
      hospitals: hospitals ?? this.hospitals,
      filteredHospitals: filteredHospitals ?? this.filteredHospitals,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class HospitalsController extends StateNotifier<HospitalsState> {
  HospitalsController(this.ref) : super(const HospitalsState());

  final Ref ref;

  Future<void> loadNearbyHospitals() async {
    state = state.copyWith(
      status: NearbyHospitalsStatus.loadingLocation,
      errorMessage: '',
      hospitals: const [],
      filteredHospitals: const [],
    );

    GeoPoint location;
    try {
      location = await ref.read(locationServiceProvider).getCurrentLocation();
    } on LocationServiceException catch (error) {
      state = state.copyWith(
        status: NearbyHospitalsStatus.error,
        errorMessage: error.message,
      );
      return;
    } catch (_) {
      state = state.copyWith(
        status: NearbyHospitalsStatus.error,
        errorMessage:
            'Unable to determine your location. Please try again.', // fallback for unexpected failures
      );
      return;
    }

    state = state.copyWith(
      status: NearbyHospitalsStatus.loadingHospitals,
      location: location,
    );

    try {
      final hospitals = await ref
          .read(hospitalSearchRepositoryProvider)
          .searchNearbyHospitals(location);
      final filtered = _filterHospitals(hospitals, state.searchQuery);
      state = state.copyWith(
        status:
            hospitals.isEmpty
                ? NearbyHospitalsStatus.empty
                : NearbyHospitalsStatus.ready,
        hospitals: hospitals,
        filteredHospitals: filtered,
        errorMessage:
            hospitals.isEmpty
                ? 'No nearby hospitals were found for your location.'
                : '',
      );
    } on HospitalSearchException catch (error) {
      state = state.copyWith(
        status: NearbyHospitalsStatus.error,
        errorMessage: error.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: NearbyHospitalsStatus.error,
        errorMessage: 'Unable to load nearby hospitals. Please try again.',
      );
    }
  }

  Future<void> retry() => loadNearbyHospitals();

  void updateSearchQuery(String query) {
    final normalized = query.trim();
    state = state.copyWith(
      searchQuery: normalized,
      filteredHospitals: _filterHospitals(state.hospitals, normalized),
    );
  }

  List<HospitalRecord> _filterHospitals(
    List<HospitalRecord> hospitals,
    String query,
  ) {
    if (query.isEmpty) {
      return hospitals;
    }

    final lower = query.toLowerCase();
    return hospitals
        .where(
          (hospital) =>
              hospital.name.toLowerCase().contains(lower) ||
              hospital.address.toLowerCase().contains(lower),
        )
        .toList();
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return const GeolocatorLocationService();
});

final hospitalsControllerProvider =
    StateNotifierProvider.autoDispose<HospitalsController, HospitalsState>(
      HospitalsController.new,
    );
