import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/controllers/session_controller.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/routes/app_routes.dart';

class PassengerProfileView extends StatelessWidget {
  const PassengerProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    final theme = Get.find<ThemeController>();

    return Obx(() {
      // Guard: only kick out on unauthenticated (NOT unknown)
      final s = session.status.value;

      if (s == SessionStatus.unknown) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (s == SessionStatus.unauthenticated) {
        Future.microtask(() => Get.offAllNamed(AppRoutes.login));
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      // ✅ authenticated
      final u = session.user.value ?? {};
      final name = (u['name'] ?? u['fullName'] ?? 'Passenger') as String;
      final email = (u['email'] ?? '—') as String;
      final phone = (u['phone'] ?? '—') as String;
      final location = (u['location'] ?? u['city'] ?? '—') as String;

      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            // theme toggle (since you asked)
            Obx(
              () => Switch(
                value: theme.isDark.value,
                onChanged: (bool value) {
                  theme.setDark(value);
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await session.logout();
                Get.offAllNamed(AppRoutes.login);
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ProfileHeader(name: name, role: "session.role"),
            const SizedBox(height: 16),

            _SectionCard(
              title: 'Contact Information',
              children: [
                _InfoRow(icon: Icons.phone, label: 'Phone', value: phone),
                _InfoRow(icon: Icons.email, label: 'Email', value: email),
                _InfoRow(
                  icon: Icons.location_on,
                  label: 'Location',
                  value: location,
                ),
              ],
            ),

            const SizedBox(height: 16),
            _SectionCard(
              title: 'Account',
              children: [
                _InfoRow(
                  icon: Icons.verified_user,
                  label: 'Role',
                  value: "session.role",
                ),
                _InfoRow(
                  icon: Icons.badge,
                  label: 'User ID',
                  value: '${u['id'] ?? '—'}',
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name, required this.role});
  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 28, child: Icon(Icons.person, size: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.15),
                  ),
                  child: Text(
                    role,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(radius: 18, child: Icon(icon, size: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
