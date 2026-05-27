import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_app/app/theme/app_colors.dart';
import 'package:cloud_app/core/models/hospital_record.dart';
import 'package:cloud_app/core/widgets/parity_cards.dart';
import 'package:cloud_app/core/widgets/parity_page_header.dart';
import 'package:cloud_app/features/hospitals/data/location_service.dart';
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
                  child: _LiveHospitalMapCard(
                    location: state.location,
                    hospitals: hospitals,
                    status: state.status,
                    errorMessage: state.errorMessage,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🚨', style: TextStyle(fontSize: 24)),
                          SizedBox(width: 10),
                          Text(
                            'Emergency Call',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: ParityInfoCard(
                    backgroundColor: AppColors.disclaimerBackground,
                    leading: Icon(
                      Icons.info_outline,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    child: Text(
                      'Based on your symptoms, we recommend visiting a hospital for professional evaluation.',
                      style: TextStyle(color: AppColors.warning, fontSize: 14),
                    ),
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
                      if (state.status ==
                              NearbyHospitalsStatus.loadingLocation ||
                          state.status ==
                              NearbyHospitalsStatus.loadingHospitals)
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

class _LiveHospitalMapCard extends StatelessWidget {
  const _LiveHospitalMapCard({
    required this.location,
    required this.hospitals,
    required this.status,
    required this.errorMessage,
  });

  final GeoPoint? location;
  final List<HospitalRecord> hospitals;
  final NearbyHospitalsStatus status;
  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    final pins = hospitals.take(3).toList(growable: false);
    final statusLabel = switch (status) {
      NearbyHospitalsStatus.loadingLocation => 'Finding your location...',
      NearbyHospitalsStatus.loadingHospitals =>
        'Loading live hospital results...',
      NearbyHospitalsStatus.error => 'Nearby hospital lookup failed.',
      NearbyHospitalsStatus.empty =>
        'No nearby hospitals found for the current location.',
      NearbyHospitalsStatus.ready => 'Live nearby hospital results',
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 192,
        decoration: const BoxDecoration(
          color: Color(0xFFE0F2FE),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A1A3263),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _MapTexturePainter()),
            ),
            const Positioned(top: 18, left: 40, child: _HospitalMapPin()),
            const Positioned(top: 48, right: 36, child: _HospitalMapPin()),
            const Positioned(bottom: 34, left: 122, child: _HospitalMapPin()),
            Positioned(
              top: 64,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _UserMapPin(),
                    if (location != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${location!.latitude.toStringAsFixed(3)}, ${location!.longitude.toStringAsFixed(3)}',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0xE6FFFFFF),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            if (pins.isNotEmpty)
              for (var index = 0; index < pins.length; index++)
                Positioned(
                  top: 18 + (index * 34),
                  right: 24 + (index * 10),
                  child: _HospitalMapPin(label: '${index + 1}'),
                ),
          ],
        ),
      ),
    );
  }
}

class _MapTexturePainter extends CustomPainter {
  const _MapTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.28)
          ..strokeWidth = 1;
    const gap = 20.0;

    for (double x = 0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _UserMapPin extends StatelessWidget {
  const _UserMapPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.navy,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.place, color: Colors.white, size: 22),
        ),
        Container(width: 4, height: 12, color: AppColors.navy),
      ],
    );
  }
}

class _HospitalMapPin extends StatelessWidget {
  const _HospitalMapPin({this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: AppColors.danger,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child:
          label == null
              ? const Icon(Icons.place, color: Colors.white, size: 18)
              : Text(
                label!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
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
