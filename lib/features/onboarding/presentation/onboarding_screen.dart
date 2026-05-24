import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ohok_flutter/app/theme/app_colors.dart';
import 'package:ohok_flutter/core/storage/local_storage_service.dart';
import 'package:ohok_flutter/features/onboarding/data/onboarding_slides.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  Future<void> _finish() async {
    final ok = await ref
        .read(localStorageServiceProvider)
        .setHasCompletedOnboarding(true);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save progress. Please try again.'),
        ),
      );
      return;
    }
    context.go('/home');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == onboardingSlides.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: isLast
                    ? const SizedBox(height: 48)
                    : TextButton(onPressed: _finish, child: const Text('Skip')),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemCount: onboardingSlides.length,
                  itemBuilder: (context, index) {
                    final pageSlide = onboardingSlides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(pageSlide.icon, style: const TextStyle(fontSize: 96)),
                        const SizedBox(height: 24),
                        Text(pageSlide.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, color: AppColors.navy)),
                        const SizedBox(height: 16),
                        Text(pageSlide.description, textAlign: TextAlign.center),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  onboardingSlides.length,
                  (dotIndex) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _index == dotIndex ? 32 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _index == dotIndex ? AppColors.navy : AppColors.sand,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (isLast) {
                    await _finish();
                    return;
                  }
                  await _controller.nextPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  minimumSize: const Size.fromHeight(56),
                ),
                child: Text(isLast ? 'Get Started' : 'Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
