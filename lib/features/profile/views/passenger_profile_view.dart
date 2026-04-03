import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/utils/phone_number_utils.dart';
import '../../../shared/controllers/session_controller.dart';
import '../../../shared/models/user.dart';
import '../../../shared/utils/input_validators.dart';
import '../../../shared/widgets/app_input_decoration.dart';
import '../../auth/routes/auth_routes.dart';
import '../models/driver_document.dart';
import '../../support/routes/support_routes.dart';
import '../routes/profile_routes.dart';
import '../controllers/profile_controller.dart';
import '../services/stripe_connect_api.dart';

class PassengerProfileView extends StatefulWidget {
  const PassengerProfileView({super.key, this.openDriverEditorOnLoad = false});

  final bool openDriverEditorOnLoad;

  @override
  State<PassengerProfileView> createState() => _PassengerProfileViewState();
}

class _PassengerProfileViewState extends State<PassengerProfileView>
    with WidgetsBindingObserver {
  late final ProfileController _controller;
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _stripeLinkSub;
  bool _closingBrowserView = false;
  bool _didAutoOpenDriverEditor = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());
    _appLinks = AppLinks();
    unawaited(_listenForStripeReturnLinks());
    if (widget.openDriverEditorOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _autoOpenDriverEditorIfNeeded();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final linkSub = _stripeLinkSub;
    if (linkSub != null) {
      unawaited(linkSub.cancel());
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_closeInAppBrowserViewIfOpen());
      unawaited(_controller.refreshStripeConnectStatus(silent: true));
    }
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
          user.driverProfile != null ||
          user.roleDefault == 'driver' ||
          theme.role.value == AppRole.driver;
      final roleLabel = isDriver ? 'Driver' : 'Passenger';
      final hasEmail = user.email.trim().isNotEmpty;
      final hasPhone = user.phone?.trim().isNotEmpty ?? false;
      final needsEmailVerification = hasEmail && !user.emailVerified;
      final needsPhoneVerification = hasPhone && !user.phoneVerified;
      final hasPendingContactVerification =
          needsEmailVerification || needsPhoneVerification;
      final isVerified =
          (((!hasEmail || user.emailVerified) &&
              (!hasPhone || user.phoneVerified)) ||
          user.driverProfile?.isVerified == true);

      return Scaffold(
        backgroundColor: _surfaceBg(isDark),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: _textPrimary(isDark),
                      ),
                    ),
                  ),
                  _HeaderActionButton(
                    icon: Icons.tune_rounded,
                    isDark: isDark,
                    onTap: () => _openQuickActionsSheet(context, session),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _UserCard(
                user: user,
                roleLabel: roleLabel,
                roleColor: isDriver
                    ? AppColors.driverPrimary
                    : AppColors.passengerPrimary,
                isVerified: isVerified,
                isDark: isDark,
                avatarUploading:
                    _controller.avatarUploading.value ||
                    _controller.loading.value,
                onUploadPhoto: () =>
                    _captureAndUploadProfilePhoto(context, user),
                onOpenVerificationDrawer: hasPendingContactVerification
                    ? () => _openVerificationDrawer(context, user)
                    : null,
              ),
              const SizedBox(height: 24),
              _SectionLabel(
                label: 'Account',
                subtitle: 'Personal details and ride contact preferences.',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _ActionGroup(
                items: [
                  _ActionItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Personal info',
                    subtitle: user.name.trim().isEmpty
                        ? 'Add the name shown on rides and messages'
                        : user.name,
                    onTap: () => _openPersonalInfoSheet(context, user),
                  ),
                ],
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _ContactMethodsCard(
                key: ValueKey(
                  '${user.name}|${user.email}|${user.phone}|${user.emailVerified}|${user.phoneVerified}|${user.pendingEmail}|${user.pendingPhone}',
                ),
                controller: _controller,
                user: user,
                isDark: isDark,
                onVerifyEmail: user.emailVerified
                    ? null
                    : () => Get.toNamed(
                        AuthRoutes.verifyEmail,
                        arguments: {'email': user.email},
                      ),
                onVerifyPhone:
                    (user.phone?.trim().isNotEmpty ?? false) &&
                        !user.phoneVerified
                    ? () => Get.toNamed(
                        AuthRoutes.verifyPhone,
                        arguments: {
                          'phone': user.phone,
                          'email': user.email,
                          'autoSend': true,
                        },
                      )
                    : null,
                onOpenVerificationDrawer: hasPendingContactVerification
                    ? () => _openVerificationDrawer(context, user)
                    : null,
              ),
              const SizedBox(height: 22),
              if (isDriver || _controller.driverProfile.value != null) ...[
                _SectionLabel(
                  label: 'Driver profile',
                  subtitle:
                      'Vehicle details, verification, and driving documents.',
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _DriverProfileCard(
                  controller: _controller,
                  profile: _controller.driverProfile.value,
                  loading: _controller.driverLoading.value,
                  isDark: isDark,
                  onEdit: () => _openDriverEditSheet(
                    context,
                    _controller.driverProfile.value,
                  ),
                  onOpenDocuments: () => _openDriverDocumentsSheet(context),
                ),
                const SizedBox(height: 22),
              ],
              _SectionLabel(
                label: 'Payments',
                subtitle: 'Manage cards for bookings and payouts.',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _ActionGroup(
                items: [
                  _ActionItem(
                    icon: Icons.credit_card_outlined,
                    label: 'Payment methods',
                    subtitle: _controller.paymentMethodsLoading.value
                        ? 'Opening card manager...'
                        : 'Manage cards and saved checkout methods',
                    trailing: _controller.paymentMethodsLoading.value
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _textPrimary(isDark),
                            ),
                          )
                        : null,
                    onTap: _controller.paymentMethodsLoading.value
                        ? null
                        : () => unawaited(_openPaymentMethods()),
                  ),
                ],
                isDark: isDark,
              ),
              if (isDriver ||
                  _controller.stripeConnectStatus.value.hasStripeAccount) ...[
                const SizedBox(height: 10),
                _StripeConnectSection(controller: _controller, isDark: isDark),
              ],
              const SizedBox(height: 22),
              _SectionLabel(
                label: 'Safety & support',
                subtitle: 'Get help, policy details, and safety guidance.',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _ActionGroup(
                items: [
                  _ActionItem(
                    icon: Icons.shield_outlined,
                    label: 'Emergency & safety',
                    subtitle: 'Safety guidance and support during active trips',
                    onTap: () => Get.toNamed(
                      SupportRoutes.tickets,
                      arguments: const {'topic': 'safety'},
                    ),
                  ),
                  _ActionItem(
                    icon: Icons.support_agent_outlined,
                    label: 'Help & support',
                    subtitle: 'Open support tickets and contact HelpRide',
                    onTap: () => Get.toNamed(
                      SupportRoutes.tickets,
                      arguments: const {'topic': 'support'},
                    ),
                  ),
                  _ActionItem(
                    icon: Icons.policy_outlined,
                    label: 'Terms & privacy',
                    subtitle: 'Policies, privacy, and legal information',
                    onTap: () => Get.toNamed(ProfileRoutes.termsPrivacy),
                  ),
                ],
                isDark: isDark,
              ),
              const SizedBox(height: 22),
              _SectionLabel(
                label: 'Account actions',
                subtitle: 'Manage your session and account access.',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _ActionGroup(
                items: [
                  _ActionItem(
                    icon: Icons.logout_rounded,
                    label: 'Log out',
                    subtitle: 'Sign out from this device',
                    destructive: true,
                    onTap: () async {
                      await session.logout();
                      Get.offAllNamed(AppRoutes.login);
                    },
                  ),
                  _ActionItem(
                    icon: Icons.delete_forever_outlined,
                    label: _controller.deleteAccountLoading.value
                        ? 'Deleting account...'
                        : 'Delete account',
                    subtitle:
                        'Permanently remove your HelpRide account and profile',
                    destructive: true,
                    trailing: _controller.deleteAccountLoading.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    onTap: _controller.deleteAccountLoading.value
                        ? null
                        : () => _confirmDeleteAccount(context),
                  ),
                ],
                isDark: isDark,
              ),
              const SizedBox(height: 18),
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

  Future<void> _autoOpenDriverEditorIfNeeded() async {
    if (_didAutoOpenDriverEditor || !widget.openDriverEditorOnLoad) return;
    _didAutoOpenDriverEditor = true;
    await _openDriverEditSheet(context, _controller.driverProfile.value);
  }

  Future<void> _openPaymentMethods() async {
    try {
      final updated = await _controller.openPaymentMethodsSheet();
      if (!updated) return;
      Get.snackbar(
        'Payment methods updated',
        'Saved cards will be available during checkout.',
      );
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '').trim();
      Get.snackbar(
        'Payment methods unavailable',
        message.isEmpty ? 'Could not open payment methods.' : message,
      );
    }
  }

  Future<void> _openPersonalInfoSheet(BuildContext context, User user) async {
    final nameCtrl = TextEditingController(text: user.name);
    final formKey = GlobalKey<FormState>();

    await _showEditSheet(
      context,
      title: 'Personal info',
      saveLabel: 'Save changes',
      formKey: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetSectionTitle(
            title: 'Display name',
            subtitle: 'This name appears on rides, bookings, and messages.',
            isDark: Get.find<ThemeController>().isDark.value,
          ),
          const SizedBox(height: 12),
          _EditField(
            controller: nameCtrl,
            label: 'Full name',
            validator: (value) => InputValidators.requiredText(
              value ?? '',
              fieldLabel: 'Full name',
            ),
            helperText: 'Keep this aligned with the name riders should see.',
          ),
        ],
      ),
      onSave: () async {
        final nextName = nameCtrl.text.trim();
        if (nextName == user.name.trim()) {
          return true;
        }
        try {
          await _controller.updateUserProfile(
            name: nextName,
            email: user.email,
            phone: PhoneNumberUtils.formatForDisplay(user.phone),
            avatarUrl: user.avatarUrl ?? '',
          );
          return true;
        } catch (e) {
          if (context.mounted) {
            _showError(context, e);
          }
          return false;
        }
      },
      isSaving: _controller.loading,
    );

    nameCtrl.dispose();
  }

  Future<void> _openDriverDocumentsSheet(BuildContext context) async {
    await _controller.refreshDriverDocuments();
    if (!context.mounted) return;
    await _showEditSheet(
      context,
      title: 'Driver documents',
      saveLabel: 'Done',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetSectionTitle(
            title: 'Verification uploads',
            subtitle:
                'Manage the license, insurance, and supporting documents used for driver review.',
            isDark: Get.find<ThemeController>().isDark.value,
          ),
          const SizedBox(height: 12),
          _DriverDocumentUploadSection(
            controller: _controller,
            isDark: Get.find<ThemeController>().isDark.value,
          ),
        ],
      ),
      onSave: () async => true,
      isSaving: false.obs,
    );
  }

  void _openQuickActionsSheet(BuildContext context, SessionController session) {
    final isDark = Get.find<ThemeController>().isDark.value;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surfaceCard(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(
                  'Quick actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 14),
                _ActionGroup(
                  isDark: isDark,
                  items: [
                    _ActionItem(
                      icon: Icons.support_agent_outlined,
                      label: 'Help & support',
                      subtitle: 'Open support tickets and contact HelpRide',
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        Get.toNamed(SupportRoutes.tickets);
                      },
                    ),
                    _ActionItem(
                      icon: Icons.policy_outlined,
                      label: 'Terms & privacy',
                      subtitle: 'Review policies, privacy, and legal info',
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        Get.toNamed(ProfileRoutes.termsPrivacy);
                      },
                    ),
                    _ActionItem(
                      icon: Icons.logout_rounded,
                      label: 'Log out',
                      subtitle: 'Sign out from this device',
                      destructive: true,
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        await session.logout();
                        Get.offAllNamed(AppRoutes.login);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'This permanently deletes your Help Ride account. If you continue, Help Ride will automatically cancel your active rides, bookings, ride requests, and open offers for you. You do not need to cancel them manually. Any refunds or driver payouts already in progress will continue processing after deletion.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _controller.deleteMyAccount();
      if (!context.mounted) return;
      Get.offAllNamed(AppRoutes.login);
      Get.snackbar('Account deleted', 'Your account has been deleted.');
    } catch (error) {
      if (!context.mounted) return;
      _showError(context, error);
    }
  }

  Future<void> _listenForStripeReturnLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingAppLink(initialUri);
      }
    } catch (_) {
      // Ignore initial deep-link read failures.
    }

    _stripeLinkSub = _appLinks.uriLinkStream.listen(
      _handleIncomingAppLink,
      onError: (_) {
        // Ignore runtime deep-link stream errors.
      },
    );
  }

  void _handleIncomingAppLink(Uri uri) {
    if (!_isStripeReturnUri(uri)) return;
    unawaited(_closeInAppBrowserViewIfOpen());
    unawaited(_controller.refreshStripeConnectStatus(silent: true));
  }

  Future<void> _closeInAppBrowserViewIfOpen() async {
    if (_closingBrowserView) return;
    _closingBrowserView = true;
    try {
      final supportsClose = await supportsCloseForLaunchMode(
        LaunchMode.inAppBrowserView,
      );
      if (!supportsClose) return;
      await closeInAppWebView();
    } catch (_) {
      // Ignore close failures if browser view is not active.
    } finally {
      _closingBrowserView = false;
    }
  }

  bool _isStripeReturnUri(Uri uri) {
    final normalizedPath = uri.path.trim().toLowerCase().replaceFirst(
      RegExp(r'/+$'),
      '',
    );
    if (normalizedPath == ProfileRoutes.stripeConnectReturn) {
      return true;
    }

    final normalizedHost = uri.host.trim().toLowerCase();
    return normalizedHost == 'stripe' && normalizedPath == '/return';
  }

  Future<void> _captureAndUploadProfilePhoto(
    BuildContext context,
    User user,
  ) async {
    if (_controller.avatarUploading.value || _controller.loading.value) return;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final picker = ImagePicker();
      final captured = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 86,
        maxWidth: 1440,
      );
      if (!mounted || captured == null) return;

      final uploadedValue = await _controller.uploadProfilePhoto(
        filePath: captured.path,
        fileName: captured.name.trim().isNotEmpty
            ? captured.name.trim()
            : captured.path.split('/').last,
        mimeType: lookupMimeType(captured.path) ?? 'image/jpeg',
      );
      if (!mounted) return;

      await _controller.updateUserProfile(
        name: user.name,
        email: user.email,
        phone: PhoneNumberUtils.formatForDisplay(user.phone),
        avatarUrl: uploadedValue,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile photo updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '').trim();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            message.isEmpty ? 'Could not update profile photo.' : message,
          ),
        ),
      );
    }
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
      saveLabel: 'Save changes',
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
            label: 'License number (optional)',
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
          if (context.mounted) {
            _showError(context, e);
          }
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
    String saveLabel = 'Save',
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
                                if (!sheetContext.mounted) return;
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
                            : Text(
                                saveLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
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

  void _openVerificationDrawer(BuildContext context, User user) {
    final hasPhone = user.phone?.trim().isNotEmpty ?? false;
    final needsEmailVerification =
        user.email.trim().isNotEmpty && !user.emailVerified;
    final needsPhoneVerification = hasPhone && !user.phoneVerified;
    if (!needsEmailVerification && !needsPhoneVerification) return;

    final isDark = Get.find<ThemeController>().isDark.value;
    final phoneEnding = PhoneNumberUtils.endingDigits(user.phone);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surfaceCard(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(
                  'Complete verification',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose what you want to verify now.',
                  style: TextStyle(
                    color: _mutedText(isDark),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                if (needsEmailVerification)
                  _VerificationActionTile(
                    icon: Icons.mail_outline,
                    title: 'Verify email',
                    subtitle: user.email,
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      Get.toNamed(
                        AuthRoutes.verifyEmail,
                        arguments: {'email': user.email},
                      );
                    },
                  ),
                if (needsPhoneVerification)
                  Padding(
                    padding: EdgeInsets.only(
                      top: needsEmailVerification ? 10 : 0,
                    ),
                    child: _VerificationActionTile(
                      icon: Icons.phone_iphone_outlined,
                      title: 'Verify mobile number',
                      subtitle: phoneEnding.isEmpty
                          ? 'Send a code by SMS'
                          : 'Send a code to the number ending in $phoneEnding',
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        Get.toNamed(
                          AuthRoutes.verifyPhone,
                          arguments: {
                            'phone': user.phone,
                            'email': user.email,
                            'autoSend': true,
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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
    required this.avatarUploading,
    required this.onUploadPhoto,
    this.onOpenVerificationDrawer,
  });

  final User user;
  final String roleLabel;
  final Color roleColor;
  final bool isVerified;
  final bool isDark;
  final bool avatarUploading;
  final VoidCallback onUploadPhoto;
  final VoidCallback? onOpenVerificationDrawer;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarUrl ?? '';
    final initials = _initialsFor(user.name);
    final formattedPhone = PhoneNumberUtils.formatForDisplay(user.phone);
    final hasPhone = formattedPhone.trim().isNotEmpty;
    final verificationLabel = isVerified
        ? 'Contact verified'
        : 'Verification needed';
    final verificationColor = isVerified
        ? AppColors.passengerPrimary
        : const Color(0xFF9C6A09);
    final verificationBg = isVerified
        ? (isDark ? const Color(0xFF14382B) : const Color(0xFFE8FAF3))
        : (isDark ? const Color(0xFF3A2C10) : const Color(0xFFFFF4D6));
    final verificationBorder = isVerified
        ? (isDark ? const Color(0xFF1E5B45) : const Color(0xFFD8F2E5))
        : (isDark ? const Color(0xFF5A4414) : const Color(0xFFF3D98B));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceCard(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder(isDark)),
        boxShadow: _cardShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 28,
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
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: avatarUploading ? null : onUploadPhoto,
                        borderRadius: BorderRadius.circular(99),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.passengerPrimary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _surfaceCard(isDark),
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: avatarUploading
                                ? SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _textPrimary(isDark),
                                    ),
                                  )
                                : Icon(
                                    Icons.photo_camera_outlined,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.isNotEmpty ? user.name : 'User',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: _textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _TagChip(
                          label: roleLabel,
                          textColor: roleColor,
                          background: roleColor.withValues(
                            alpha: isDark ? 0.2 : 0.12,
                          ),
                        ),
                        GestureDetector(
                          onTap: isVerified ? null : onOpenVerificationDrawer,
                          child: _OutlinedTagChip(
                            label: verificationLabel,
                            textColor: verificationColor,
                            background: verificationBg,
                            borderColor: verificationBorder,
                            icon: isVerified
                                ? Icons.verified_rounded
                                : Icons.pending_outlined,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: _fieldFill(isDark),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _cardBorder(isDark)),
            ),
            child: Column(
              children: [
                _HeaderMetaLine(
                  icon: Icons.mail_outline,
                  value: user.email.trim().isEmpty
                      ? 'Add your email address'
                      : user.email,
                  isDark: isDark,
                ),
                if (hasPhone) ...[
                  const SizedBox(height: 10),
                  Divider(height: 1, color: _cardDivider(isDark)),
                  const SizedBox(height: 10),
                ],
                _HeaderMetaLine(
                  icon: Icons.phone_iphone_outlined,
                  value: hasPhone ? formattedPhone : 'Add your mobile number',
                  isDark: isDark,
                ),
                if (avatarUploading) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Updating profile photo...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _mutedText(isDark),
                      ),
                    ),
                  ),
                ],
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

class _ContactMethodsCard extends StatefulWidget {
  const _ContactMethodsCard({
    super.key,
    required this.controller,
    required this.user,
    required this.isDark,
    this.onVerifyEmail,
    this.onVerifyPhone,
    this.onOpenVerificationDrawer,
  });

  final ProfileController controller;
  final User user;
  final bool isDark;
  final VoidCallback? onVerifyEmail;
  final VoidCallback? onVerifyPhone;
  final VoidCallback? onOpenVerificationDrawer;

  @override
  State<_ContactMethodsCard> createState() => _ContactMethodsCardState();
}

class _ContactMethodsCardState extends State<_ContactMethodsCard> {
  Future<void> _openEmailSheet() async {
    final currentEmail = widget.user.email.trim();
    final pendingEmail = widget.user.pendingEmail?.trim() ?? '';
    final hasPendingChange =
        pendingEmail.isNotEmpty &&
        pendingEmail.toLowerCase() != currentEmail.toLowerCase();
    final needsVerification =
        currentEmail.isNotEmpty && !widget.user.emailVerified;

    if (hasPendingChange) {
      await _showVerificationFirstSheet(
        title: 'Verify your new email',
        value: pendingEmail,
        message:
            'Your current email stays active until the new address is verified.',
        actionLabel: 'Verify new email',
        onAction: () => Get.toNamed(
          AuthRoutes.verifyEmail,
          arguments: {'email': pendingEmail},
        ),
      );
      return;
    }

    if (needsVerification) {
      await _showVerificationFirstSheet(
        title: 'Verify email first',
        value: currentEmail,
        message:
            'Verify your current email before changing it. This helps protect account recovery and important trip updates.',
        actionLabel: 'Verify email',
        onAction: widget.onVerifyEmail,
      );
      return;
    }

    final emailCtrl = TextEditingController(text: currentEmail);
    await _showContactEditorSheet(
      title: currentEmail.isEmpty ? 'Add email' : 'Edit email',
      fieldLabel: 'Email',
      controller: emailCtrl,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) return 'Email is required.';
        return InputValidators.email(trimmed);
      },
      helperText:
          'If you change your email, you will need to verify the new address before it becomes active.',
      onSave: () async {
        final beforeEmail = widget.user.email.trim().toLowerCase();
        final beforePendingEmail = pendingEmail.toLowerCase();
        final nextEmail = emailCtrl.text.trim().toLowerCase();
        if (nextEmail == beforeEmail ||
            (beforePendingEmail.isNotEmpty &&
                nextEmail == beforePendingEmail)) {
          return _ContactEditResult.noChanges();
        }
        final updatedUser = await widget.controller.updateUserProfile(
          name: widget.user.name,
          email: emailCtrl.text,
          phone: PhoneNumberUtils.formatForDisplay(widget.user.phone),
          avatarUrl: widget.user.avatarUrl ?? '',
        );
        final updatedPendingEmail = updatedUser.pendingEmail?.trim() ?? '';
        return updatedPendingEmail.isNotEmpty &&
                updatedPendingEmail.toLowerCase() != beforeEmail
            ? _ContactEditResult.verifyEmail(updatedPendingEmail)
            : _ContactEditResult.saved();
      },
    );
    emailCtrl.dispose();
  }

  Future<void> _openPhoneSheet() async {
    final hasPhone = widget.user.phone?.trim().isNotEmpty ?? false;
    final formattedPhone = PhoneNumberUtils.formatForDisplay(widget.user.phone);
    final pendingPhone = widget.user.pendingPhone?.trim() ?? '';
    final hasPendingChange =
        pendingPhone.isNotEmpty &&
        pendingPhone != (widget.user.phone?.trim() ?? '');
    final needsVerification = hasPhone && !widget.user.phoneVerified;

    if (hasPendingChange) {
      await _showVerificationFirstSheet(
        title: 'Verify your new mobile',
        value: PhoneNumberUtils.formatForDisplay(pendingPhone),
        message:
            'Your current mobile number stays active until the new number is verified.',
        actionLabel: 'Verify new mobile',
        onAction: () => Get.toNamed(
          AuthRoutes.verifyPhone,
          arguments: {
            'phone': pendingPhone,
            'email': widget.user.email,
            'autoSend': true,
          },
        ),
      );
      return;
    }

    if (needsVerification) {
      await _showVerificationFirstSheet(
        title: 'Verify mobile first',
        value: formattedPhone,
        message:
            'Verify your current mobile number before changing it. This protects ride alerts and SMS sign-in.',
        actionLabel: 'Verify mobile',
        onAction: widget.onVerifyPhone,
      );
      return;
    }

    final phoneCtrl = TextEditingController(text: formattedPhone);
    await _showContactEditorSheet(
      title: hasPhone ? 'Edit mobile number' : 'Add mobile number',
      fieldLabel: 'Mobile number',
      controller: phoneCtrl,
      keyboardType: TextInputType.phone,
      inputFormatters: const [PhoneTextInputFormatter()],
      validator: (value) => InputValidators.optionalPhone(value ?? ''),
      helperText:
          'If you change your number, the new number must be verified before ride alerts and SMS sign-in use it.',
      onSave: () async {
        final beforePhone = PhoneNumberUtils.normalizeToE164(
          widget.user.phone ?? '',
        );
        final beforePendingPhone = PhoneNumberUtils.normalizeToE164(
          pendingPhone,
        );
        final nextPhone = PhoneNumberUtils.normalizeToE164(phoneCtrl.text);
        if (nextPhone == null ||
            nextPhone == beforePhone ||
            (beforePendingPhone != null && nextPhone == beforePendingPhone)) {
          return _ContactEditResult.noChanges();
        }
        final updatedUser = await widget.controller.updateUserProfile(
          name: widget.user.name,
          email: widget.user.email,
          phone: phoneCtrl.text,
          avatarUrl: widget.user.avatarUrl ?? '',
        );
        final updatedPendingPhone = updatedUser.pendingPhone?.trim() ?? '';
        return beforePhone != updatedPendingPhone &&
                updatedPendingPhone.isNotEmpty
            ? _ContactEditResult.verifyPhone(
                phone: updatedPendingPhone,
                email: updatedUser.email,
              )
            : _ContactEditResult.saved();
      },
    );
    phoneCtrl.dispose();
  }

  Future<void> _showVerificationFirstSheet({
    required String title,
    required String value,
    required String message,
    required String actionLabel,
    required VoidCallback? onAction,
  }) {
    final isDark = widget.isDark;
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surfaceCard(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: TextStyle(
                    color: _mutedText(isDark),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onAction == null
                        ? null
                        : () {
                            Navigator.of(sheetContext).pop();
                            onAction();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.passengerPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      actionLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showContactEditorSheet({
    required String title,
    required String fieldLabel,
    required TextEditingController controller,
    required Future<_ContactEditResult> Function() onSave,
    required String? Function(String?) validator,
    required String helperText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) async {
    final isDark = widget.isDark;
    final formKey = GlobalKey<FormState>();
    final messenger = ScaffoldMessenger.of(context);
    String? apiError;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surfaceCard(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final viewInsets = MediaQuery.of(sheetContext).viewInsets.bottom;
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: viewInsets),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary(isDark),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        helperText,
                        style: TextStyle(
                          color: _mutedText(isDark),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _EditField(
                        controller: controller,
                        label: fieldLabel,
                        keyboardType: keyboardType,
                        inputFormatters: inputFormatters,
                        validator: validator,
                        helperText:
                            'Verification will be required after saving.',
                        forceErrorText: apiError,
                        onChanged: (_) {
                          if (apiError != null) {
                            setSheetState(() => apiError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Obx(() {
                        final saving = widget.controller.loading.value;
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: saving
                                ? null
                                : () async {
                                    if (!(formKey.currentState?.validate() ??
                                        false)) {
                                      return;
                                    }
                                    try {
                                      final result = await onSave();
                                      if (!mounted || !sheetContext.mounted) {
                                        return;
                                      }
                                      Navigator.of(sheetContext).pop();
                                      if (result.routeName != null) {
                                        Get.toNamed(
                                          result.routeName!,
                                          arguments: result.arguments,
                                        );
                                      } else if (result.snackBarMessage !=
                                          null) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              result.snackBarMessage!,
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (!sheetContext.mounted) return;
                                      setSheetState(() {
                                        apiError = e.toString().replaceFirst(
                                          'Exception: ',
                                          '',
                                        );
                                      });
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.passengerPrimary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
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
                                    'Save changes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedPhone = PhoneNumberUtils.formatForDisplay(widget.user.phone);
    final hasPhone = formattedPhone.trim().isNotEmpty;
    final currentEmail = widget.user.email.trim();
    final pendingEmail = widget.user.pendingEmail?.trim() ?? '';
    final pendingPhone = widget.user.pendingPhone?.trim() ?? '';
    final needsEmailVerification =
        currentEmail.isNotEmpty && !widget.user.emailVerified;
    final needsPhoneVerification = hasPhone && !widget.user.phoneVerified;
    final hasPendingEmailChange =
        pendingEmail.isNotEmpty &&
        pendingEmail.toLowerCase() != currentEmail.toLowerCase();
    final normalizedCurrentPhone = PhoneNumberUtils.normalizeToE164(
      widget.user.phone ?? '',
    );
    final normalizedPendingPhone = PhoneNumberUtils.normalizeToE164(
      pendingPhone,
    );
    final hasPendingPhoneChange =
        normalizedPendingPhone != null &&
        normalizedPendingPhone != normalizedCurrentPhone;
    final needsAnyVerification =
        needsEmailVerification || needsPhoneVerification;
    final pendingBannerText = hasPendingEmailChange
        ? 'Pending email verification for $pendingEmail'
        : hasPendingPhoneChange
        ? 'Pending mobile verification for ${PhoneNumberUtils.formatForDisplay(pendingPhone)}'
        : needsPhoneVerification
        ? 'Verify your mobile number before changing it.'
        : needsEmailVerification
        ? 'Verify your email before changing it.'
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: _surfaceCard(widget.isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder(widget.isDark)),
        boxShadow: _cardShadow(widget.isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Contact methods',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary(widget.isDark),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (needsAnyVerification ||
                  hasPendingEmailChange ||
                  hasPendingPhoneChange)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? const Color(0xFF3A2C10)
                        : const Color(0xFFFFF4D6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Needs attention',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF9C6A09),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Update the contact details used for alerts, booking updates, and account recovery.',
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: _mutedText(widget.isDark),
            ),
          ),
          const SizedBox(height: 8),
          _ContactMethodDisplayRow(
            icon: Icons.mail_outline,
            title: 'Email',
            value: currentEmail.isNotEmpty
                ? widget.user.email
                : 'Add your email address',
            supportingText: hasPendingEmailChange
                ? 'Pending verification: $pendingEmail'
                : currentEmail.isEmpty
                ? 'Required for receipts and recovery'
                : null,
            statusLabel: currentEmail.isEmpty
                ? 'Add'
                : widget.user.emailVerified
                ? 'Verified'
                : 'Pending',
            verified: currentEmail.isNotEmpty && widget.user.emailVerified,
            isDark: widget.isDark,
            onTap: _openEmailSheet,
          ),
          Divider(height: 24, color: _cardDivider(widget.isDark)),
          _ContactMethodDisplayRow(
            icon: Icons.phone_iphone_outlined,
            title: 'Mobile',
            value: hasPhone ? formattedPhone : 'Add your mobile number',
            supportingText: hasPendingPhoneChange
                ? 'Pending verification: ${PhoneNumberUtils.formatForDisplay(pendingPhone)}'
                : !hasPhone
                ? 'Required for SMS ride alerts'
                : null,
            statusLabel: hasPhone
                ? (widget.user.phoneVerified ? 'Verified' : 'Pending')
                : 'Add',
            verified: hasPhone && widget.user.phoneVerified,
            isDark: widget.isDark,
            onTap: _openPhoneSheet,
          ),
          if (pendingBannerText != null || !hasPhone) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? const Color(0xFF171C27)
                    : const Color(0xFFF8FAFD),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _cardBorder(widget.isDark)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? const Color(0xFF3A2C10)
                          : const Color(0xFFFFF4D6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      size: 16,
                      color: Color(0xFF9C6A09),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pendingBannerText ??
                              'Verified contact details are required for ride alerts and sign-in.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.45,
                            color: _textPrimary(widget.isDark),
                          ),
                        ),
                        if (widget.onOpenVerificationDrawer != null) ...[
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: widget.onOpenVerificationDrawer,
                            child: Text(
                              'Review verification',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.passengerPrimary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DriverProfileCard extends StatelessWidget {
  const _DriverProfileCard({
    required this.controller,
    required this.profile,
    required this.loading,
    required this.isDark,
    required this.onEdit,
    required this.onOpenDocuments,
  });

  final ProfileController controller;
  final DriverProfile? profile;
  final bool loading;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onOpenDocuments;

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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _driverCardBorder(isDark)),
        boxShadow: _cardShadow(isDark),
      ),
      child: Obx(() {
        final docs = controller.driverDocuments;
        final docCount = docs.length;
        final approvedCount = docs
            .where(
              (doc) => (doc.status ?? '').trim().toLowerCase() == 'approved',
            )
            .length;

        return Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.driverPrimary.withValues(
                      alpha: isDark ? 0.18 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.directions_car_outlined,
                    color: AppColors.driverPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Driver profile',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: _textPrimary(isDark),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage your vehicle details and verification documents.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: _mutedText(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusPill(
                  isActive: profile?.isVerified == true,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ActionGroup(
              isDark: isDark,
              items: [
                _ActionItem(
                  icon: Icons.local_taxi_outlined,
                  label: 'Vehicle details',
                  subtitle: _vehicleSummary(profile),
                  onTap: onEdit,
                ),
                _ActionItem(
                  icon: Icons.verified_user_outlined,
                  label: 'Driver verification',
                  subtitle: profile?.isVerified == true
                      ? 'Verified to drive on HelpRide'
                      : approvedCount > 0
                      ? '$approvedCount document${approvedCount == 1 ? '' : 's'} approved'
                      : 'Selfie, license, and insurance still need review',
                  trailing: profile?.isVerified == true
                      ? Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: AppColors.passengerPrimary,
                        )
                      : null,
                  onTap: onOpenDocuments,
                ),
                _ActionItem(
                  icon: Icons.description_outlined,
                  label: 'Documents',
                  subtitle: docCount == 0
                      ? 'Upload your selfie, license, and insurance files'
                      : '$docCount file${docCount == 1 ? '' : 's'} uploaded',
                  onTap: onOpenDocuments,
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  String _vehicleSummary(DriverProfile? profile) {
    final parts = [
      profile?.carMake,
      profile?.carModel,
      profile?.carYear,
      profile?.plateNumber,
    ].where((p) => p != null && p.trim().isNotEmpty).toList();
    return parts.isEmpty
        ? 'Add your vehicle and plate details'
        : parts.join(' • ');
  }
}

class _HeaderMetaLine extends StatelessWidget {
  const _HeaderMetaLine({
    required this.icon,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 15, color: _mutedText(isDark)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: _mutedText(isDark),
              height: 1.3,
            ),
          ),
        ),
      ],
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
    final label = isActive ? 'Verified' : 'Reviewing';

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

class _ContactMethodDisplayRow extends StatelessWidget {
  const _ContactMethodDisplayRow({
    required this.icon,
    required this.title,
    required this.value,
    this.supportingText,
    required this.statusLabel,
    required this.verified,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? supportingText;
  final String statusLabel;
  final bool verified;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _fieldFill(isDark),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _cardBorder(isDark)),
            ),
            child: Icon(icon, size: 20, color: _mutedText(isDark)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _mutedText(isDark),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary(isDark),
                    height: 1.25,
                  ),
                ),
                if (supportingText != null && supportingText!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      supportingText!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: _mutedText(isDark),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (verified)
                Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.passengerPrimary,
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _chipNeutralBg(isDark),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _mutedText(isDark),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: _mutedText(isDark)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactEditResult {
  _ContactEditResult._({this.routeName, this.arguments, this.snackBarMessage});

  _ContactEditResult.saved()
    : this._(snackBarMessage: 'Contact details updated.');

  _ContactEditResult.noChanges() : this._();

  _ContactEditResult.verifyEmail(String email)
    : this._(routeName: AuthRoutes.verifyEmail, arguments: {'email': email});

  _ContactEditResult.verifyPhone({required String phone, required String email})
    : this._(
        routeName: AuthRoutes.verifyPhone,
        arguments: {'phone': phone, 'email': email, 'autoSend': true},
      );

  final String? routeName;
  final Map<String, dynamic>? arguments;
  final String? snackBarMessage;
}

class _CompactBadge extends StatelessWidget {
  const _CompactBadge({
    required this.label,
    required this.textColor,
    required this.background,
    this.borderColor,
    this.icon,
  });

  final String label;
  final Color textColor;
  final Color background;
  final Color? borderColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 5),
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

class _VerificationActionTile extends StatelessWidget {
  const _VerificationActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surfaceBg(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardBorder(isDark)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _surfaceCard(isDark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cardBorder(isDark)),
              ),
              child: Icon(icon, size: 18, color: AppColors.passengerPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
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
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: _mutedText(isDark),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: _mutedText(isDark)),
          ],
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
  });

  final String label;
  final Color textColor;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return _CompactBadge(
      label: label,
      textColor: textColor,
      background: background,
    );
  }
}

class _OutlinedTagChip extends StatelessWidget {
  const _OutlinedTagChip({
    required this.label,
    required this.textColor,
    required this.background,
    required this.borderColor,
    this.icon,
  });

  final String label;
  final Color textColor;
  final Color background;
  final Color borderColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return _CompactBadge(
      label: label,
      textColor: textColor,
      background: background,
      borderColor: borderColor,
      icon: icon,
    );
  }
}

class _StripeConnectSection extends StatelessWidget {
  const _StripeConnectSection({required this.controller, required this.isDark});

  final ProfileController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceCard(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder(isDark)),
        boxShadow: _cardShadow(isDark),
      ),
      child: Obx(() {
        final status = controller.stripeConnectStatus.value;
        final loading = controller.stripeStatusLoading.value;
        final onboardingLoading = controller.stripeOnboardingLoading.value;
        final dashboardLoading = controller.stripeDashboardLoading.value;
        final error = controller.stripeConnectError.value;
        final uiState = _statusUiState(status, loading: loading);
        final canOpenDashboard = status.hasStripeAccount;
        final setupLabel = status.hasStripeAccount
            ? 'Continue onboarding'
            : 'Set Up Payouts';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF172133)
                        : const Color(0xFFF3F7FE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 20,
                    color: AppColors.driverPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payouts',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: _textPrimary(isDark),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage your Stripe payout setup and banking details.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: _mutedText(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _StripeStatusChip(
                  label: uiState.label,
                  isReady: uiState.ready,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _fieldFill(isDark),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _cardBorder(isDark)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    uiState.message,
                    style: TextStyle(
                      color: _textPrimary(isDark),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  if (uiState.requiresInformation &&
                      status.requirementsCurrentlyDue.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ..._buildRequirementRows(
                      status.requirementsCurrentlyDue,
                      isDark: isDark,
                    ),
                  ],
                  if (status.requirementsPendingVerification.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Pending verification',
                      style: TextStyle(
                        color: _textPrimary(isDark),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ..._buildRequirementRows(
                      status.requirementsPendingVerification,
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
            if (error != null && error.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                error,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (uiState.showOnboardingButton)
                  ElevatedButton(
                    onPressed: onboardingLoading
                        ? null
                        : () => _openStripeOnboarding(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.driverPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                    ),
                    child: onboardingLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            setupLabel,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                if (canOpenDashboard)
                  OutlinedButton(
                    onPressed: dashboardLoading
                        ? null
                        : () => _openStripeDashboard(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textPrimary(isDark),
                      side: BorderSide(color: _cardBorder(isDark)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                    ),
                    child: dashboardLoading
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _textPrimary(isDark),
                            ),
                          )
                        : const Text(
                            'View payout details',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Future<void> _openStripeOnboarding(BuildContext context) async {
    try {
      final uri = await controller.createStripeOnboardingUri();
      await _launchStripeInBrowser(
        uri,
        failureMessage: 'Could not open Stripe onboarding.',
      );
    } catch (e) {
      if (!context.mounted) return;
      _showSnack(context, _cleanError(e));
    }
  }

  Future<void> _openStripeDashboard(BuildContext context) async {
    try {
      final uri = await controller.createStripeDashboardUri();
      await _launchStripeInBrowser(
        uri,
        failureMessage: 'Could not open pay details.',
      );
    } catch (e) {
      if (!context.mounted) return;
      _showSnack(context, _cleanError(e));
    }
  }

  Future<void> _launchStripeInBrowser(
    Uri uri, {
    required String failureMessage,
  }) async {
    final openedInBrowserView = await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
    );
    if (openedInBrowserView) return;

    final openedInExternalBrowser = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (openedInExternalBrowser) return;

    throw Exception(failureMessage);
  }

  List<Widget> _buildRequirementRows(
    List<String> rawItems, {
    required bool isDark,
    int maxVisible = 3,
  }) {
    final items = rawItems
        .map(_formatRequirement)
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
    if (items.isEmpty) return const <Widget>[];

    final visible = items.take(maxVisible).toList(growable: false);
    final hasMore = items.length > visible.length;
    final rows = <Widget>[
      for (final item in visible)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.circle, size: 6, color: _mutedText(isDark)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(color: _mutedText(isDark), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
    ];

    if (hasMore) {
      rows.add(
        Text(
          '+${items.length - visible.length} more',
          style: TextStyle(
            color: _mutedText(isDark),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return rows;
  }

  _StripeConnectUiState _statusUiState(
    StripeConnectStatus status, {
    required bool loading,
  }) {
    if (loading) {
      return const _StripeConnectUiState(
        label: 'Checking',
        message: 'Checking Stripe Connect status...',
        ready: false,
        requiresInformation: false,
        showOnboardingButton: false,
      );
    }

    if (!status.hasStripeAccount) {
      return const _StripeConnectUiState(
        label: 'Not set up',
        message:
            'Set up Stripe Connect to receive payouts in your bank account.',
        ready: false,
        requiresInformation: false,
        showOnboardingButton: true,
      );
    }

    switch (status.statusSummary) {
      case StripeConnectStatusSummary.ready:
        return const _StripeConnectUiState(
          label: 'Payouts ready',
          message: 'You can now receive payouts for completed rides.',
          ready: true,
          requiresInformation: false,
          showOnboardingButton: false,
        );
      case StripeConnectStatusSummary.pendingVerification:
        return const _StripeConnectUiState(
          label: 'Pending review',
          message: 'Stripe is reviewing, no action needed yet',
          ready: false,
          requiresInformation: false,
          showOnboardingButton: false,
        );
      case StripeConnectStatusSummary.requiresInformation:
        return const _StripeConnectUiState(
          label: 'Action required',
          message: 'Continue onboarding',
          ready: false,
          requiresInformation: true,
          showOnboardingButton: true,
        );
      case StripeConnectStatusSummary.unknown:
        return _StripeConnectUiState(
          label: status.payoutsReady ? 'Payouts ready' : 'Not set up',
          message: status.payoutsReady
              ? 'You can now receive payouts for completed rides.'
              : 'Set up Stripe Connect to receive payouts in your bank account.',
          ready: status.payoutsReady,
          requiresInformation: status.requiresInformation,
          showOnboardingButton:
              status.requiresInformation || !status.hasStripeAccount,
        );
    }
  }

  String _formatRequirement(String value) {
    final normalized = value
        .replaceAll('.', ' ')
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) return value;
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  void _showSnack(BuildContext context, String message) {
    final text = message.isEmpty ? 'Could not open Stripe link.' : message;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _StripeConnectUiState {
  const _StripeConnectUiState({
    required this.label,
    required this.message,
    required this.ready,
    required this.requiresInformation,
    required this.showOnboardingButton,
  });

  final String label;
  final String message;
  final bool ready;
  final bool requiresInformation;
  final bool showOnboardingButton;
}

class _StripeStatusChip extends StatelessWidget {
  const _StripeStatusChip({
    required this.label,
    required this.isReady,
    required this.isDark,
  });

  final String label;
  final bool isReady;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final background = isReady
        ? (isDark ? const Color(0xFF14382B) : const Color(0xFFE8FAF3))
        : _chipNeutralBg(isDark);
    final textColor = isReady ? AppColors.passengerPrimary : _mutedText(isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    required this.isDark,
    this.subtitle,
  });

  final String label;
  final bool isDark;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _textPrimary(isDark),
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.2,
          ),
        ),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              color: _mutedText(isDark),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _surfaceCard(isDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder(isDark)),
            boxShadow: _cardShadow(isDark),
          ),
          child: Icon(icon, color: _textPrimary(isDark), size: 20),
        ),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder(isDark)),
        boxShadow: _cardShadow(isDark),
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
  final String? subtitle;
  final bool destructive;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.destructive = false,
    this.trailing,
    this.onTap,
  });
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({required this.item, required this.isDark});

  final _ActionItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accentColor = item.destructive
        ? const Color(0xFFDA3C3C)
        : AppColors.driverPrimary;
    final textColor = item.destructive
        ? const Color(0xFFB3261E)
        : _textPrimary(isDark);
    final iconTint = item.onTap == null ? _mutedText(isDark) : accentColor;

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.destructive
                    ? (isDark
                          ? const Color(0xFF2A1515)
                          : const Color(0xFFFFF1F1))
                    : (isDark
                          ? const Color(0xFF172133)
                          : const Color(0xFFF3F7FE)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: iconTint, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: textColor,
                    ),
                  ),
                  if (item.subtitle != null &&
                      item.subtitle!.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: _mutedText(isDark),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (item.trailing != null) ...[
              item.trailing!,
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.chevron_right_rounded,
              color: item.onTap == null
                  ? _cardBorder(isDark)
                  : _mutedText(isDark),
            ),
          ],
        ),
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
      final pickedFile = await _pickUploadFile(requirement);
      if (!mounted || pickedFile == null) return;

      await widget.controller.uploadDriverDocument(
        type: requirement.type,
        filePath: pickedFile.path,
        fileName: pickedFile.fileName,
        mimeType: pickedFile.mimeType,
      );
      if (!mounted) return;
      _showSnack(
        requirement.type == 'selfie'
            ? '${requirement.title} uploaded and set as your profile photo.'
            : '${requirement.title} uploaded successfully.',
      );
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

  Future<_PickedDriverDocumentFile?> _pickUploadFile(
    _DriverDocumentRequirement requirement,
  ) async {
    if (requirement.photoOnly) {
      return _pickSelfiePhoto();
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      withData: false,
    );
    if (!mounted || result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final path = file.path;
    if (path == null || path.trim().isEmpty) {
      _setTypeError(requirement.type, 'Could not read the selected file.');
      return null;
    }

    final fileName = file.name.trim().isNotEmpty
        ? file.name.trim()
        : path.split('/').last;
    final mimeType =
        lookupMimeType(path, headerBytes: file.bytes) ??
        _mimeTypeForExt(file.extension);

    return _PickedDriverDocumentFile(
      path: path,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  Future<_PickedDriverDocumentFile?> _pickSelfiePhoto() async {
    final source = await _promptSelfieSource();
    if (!mounted || source == null) return null;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 86,
      maxWidth: 1600,
    );
    if (!mounted || image == null) return null;

    final fileName = image.name.trim().isNotEmpty
        ? image.name.trim()
        : image.path.split('/').last;

    return _PickedDriverDocumentFile(
      path: image.path,
      fileName: fileName,
      mimeType: lookupMimeType(image.path) ?? 'image/jpeg',
    );
  }

  Future<ImageSource?> _promptSelfieSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add selfie photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Use a clear front-facing photo that matches your driver documents. This selfie will also become your profile photo.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: _mutedText(isDark),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Take selfie'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose existing photo'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
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
    this.photoOnly = false,
  });

  final String type;
  final String title;
  final String buttonLabel;
  final String description;
  final List<String> aliases;
  final bool photoOnly;
}

const _driverDocumentRequirements = <_DriverDocumentRequirement>[
  _DriverDocumentRequirement(
    type: 'selfie',
    title: 'Selfie Photo',
    buttonLabel: 'selfie photo',
    description:
        'Take or upload a clear selfie photo so HelpRide can match your account to your driver documents and use it as your profile photo.',
    aliases: ['driver_selfie', 'photo_selfie'],
    photoOnly: true,
  ),
  _DriverDocumentRequirement(
    type: 'license',
    title: 'Driver License',
    buttonLabel: 'license document',
    description: 'Upload a clear image or PDF of your valid driver license.',
    aliases: ['driver_license'],
  ),
  _DriverDocumentRequirement(
    type: 'insurance',
    title: 'Insurance Proof',
    buttonLabel: 'insurance document',
    description: 'Upload active insurance proof for this vehicle.',
    aliases: ['insurance_proof', 'proof_of_insurance'],
  ),
  _DriverDocumentRequirement(
    type: 'ownership',
    title: 'Ownership Document',
    buttonLabel: 'ownership document',
    description:
        'Upload ownership proof (vehicle title/ownership or registration).',
    aliases: [
      'registration',
      'vehicle_registration',
      'car_registration',
      'vehicle_ownership',
      'ownership_proof',
    ],
  ),
  _DriverDocumentRequirement(
    type: 'other',
    title: 'Other Document',
    buttonLabel: 'other document',
    description: 'Upload any additional supporting document (optional).',
    aliases: ['misc', 'miscellaneous', 'additional_document'],
  ),
];

class _PickedDriverDocumentFile {
  const _PickedDriverDocumentFile({
    required this.path,
    required this.fileName,
    required this.mimeType,
  });

  final String path;
  final String fileName;
  final String mimeType;
}

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
              color: statusColor.withValues(alpha: isDark ? 0.25 : 0.12),
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
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.helperText,
    this.forceErrorText,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final String? helperText;
  final String? forceErrorText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      onChanged: onChanged,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: appInputDecoration(
        context,
        labelText: label,
        helperText: helperText,
        errorText: forceErrorText,
        radius: 14,
      ),
    );
  }
}

String _driverDocTypeLabel(String raw) {
  final value = raw.trim().toLowerCase().replaceAll(RegExp(r'[\s\-]'), '_');
  switch (value) {
    case 'selfie':
    case 'driver_selfie':
    case 'photo_selfie':
      return 'Selfie';
    case 'license':
    case 'driver_license':
      return 'License';
    case 'insurance':
    case 'insurance_proof':
    case 'proof_of_insurance':
      return 'Insurance';
    case 'ownership':
    case 'registration':
    case 'vehicle_registration':
    case 'car_registration':
    case 'vehicle_ownership':
    case 'ownership_proof':
      return 'Ownership';
    case 'other':
    case 'misc':
    case 'miscellaneous':
    case 'additional_document':
      return 'Other';
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

List<BoxShadow> _cardShadow(bool isDark) => [
  BoxShadow(
    color: isDark ? const Color(0x33000000) : const Color(0x0F101828),
    blurRadius: 22,
    offset: const Offset(0, 10),
  ),
];

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
    isDark ? AppColors.darkSurface : const Color(0xFFF8FAFD);

Color _driverCardBorder(bool isDark) =>
    isDark ? const Color(0xFF232836) : const Color(0xFFE6EAF2);

Color _fieldFill(bool isDark) =>
    isDark ? const Color(0xFF1C2331) : const Color(0xFFF3F5F8);
