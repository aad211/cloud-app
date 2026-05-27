import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_app/app/theme/app_colors.dart';
import 'package:cloud_app/core/models/hospital_record.dart';
import 'package:cloud_app/core/widgets/parity_page_header.dart';
import 'package:cloud_app/features/hospitals/presentation/hospitals_controller.dart';

class HospitalsScreen extends ConsumerStatefulWidget {
  const HospitalsScreen({super.key});

  @override
  ConsumerState<HospitalsScreen> createState() => _HospitalsScreenState();
}

class _HospitalsScreenState extends ConsumerState<HospitalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(hospitalsControllerProvider.notifier).loadNearbyHospitals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hospitalsControllerProvider);
    final notifier = ref.read(hospitalsControllerProvider.notifier);
    final hospitals = state.filteredHospitals;
    final showSearchEmpty =
        state.status == NearbyHospitalsStatus.ready &&
        state.searchQuery.isNotEmpty &&
        hospitals.isEmpty;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ParityPageHeader(
                  title: 'Nearby Hospitals',
                  subtitle: 'Find medical help near you',
                  onBack: () => context.go('/home'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.blue,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              state.location == null
                                  ? 'Finding your location...'
                                  : '${state.location!.latitude.toStringAsFixed(3)}, ${state.location!.longitude.toStringAsFixed(3)}',
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        onChanged: notifier.updateSearchQuery,
                        decoration: InputDecoration(
                          hintText: 'Search hospital...',
                          hintStyle: const TextStyle(color: AppColors.blue),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.blue,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.sand,
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.blue,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nearby Hospitals (${hospitals.length})',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (state.status == NearbyHospitalsStatus.loadingLocation ||
                          state.status == NearbyHospitalsStatus.loadingHospitals)
                        const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (state.status == NearbyHospitalsStatus.loadingLocation ||
                    state.status == NearbyHospitalsStatus.loadingHospitals)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: _StateCard(
                      icon: Icons.location_searching,
                      title: 'Finding nearby hospitals',
                      message:
                          'We are getting your location and loading live hospital results.',
                    ),
                  )
                else if (state.status == NearbyHospitalsStatus.error)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _StateCard(
                      icon: Icons.error_outline,
                      title: 'Unable to load nearby hospitals',
                      message: state.errorMessage,
                      actionLabel: 'Retry',
                      onAction: notifier.retry,
                    ),
                  )
                else if (state.status == NearbyHospitalsStatus.empty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: _StateCard(
                      icon: Icons.local_hospital_outlined,
                      title: 'No nearby hospitals found',
                      message:
                          'Try again after moving or enabling location access.',
                    ),
                  )
                else if (showSearchEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: _StateCard(
                      icon: Icons.search_off,
                      title: 'No matching hospitals',
                      message:
                          'Clear the search field to show all live results again.',
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < hospitals.length;
                          index++
                        ) ...[
                          _HospitalCard(hospital: hospitals[index]),
                          if (index != hospitals.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HospitalCard extends StatelessWidget {
  const _HospitalCard({required this.hospital});

  final HospitalRecord hospital;

  @override
  Widget build(BuildContext context) {
    final hasPhone = hospital.phone != null && hospital.phone!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sand, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hospital.name,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 16, color: AppColors.blue),
              const SizedBox(width: 4),
              Text(
                '${hospital.distanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(color: AppColors.blue, fontSize: 12),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.disclaimerBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Live',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hospital.address,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (hasPhone) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      launchUrl(Uri.parse('tel:${hospital.phone}'));
                    },
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _openDirections(hospital);
                  },
                  icon: const Icon(Icons.navigation, size: 16),
                  label: const Text('Directions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openDirections(HospitalRecord hospital) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${hospital.latitude},${hospital.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sand, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.blue, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  onAction!();
                },
                child: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
