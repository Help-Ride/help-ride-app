import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/controllers/session_controller.dart';
import '../../../shared/models/user.dart';
import '../controllers/profile_controller.dart';

class PassengerProfileView extends StatefulWidget {
  const PassengerProfileView({super.key});

  @override
  State<PassengerProfileView> createState() => _PassengerProfileViewState();
}

class _PassengerProfileViewState extends State<PassengerProfileView> {
  late final ProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    final theme = Get.find<ThemeController>();

    return Obx(() {
      final status = session.status.value;
      final isDark = theme.isDark.value;

      if (status == SessionStatus.unknown) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (status == SessionStatus.unauthenticated) {
        Future.microtask(() => Get.offAllNamed(AppRoutes.login));
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      final user = session.user.value;
      if (user == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      final isDriver = user.driverProfile != null || user.roleDefault == 'driver';
      final roleLabel = isDriver ? 'Driver' : 'Passenger';
      final isVerified =
          user.emailVerified || user.driverProfile?.isVerified == true;

      return Scaffold(
        backgroundColor: _surfaceBg(isDark),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary(isDark),
                ),
              ),
              const SizedBox(height: 14),
              _UserCard(
                user: user,
                roleLabel: roleLabel,
                roleColor: isDriver
                    ? AppColors.driverPrimary
                    : AppColors.passengerPrimary,
                isVerified: isVerified,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              if (isDriver || _controller.driverProfile.value != null) ...[
                _DriverProfileCard(
                  profile: _controller.driverProfile.value,
                  loading: _controller.driverLoading.value,
                  isDark: isDark,
                  onEdit: () => _openDriverEditSheet(
                    context,
                    _controller.driverProfile.value,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              _SectionLabel(label: 'ACCOUNT', isDark: isDark),
              const SizedBox(height: 8),
              _ActionGroup(
                items: [
                  _ActionItem(
                    icon: Icons.person_outline,
                    label: 'Personal Information',
                    onTap: () => _openUserEditSheet(context, user),
                  ),
                  const _ActionItem(
                    icon: Icons.lock_outline,
                    label: 'Email & Password',
                  ),
                  const _ActionItem(
                    icon: Icons.phone_outlined,
                    label: 'Phone Number',
                  ),
                  const _ActionItem(
                    icon: Icons.verified_user_outlined,
                    label: 'Verification',
                  ),
                ],
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _SectionLabel(label: 'PREFERENCES', isDark: isDark),
              const SizedBox(height: 8),
              _ActionGroup(
                items: const [
                  _ActionItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                  ),
                  _ActionItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                  ),
                ],
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _SectionLabel(label: 'SUPPORT', isDark: isDark),
              const SizedBox(height: 8),
              _ActionGroup(
                items: const [
                  _ActionItem(
                    icon: Icons.help_outline,
                    label: 'Help Center',
                  ),
                  _ActionItem(
                    icon: Icons.policy_outlined,
                    label: 'Terms & Privacy',
                  ),
                ],
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _LogoutCard(
                onLogout: () async {
                  await session.logout();
                  Get.offAllNamed(AppRoutes.login);
                },
                isDark: isDark,
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: _mutedText(isDark),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _openUserEditSheet(BuildContext context, User user) async {
    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone ?? '');
    final avatarCtrl = TextEditingController(text: user.avatarUrl ?? '');

    await _showEditSheet(
      context,
      title: 'Edit Profile',
      child: Column(
        children: [
          _EditField(controller: nameCtrl, label: 'Full name'),
          const SizedBox(height: 12),
          _EditField(
            controller: phoneCtrl,
            label: 'Phone number',
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-()\s]')),
            ],
          ),
          const SizedBox(height: 12),
          _EditField(
            controller: avatarCtrl,
            label: 'Avatar URL',
            keyboardType: TextInputType.url,
          ),
        ],
      ),
      onSave: () async {
        try {
          await _controller.updateUserProfile(
            name: nameCtrl.text,
            phone: phoneCtrl.text,
            avatarUrl: avatarCtrl.text,
          );
          return true;
        } catch (e) {
          _showError(context, e);
          return false;
        }
      },
      isSaving: _controller.loading,
    );
  }

  Future<void> _openDriverEditSheet(
    BuildContext context,
    DriverProfile? profile,
  ) async {
    final makeCtrl = TextEditingController(text: profile?.carMake ?? '');
    final modelCtrl = TextEditingController(text: profile?.carModel ?? '');
    final yearCtrl = TextEditingController(text: profile?.carYear ?? '');
    final colorCtrl = TextEditingController(text: profile?.carColor ?? '');
    final plateCtrl = TextEditingController(text: profile?.plateNumber ?? '');
    final licenseCtrl = TextEditingController(text: profile?.licenseNumber ?? '');
    final insuranceCtrl =
        TextEditingController(text: profile?.insuranceInfo ?? '');

    await _showEditSheet(
      context,
      title: profile == null ? 'Create Driver Profile' : 'Edit Driver Profile',
      child: Column(
        children: [
          _EditField(controller: makeCtrl, label: 'Car make'),
          const SizedBox(height: 12),
          _EditField(controller: modelCtrl, label: 'Car model'),
          const SizedBox(height: 12),
          _EditField(
            controller: yearCtrl,
            label: 'Car year',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _EditField(controller: colorCtrl, label: 'Car color'),
          const SizedBox(height: 12),
          _EditField(controller: plateCtrl, label: 'Plate number'),
          const SizedBox(height: 12),
          _EditField(controller: licenseCtrl, label: 'License number'),
          const SizedBox(height: 12),
          _EditField(controller: insuranceCtrl, label: 'Insurance info'),
        ],
      ),
      onSave: () async {
        try {
          await _controller.upsertDriverProfile(
            carMake: makeCtrl.text,
            carModel: modelCtrl.text,
            carYear: yearCtrl.text,
            carColor: colorCtrl.text,
            plateNumber: plateCtrl.text,
            licenseNumber: licenseCtrl.text,
            insuranceInfo: insuranceCtrl.text,
          );
          return true;
        } catch (e) {
          _showError(context, e);
          return false;
        }
      },
      isSaving: _controller.driverLoading,
    );
  }

  Future<void> _showEditSheet(
    BuildContext context, {
    required String title,
    required Widget child,
    required Future<bool> Function() onSave,
    required RxBool isSaving,
  }) {
    final isDark = Get.find<ThemeController>().isDark.value;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surfaceCard(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            16,
            18,
            16 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6EAF2),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary(isDark),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (Navigator.of(sheetContext).canPop()) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                    icon: const Icon(Icons.close),
                    color: _mutedText(isDark),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              child,
              const SizedBox(height: 16),
              Obx(() {
                final saving = isSaving.value;
                return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final ok = await onSave();
                            if (!ok) return;
                            if (Navigator.of(sheetContext).canPop()) {
                              Navigator.of(sheetContext).pop();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.passengerPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showError(BuildContext context, Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.roleLabel,
    required this.roleColor,
    required this.isVerified,
    required this.isDark,
  });

  final User user;
  final String roleLabel;
  final Color roleColor;
  final bool isVerified;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarUrl ?? '';
    final initials = _initialsFor(user.name);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceCard(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder(isDark)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor:
                isDark ? const Color(0xFF1C2331) : const Color(0xFFE9EEF6),
            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty
                ? Text(
                    initials.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.lightText,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.isNotEmpty ? user.name : 'User',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    color: _mutedText(isDark),
                    fontSize: 13,
                  ),
                ),
                if ((user.phone ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      user.phone!,
                      style: TextStyle(
                        color: _mutedText(isDark),
                        fontSize: 13,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _TagChip(
                      label: roleLabel,
                      textColor: roleColor,
                      background:
                          roleColor.withOpacity(isDark ? 0.22 : 0.12),
                    ),
                    if (isVerified)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _TagChip(
                          label: 'Verified',
                          textColor: _textPrimary(isDark),
                          background: _chipNeutralBg(isDark),
                          icon: Icons.verified_outlined,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initialsFor(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    return parts.take(2).map((part) => part[0]).join();
  }
}

class _DriverProfileCard extends StatelessWidget {
  const _DriverProfileCard({
    required this.profile,
    required this.loading,
    required this.isDark,
    required this.onEdit,
  });

  final DriverProfile? profile;
  final bool loading;
  final bool isDark;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 6),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _driverCardBg(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _driverCardBorder(isDark)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car, color: AppColors.driverPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Driver Profile',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: _textPrimary(isDark),
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                color: AppColors.driverPrimary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DriverInfoRow(
            label: 'Vehicle',
            value: _joinParts(profile?.carMake, profile?.carModel),
            isDark: isDark,
          ),
          _DriverInfoRow(label: 'Year', value: profile?.carYear, isDark: isDark),
          _DriverInfoRow(label: 'Color', value: profile?.carColor, isDark: isDark),
          _DriverInfoRow(
            label: 'License Plate',
            value: profile?.plateNumber,
            isDark: isDark,
          ),
          _DriverInfoRow(
            label: 'License No.',
            value: profile?.licenseNumber,
            isDark: isDark,
          ),
          _DriverInfoRow(
            label: 'Insurance',
            value: profile?.insuranceInfo,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status',
                style: TextStyle(color: _mutedText(isDark), fontSize: 13),
              ),
              _StatusPill(
                isActive: profile?.isVerified == true,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _joinParts(String? a, String? b) {
    final parts = [a, b].where((p) => p != null && p.trim().isNotEmpty).toList();
    return parts.isEmpty ? '—' : parts.join(' ');
  }
}

class _DriverInfoRow extends StatelessWidget {
  const _DriverInfoRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String? value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: _mutedText(isDark),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              (value == null || value!.trim().isEmpty) ? '—' : value!,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: _textPrimary(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isActive, required this.isDark});

  final bool isActive;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isActive
        ? (isDark ? const Color(0xFF14382B) : const Color(0xFFE8FAF3))
        : _chipNeutralBg(isDark);
    final color = isActive ? AppColors.passengerPrimary : _mutedText(isDark);
    final label = isActive ? 'Active' : 'Pending';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.textColor,
    required this.background,
    this.icon,
  });

  final String label;
  final Color textColor;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(icon, size: 14, color: textColor),
            ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: _mutedText(isDark),
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    );
  }
}

class _ActionGroup extends StatelessWidget {
  const _ActionGroup({required this.items, required this.isDark});

  final List<_ActionItem> items;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceCard(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder(isDark)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _ProfileActionTile(item: items[i], isDark: isDark),
            if (i != items.length - 1)
              Divider(height: 1, color: _cardDivider(isDark)),
          ],
        ],
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    this.onTap,
  });
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({required this.item, required this.isDark});

  final _ActionItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: item.onTap,
      leading: Icon(item.icon, color: _mutedText(isDark)),
      title: Text(
        item.label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: _textPrimary(isDark),
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: _mutedText(isDark)),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onLogout, required this.isDark});

  final VoidCallback onLogout;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceCard(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder(isDark)),
      ),
      child: ListTile(
        onTap: onLogout,
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text(
          'Log out',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w700,
          ),
        ),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _mutedText(Get.find<ThemeController>().isDark.value)),
        filled: true,
        fillColor: _fieldFill(Get.find<ThemeController>().isDark.value),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

Color _surfaceBg(bool isDark) => isDark ? AppColors.darkBg : AppColors.lightBg;

Color _surfaceCard(bool isDark) =>
    isDark ? AppColors.darkSurface : Colors.white;

Color _cardBorder(bool isDark) =>
    isDark ? const Color(0xFF232836) : const Color(0xFFE6EAF2);

Color _cardDivider(bool isDark) =>
    isDark ? const Color(0xFF1C202B) : const Color(0xFFF1F3F7);

Color _mutedText(bool isDark) =>
    isDark ? AppColors.darkMuted : AppColors.lightMuted;

Color _textPrimary(bool isDark) =>
    isDark ? AppColors.darkText : AppColors.lightText;

Color _chipNeutralBg(bool isDark) =>
    isDark ? const Color(0xFF1E222D) : const Color(0xFFF1F3F7);

Color _driverCardBg(bool isDark) =>
    isDark ? const Color(0xFF122033) : const Color(0xFFEFF6FF);

Color _driverCardBorder(bool isDark) =>
    isDark ? const Color(0xFF1B2C44) : const Color(0xFFD8E6FF);

Color _fieldFill(bool isDark) =>
    isDark ? const Color(0xFF1C2331) : const Color(0xFFF3F5F8);
