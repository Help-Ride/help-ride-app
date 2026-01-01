import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/custom_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OnboardingController>(
      init: OnboardingController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            automaticallyImplyLeading: false,
            actions: [
              TextButton(
                onPressed: controller.skip,
                child: Text(
                  "Skip",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xff4A5565),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              // Full PageView for Image + Title + Subtitle
              PageView.builder(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                itemCount: controller.pages.length,
                itemBuilder: (context, index) {
                  final page = controller.pages[index];

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        SizedBox(height: 80),

                        Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Image.asset(
                                page["image"]!,
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Container(
                              height: 100,
                              width: 100,
                              padding: EdgeInsets.all(12),
                              child: Image.asset(
                                AppImages.carImage,
                              ), // Same logo on all
                            ),
                          ],
                        ),

                        SizedBox(height: 30),

                        Text(
                          page["title"]!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xff101828),
                          ),
                        ),

                        SizedBox(height: 16),

                        Text(
                          page["subtitle"]!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xff4A5565),
                          ),
                        ),

                        SizedBox(height: 22),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            controller.pages.length,
                                (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: EdgeInsets.symmetric(horizontal: 6),
                              height: 8,
                              width: controller.pageIndex == i ? 24 : 8,
                              decoration: BoxDecoration(
                                gradient: controller.pageIndex == i
                                    ? const LinearGradient(
                                  colors: [
                                    Color(0xFF00BC7D),
                                    Color(0xFF009689),
                                  ],
                                )
                                    : LinearGradient(
                                  colors: [
                                    Colors.grey.shade300,
                                    Colors.grey.shade400,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),

              Positioned(
                bottom: 40,
                left: 32,
                right: 32,
                child: CustomButton(
                  text: controller.pageIndex == controller.pages.length - 1
                      ? "Get Started"
                      : "Next",
                  fontSize: 14,
                  fontWeight: FontWeight.w500,

                  gradientColors: const [
                    Color(0xFF00BC7D),
                    Color(0xFF009689)
                  ],
                  icon: Icons.arrow_forward_ios,
                  onTap: controller.nextPage,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
