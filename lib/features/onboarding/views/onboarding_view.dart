import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/onboarding_controller.dart';
import '../../../core/theme/app_colors.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(OnboardingController());

    final pages = const [
      _OnboardPage(
        title: 'Find Your Ride',
        subtitle:
            'Search and book rides with verified drivers going your way. Safe, affordable, and convenient.',
        icon: Icons.directions_car_rounded,
        // Replace with your own images later:
        imageUrl:
            'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80',
      ),
      _OnboardPage(
        title: 'Share Your Journey',
        subtitle:
            'Offer rides to passengers and earn money while traveling. Connect with people on the go.',
        icon: Icons.group_rounded,
        imageUrl:
            'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80',
      ),
      _OnboardPage(
        title: 'Travel With Confidence',
        subtitle:
            'Verified profiles, secure payments, and 24/7 support. Your safety is our priority.',
        icon: Icons.shield_rounded,
        imageUrl:
            'https://images.unsplash.com/photo-1526481280695-3c687fd5432c?auto=format&fit=crop&w=1200&q=80',
        isLast: true,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  const Spacer(),
                  TextButton(onPressed: c.skip, child: const Text('Skip')),
                ],
              ),
            ),

            // pages
            Expanded(
              child: PageView(
                controller: c.pageController,
                onPageChanged: c.onPageChanged,
                children: pages,
              ),
            ),

            // dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Obx(() {
                final i = c.currentIndex.value;
                final isLast = i == 2;

                return Column(
                  children: [
                    _Dots(current: i),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isLast ? c.finish : c.next,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(isLast ? 'Get Started' : 'Next'),
                            const SizedBox(width: 10),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.imageUrl,
    this.isLast = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String imageUrl;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: Column(
        children: [
          const SizedBox(height: 18),

          // image card
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 18,
                  offset: Offset(0, 10),
                  color: Color(0x22000000),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(imageUrl, fit: BoxFit.cover),
                  Container(color: Colors.black.withOpacity(0.12)),
                  Center(
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(icon, color: AppColors.primary, size: 28),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: Theme.of(context).hintColor,
              ),
            ),
          ),

          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final selected = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: selected ? 18 : 6,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : const Color(0xFFD6D8DE),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}
