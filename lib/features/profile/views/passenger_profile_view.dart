import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:mime/mime.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/controllers/session_controller.dart';
import '../../../shared/models/user.dart';
import '../../../shared/utils/input_validators.dart';
import '../../../shared/widgets/app_input_decoration.dart';
import '../models/driver_document.dart';
import '../../support/routes/support_routes.dart';
import '../routes/profile_routes.dart';
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

      final isDriver =
          user.driverProfile != null || user.roleDefault == 'driver';
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
                  _ActionItem(icon: Icons.settings_outlined, label: 'Settings'),
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
                items: [
                  _ActionItem(
                    icon: Icons.help_outline,
                    label: 'Help Center',
                    onTap: () => Get.toNamed(SupportRoutes.tickets),
                  ),
                  _ActionItem(
                    icon: Icons.policy_outlined,
                    label: 'Terms & Privacy',
                    onTap: () => Get.toNamed(ProfileRoutes.termsPrivacy),
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
    final formKey = GlobalKey<FormState>();

    await _showEditSheet(
      context,
      title: 'Edit Profile',
      formKey: formKey,
      child: Column(
        children: [
          _EditField(
            controller: nameCtrl,
            label: 'Full name',
            validator: (value) => InputValidators.minLength(
              value ?? '',
              fieldLabel: 'Full name',
              minChars: 2,
            ),
          ),
          const SizedBox(height: 12),
          _EditField(
            controller: phoneCtrl,
            label: 'Phone number',
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-()\s]')),
            ],
            validator: (value) => InputValidators.optionalPhone(value ?? ''),
          ),
          const SizedBox(height: 12),
          _EditField(
            controller: avatarCtrl,
            label: 'Avatar URL',
            keyboardType: TextInputType.url,
            validator: (value) => InputValidators.optionalUrl(value ?? ''),
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
    final licenseCtrl = TextEditingController(
      text: profile?.licenseNumber ?? '',
    );
    final insuranceCtrl = TextEditingController(
      text: profile?.insuranceInfo ?? '',
    );
    _controller.refreshDriverDocuments();
    final formKey = GlobalKey<FormState>();

    await _showEditSheet(
      context,
      title: profile == null ? 'Create Driver Profile' : 'Edit Driver Profile',
      formKey: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetSectionTitle(
            title: 'Vehicle Information',
            subtitle: 'Keep these details aligned with your onboarding info.',
            isDark: Get.find<ThemeController>().isDark.value,
          ),
          const SizedBox(height: 12),
          _EditField(
            controller: makeCtrl,
            label: 'Car make',
            validator: (value) => InputValidators.requiredText(
              value ?? '',
              fieldLabel: 'Car make',
            ),
          ),
          const SizedBox(height: 12),
          _EditField(
            controller: modelCtrl,
            label: 'Car model',
            validator: (value) => InputValidators.requiredText(
              value ?? '',
              fieldLabel: 'Car model',
            ),
          ),
          const SizedBox(height: 12),
          _EditField(
            controller: yearCtrl,
            label: 'Car year',
            keyboardType: TextInputType.number,
            validator: (value) => InputValidators.optionalYear(value ?? ''),
          ),
          const SizedBox(height: 12),
          _EditField(controller: colorCtrl, label: 'Car color'),
          const SizedBox(height: 12),
          _EditField(
            controller: plateCtrl,
            label: 'Plate number',
            validator: (value) => InputValidators.requiredText(
              value ?? '',
              fieldLabel: 'Plate number',
            ),
          ),
          const SizedBox(height: 12),
          _EditField(
            controller: licenseCtrl,
            label: 'License number',
            validator: (value) => InputValidators.requiredText(
              value ?? '',
              fieldLabel: 'License number',
            ),
          ),
          const SizedBox(height: 18),
          _SheetSectionTitle(
            title: 'Required Documents',
            subtitle: 'Upload each required file separately for verification.',
            isDark: Get.find<ThemeController>().isDark.value,
          ),
          const SizedBox(height: 12),
          _DriverDocumentUploadSection(
            controller: _controller,
            isDark: Get.find<ThemeController>().isDark.value,
          ),
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
    GlobalKey<FormState>? formKey,
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
        final viewInsets = MediaQuery.of(sheetContext).viewInsets.bottom;
        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.9;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: viewInsets),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
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
                  Flexible(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: formKey == null
                          ? child
                          : Form(key: formKey, child: child),
                    ),
                  ),
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
                                if (formKey != null &&
                                    !(formKey.currentState?.validate() ??
                                        false)) {
                                  return;
                                }
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
            ),
          ),
        );
      },
    );
  }

  void _showError(BuildContext context, Object e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
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
            backgroundColor: isDark
                ? const Color(0xFF1C2331)
                : const Color(0xFFE9EEF6),
            backgroundImage: avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
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
                  style: TextStyle(color: _mutedText(isDark), fontSize: 13),
                ),
                if ((user.phone ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      user.phone!,
                      style: TextStyle(color: _mutedText(isDark), fontSize: 13),
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _TagChip(
                      label: roleLabel,
                      textColor: roleColor,
                      background: roleColor.withOpacity(isDark ? 0.22 : 0.12),
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
          _DriverInfoRow(
            label: 'Year',
            value: profile?.carYear,
            isDark: isDark,
          ),
          _DriverInfoRow(
            label: 'Color',
            value: profile?.carColor,
            isDark: isDark,
          ),
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
    final parts = [
      a,
      b,
    ].where((p) => p != null && p.trim().isNotEmpty).toList();
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
              style: TextStyle(color: _mutedText(isDark), fontSize: 13),
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
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
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

  const _ActionItem({required this.icon, required this.label, this.onTap});
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
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
        ),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      ),
    );
  }
}

class _DriverDocumentUploadSection extends StatefulWidget {
  const _DriverDocumentUploadSection({
    required this.controller,
    required this.isDark,
  });

  final ProfileController controller;
  final bool isDark;

  @override
  State<_DriverDocumentUploadSection> createState() =>
      _DriverDocumentUploadSectionState();
}

class _DriverDocumentUploadSectionState
    extends State<_DriverDocumentUploadSection> {
  String? _uploadingType;
  final _typeErrors = <String, String?>{};

  Future<void> _pickAndUpload(_DriverDocumentRequirement requirement) async {
    if (_uploadingType != null || widget.controller.docsUploading.value) return;

    setState(() {
      _uploadingType = requirement.type;
      _typeErrors[requirement.type] = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
        withData: false,
      );
      if (!mounted || result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final path = file.path;
      if (path == null || path.trim().isEmpty) {
        _setTypeError(requirement.type, 'Could not read the selected file.');
        return;
      }

      final fileName = file.name.trim().isNotEmpty
          ? file.name.trim()
          : path.split('/').last;
      final mimeType =
          lookupMimeType(path, headerBytes: file.bytes) ??
          _mimeTypeForExt(file.extension);

      await widget.controller.uploadDriverDocument(
        type: requirement.type,
        filePath: path,
        fileName: fileName,
        mimeType: mimeType,
      );
      if (!mounted) return;
      _showSnack('${requirement.title} uploaded successfully.');
      _setTypeError(requirement.type, null);
    } catch (e) {
      if (!mounted) return;
      final message = _friendlyError(e);
      _setTypeError(requirement.type, message);
      _showSnack(message);
    } finally {
      if (mounted) {
        setState(() => _uploadingType = null);
      }
    }
  }

  String _mimeTypeForExt(String? ext) {
    switch ((ext ?? '').toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  String _friendlyError(Object error) {
    final fromController = widget.controller.docsError.value;
    if (fromController != null && fromController.trim().isNotEmpty) {
      return fromController.replaceFirst('Exception: ', '').trim();
    }
    final cleaned = error.toString().replaceFirst('Exception: ', '').trim();
    if (cleaned.isEmpty) return 'Upload failed. Please try again.';
    return cleaned;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = widget.controller.docsLoading.value;
      final uploading = widget.controller.docsUploading.value;
      final allDocs = widget.controller.driverDocuments;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surfaceCard(widget.isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _cardBorder(widget.isDark)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (loading) ...[
              const SizedBox(height: 2),
              const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 10),
            ],
            for (int i = 0; i < _driverDocumentRequirements.length; i++) ...[
              Builder(
                builder: (_) {
                  final requirement = _driverDocumentRequirements[i];
                  final docs = _documentsForRequirement(allDocs, requirement)
                    ..sort(
                      (a, b) => _sortKey(
                        b.updatedAt ?? b.createdAt,
                      ).compareTo(_sortKey(a.updatedAt ?? a.createdAt)),
                    );
                  final isThisUploading =
                      uploading && _uploadingType == requirement.type;
                  final busy = uploading || _uploadingType != null;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _fieldFill(widget.isDark),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _cardBorder(widget.isDark)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          requirement.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary(widget.isDark),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          requirement.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: _mutedText(widget.isDark),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: busy
                                ? null
                                : () => _pickAndUpload(requirement),
                            icon: isThisUploading
                                ? SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _textPrimary(widget.isDark),
                                    ),
                                  )
                                : const Icon(
                                    Icons.upload_file_outlined,
                                    size: 18,
                                  ),
                            label: Text(
                              isThisUploading
                                  ? 'Uploading...'
                                  : docs.isEmpty
                                  ? 'Upload ${requirement.buttonLabel}'
                                  : 'Replace ${requirement.buttonLabel}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _textPrimary(widget.isDark),
                              side: BorderSide(
                                color: _cardBorder(widget.isDark),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        if ((_typeErrors[requirement.type] ?? '')
                            .trim()
                            .isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _typeErrors[requirement.type]!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        if (docs.isEmpty)
                          Text(
                            'No ${requirement.buttonLabel} uploaded yet.',
                            style: TextStyle(
                              fontSize: 12,
                              color: _mutedText(widget.isDark),
                            ),
                          )
                        else
                          Column(
                            children: [
                              for (final doc in docs)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _DriverDocumentTile(
                                    isDark: widget.isDark,
                                    document: doc,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
              if (i != _driverDocumentRequirements.length - 1)
                const SizedBox(height: 12),
            ],
          ],
        ),
      );
    });
  }

  void _setTypeError(String type, String? message) {
    if (!mounted) return;
    setState(() => _typeErrors[type] = message);
  }

  List<DriverDocument> _documentsForRequirement(
    List<DriverDocument> docs,
    _DriverDocumentRequirement requirement,
  ) {
    return docs.where((doc) {
      final docType = _normalizeDocType(doc.type);
      if (docType == requirement.type) return true;
      return requirement.aliases.contains(docType);
    }).toList();
  }

  String _normalizeDocType(String raw) {
    return raw.trim().toLowerCase().replaceAll(RegExp(r'[\s\-]'), '_');
  }

  int _sortKey(String? raw) {
    final dt = DateTime.tryParse(raw ?? '');
    if (dt == null) return 0;
    return dt.millisecondsSinceEpoch;
  }
}

class _DriverDocumentRequirement {
  const _DriverDocumentRequirement({
    required this.type,
    required this.title,
    required this.buttonLabel,
    required this.description,
    this.aliases = const [],
  });

  final String type;
  final String title;
  final String buttonLabel;
  final String description;
  final List<String> aliases;
}

const _driverDocumentRequirements = <_DriverDocumentRequirement>[
  _DriverDocumentRequirement(
    type: 'license',
    title: 'Driver License',
    buttonLabel: 'license document',
    description: 'Upload a clear image or PDF of your valid driver license.',
    aliases: ['driver_license'],
  ),
  _DriverDocumentRequirement(
    type: 'registration',
    title: 'Vehicle Registration',
    buttonLabel: 'registration document',
    description: 'Upload your current vehicle registration document.',
    aliases: ['vehicle_registration', 'car_registration'],
  ),
  _DriverDocumentRequirement(
    type: 'insurance',
    title: 'Insurance Proof',
    buttonLabel: 'insurance document',
    description: 'Upload active insurance proof for this vehicle.',
    aliases: ['insurance_proof', 'proof_of_insurance'],
  ),
];

class _SheetSectionTitle extends StatelessWidget {
  const _SheetSectionTitle({
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _textPrimary(isDark),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: _mutedText(isDark),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _DriverDocumentTile extends StatelessWidget {
  const _DriverDocumentTile({required this.isDark, required this.document});

  final bool isDark;
  final DriverDocument document;

  @override
  Widget build(BuildContext context) {
    final name = (document.fileName ?? '').trim().isEmpty
        ? '${_driverDocTypeLabel(document.type)} document'
        : document.fileName!.trim();
    final status = _docStatusLabel(document.status);
    final statusColor = _docStatusColor(status);
    final timestamp = _formatDocTimestamp(
      document.updatedAt ?? document.createdAt,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _fieldFill(isDark),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.description_outlined, size: 18, color: _mutedText(isDark)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: _textPrimary(isDark),
                  ),
                ),
                if (timestamp != null)
                  Text(
                    'Uploaded $timestamp',
                    style: TextStyle(fontSize: 11, color: _mutedText(isDark)),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(isDark ? 0.25 : 0.12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
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
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: appInputDecoration(context, labelText: label, radius: 14),
    );
  }
}

String _driverDocTypeLabel(String raw) {
  final value = raw.trim().toLowerCase().replaceAll(RegExp(r'[\s\-]'), '_');
  switch (value) {
    case 'license':
    case 'driver_license':
      return 'License';
    case 'registration':
    case 'vehicle_registration':
    case 'car_registration':
      return 'Registration';
    case 'insurance':
    case 'insurance_proof':
    case 'proof_of_insurance':
      return 'Insurance';
    default:
      if (value.isEmpty) return 'Driver';
      return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

String _docStatusLabel(String? raw) {
  final v = (raw ?? '').trim().toLowerCase();
  if (v.isEmpty) return 'Uploaded';
  if (v == 'approved') return 'Approved';
  if (v == 'rejected') return 'Rejected';
  if (v == 'pending') return 'Pending';
  return '${v[0].toUpperCase()}${v.substring(1)}';
}

Color _docStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'approved':
      return AppColors.passengerPrimary;
    case 'rejected':
      return Colors.redAccent;
    case 'pending':
      return Colors.orange;
    default:
      return const Color(0xFF4B79E5);
  }
}

String? _formatDocTimestamp(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final dt = DateTime.tryParse(raw.trim());
  if (dt == null) return null;
  final local = dt.toLocal();
  final mm = local.month.toString().padLeft(2, '0');
  final dd = local.day.toString().padLeft(2, '0');
  final yy = local.year.toString();
  return '$mm/$dd/$yy';
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
