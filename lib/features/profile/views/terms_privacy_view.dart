import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';

class TermsPrivacyView extends StatelessWidget {
  const TermsPrivacyView({super.key});

  static const String _supportEmail = 'support@help-ride.app';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        elevation: 0,
        foregroundColor: textPrimary,
        title: const Text(
          'Terms & Privacy',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          children: [
            Text(
              'Quick summary',
              style: TextStyle(
                color: textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            _Card(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bullet(
                    isDark: isDark,
                    text:
                        'Be respectful and follow local laws. Unsafe or abusive behavior can lead to account restrictions.',
                  ),
                  const SizedBox(height: 8),
                  _Bullet(
                    isDark: isDark,
                    text:
                        'We collect only what we need to provide the service (like account info and trip data).',
                  ),
                  const SizedBox(height: 8),
                  _Bullet(
                    isDark: isDark,
                    text:
                        'Location may be used to match rides, provide navigation context, and improve safety.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Card(
              isDark: isDark,
              child: Column(
                children: [
                  _PolicyTile(
                    isDark: isDark,
                    title: 'Terms of Service (simple)',
                    subtitle: 'How the app works and what’s expected.',
                    icon: Icons.policy_outlined,
                    children: const [
                      _PolicySection(
                        title: 'Using the app',
                        body:
                            'Help Ride helps passengers request rides and helps drivers offer rides. By using the app you agree to use it responsibly and to provide accurate information.',
                      ),
                      _PolicySection(
                        title: 'Safety and conduct',
                        body:
                            'Treat others with respect. Do not harass, discriminate, threaten, or attempt to misuse the platform. If we believe the app is being used in a harmful way, we may suspend or close accounts.',
                      ),
                      _PolicySection(
                        title: 'Payments and pricing',
                        body:
                            'Prices and fees shown in the app are estimates unless stated otherwise. Payments are processed through supported payment providers. Refunds and disputes depend on ride status and provider rules.',
                      ),
                      _PolicySection(
                        title: 'Cancellations',
                        body:
                            'Trips may be cancelled by passengers or drivers. Repeated cancellations or abusive behavior may result in limits or suspension.',
                      ),
                      _PolicySection(
                        title: 'No guarantee',
                        body:
                            'We try to provide a reliable service, but we can’t guarantee that a ride will always be available or that the app will be error-free.',
                      ),
                    ],
                  ),
                  Divider(height: 1, color: _cardDivider(isDark)),
                  _PolicyTile(
                    isDark: isDark,
                    title: 'Privacy Policy (simple)',
                    subtitle: 'What data we collect and why.',
                    icon: Icons.privacy_tip_outlined,
                    children: const [
                      _PolicySection(
                        title: 'What we collect',
                        body:
                            'We may collect account details (name, email, phone), trip details (pickup/drop-off, time), and device/app signals (for reliability and security).',
                      ),
                      _PolicySection(
                        title: 'Location data',
                        body:
                            'If you grant permission, we may use location to suggest pickups, match rides, and improve safety. You can change location permissions in your device settings.',
                      ),
                      _PolicySection(
                        title: 'How we use data',
                        body:
                            'We use data to run the service, provide support, prevent fraud, and improve features. We do not sell your personal data.',
                      ),
                      _PolicySection(
                        title: 'Sharing',
                        body:
                            'We share data only when needed to provide the service (e.g., payment processing, messaging), to comply with law, or to protect users and the platform.',
                      ),
                      _PolicySection(
                        title: 'Retention and security',
                        body:
                            'We keep data only as long as needed for operations and legal obligations. We use reasonable safeguards, but no system is 100% secure.',
                      ),
                    ],
                  ),
                  Divider(height: 1, color: _cardDivider(isDark)),
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    leading: Icon(Icons.mail_outline, color: muted),
                    title: Text(
                      'Contact',
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      _supportEmail,
                      style: TextStyle(color: muted, fontWeight: FontWeight.w600),
                    ),
                    trailing: IconButton(
                      tooltip: 'Copy email',
                      onPressed: () async {
                        await Clipboard.setData(
                          const ClipboardData(text: _supportEmail),
                        );
                        Get.snackbar('Copied', 'Support email copied.');
                      },
                      icon: Icon(Icons.copy_rounded, color: muted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This page is a simple, human-readable summary and may be updated. For legal terms, please contact support.',
              style: TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.isDark, required this.child});
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder(isDark)),
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }
}

class _PolicyTile extends StatelessWidget {
  const _PolicyTile({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  final bool isDark;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: Icon(icon, color: muted),
        title: Text(
          title,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: muted, fontWeight: FontWeight.w600),
        ),
        iconColor: muted,
        collapsedIconColor: muted,
        children: children,
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              color: muted,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.isDark, required this.text});
  final bool isDark;
  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(Icons.circle, size: 6, color: muted),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: muted,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

Color _cardBorder(bool isDark) =>
    isDark ? const Color(0xFF232836) : const Color(0xFFE6EAF2);

Color _cardDivider(bool isDark) =>
    isDark ? const Color(0xFF1C202B) : const Color(0xFFF1F3F7);

