import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_app/app/theme/app_colors.dart';
import 'package:cloud_app/core/models/hospital_record.dart';
import 'package:cloud_app/core/widgets/parity_cards.dart';
import 'package:cloud_app/core/widgets/parity_page_header.dart';
import 'package:cloud_app/features/hospitals/data/hospital_seed.dart';

class HospitalsScreen extends StatefulWidget {
  const HospitalsScreen({super.key});

  @override
  State<HospitalsScreen> createState() => _HospitalsScreenState();
}

class _HospitalsScreenState extends State<HospitalsScreen> {
  String _query = '';

  List<HospitalRecord> get _filtered =>
      hospitalSeed
          .where((h) => h.name.toLowerCase().contains(_query.toLowerCase()))
          .toList();

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: _MockMapCard(),
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
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search hospital...',
                    hintStyle: const TextStyle(color: AppColors.blue),
                    prefixIcon: const Icon(Icons.search, color: AppColors.blue),
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
                child: Text(
                  'Nearby Hospitals (${filtered.length})',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    for (var index = 0; index < filtered.length; index++) ...[
                      _HospitalCard(hospital: filtered[index]),
                      if (index != filtered.length - 1)
                        const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockMapCard extends StatelessWidget {
  const _MockMapCard();

  @override
  Widget build(BuildContext context) {
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
          children: const [
            Positioned.fill(child: CustomPaint(painter: _MapTexturePainter())),
            Positioned(top: 18, left: 40, child: _HospitalMapPin()),
            Positioned(top: 48, right: 36, child: _HospitalMapPin()),
            Positioned(bottom: 34, left: 122, child: _HospitalMapPin()),
            Positioned(
              top: 64,
              left: 0,
              right: 0,
              child: Center(child: _UserMapPin()),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xE6FFFFFF),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    '📍 Your Location',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
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
  const _HospitalMapPin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: AppColors.danger,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.place, color: Colors.white, size: 18),
    );
  }
}

class _HospitalCard extends StatelessWidget {
  const _HospitalCard({required this.hospital});

  final HospitalRecord hospital;

  @override
  Widget build(BuildContext context) {
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
                '${hospital.distanceKm} km',
                style: const TextStyle(color: AppColors.blue, fontSize: 12),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.star, size: 16, color: AppColors.gold),
              const SizedBox(width: 4),
              Text(
                hospital.rating.toString(),
                style: const TextStyle(color: AppColors.blue, fontSize: 12),
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
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
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
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
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
}
