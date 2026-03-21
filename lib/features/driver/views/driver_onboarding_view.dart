import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mime/mime.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/controllers/session_controller.dart';
import '../../../shared/widgets/app_input_decoration.dart';
import '../../home/controllers/home_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/models/driver_document.dart';
import '../../profile/services/stripe_connect_api.dart';
import '../controllers/driver_onboarding_controller.dart';
import '../routes/driver_routes.dart';

class DriverOnboardingView extends StatefulWidget {
  const DriverOnboardingView({super.key});

  @override
  State<DriverOnboardingView> createState() => _DriverOnboardingViewState();
}

class _DriverOnboardingViewState extends State<DriverOnboardingView>
    with WidgetsBindingObserver {
  static const _steps = <String>[
    'Car details',
    'Documents',
    'Stripe onboarding',
  ];

  late final DriverOnboardingController _driverController;
  late final ProfileController _profileController;
  late final SessionController _session;
  late final AppLinks _appLinks;

  StreamSubscription<Uri>? _stripeLinkSub;
  int _stepIndex = 0;
  String? _uploadingType;
  final Map<String, String?> _typeErrors = <String, String?>{};
  bool _closingBrowserView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _driverController = Get.isRegistered<DriverOnboardingController>()
        ? Get.find<DriverOnboardingController>()
        : Get.put(DriverOnboardingController(), permanent: false);

    _profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController(), permanent: false);

    _session = Get.find<SessionController>();
    _appLinks = AppLinks();

    _seedFormFromExistingProfile();
    unawaited(_listenForStripeReturnLinks());
    unawaited(_hydrateInitialStepState());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final sub = _stripeLinkSub;
    if (sub != null) {
      unawaited(sub.cancel());
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_closeInAppBrowserViewIfOpen());
      unawaited(_profileController.refreshStripeConnectStatus(silent: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final docs = _profileController.driverDocuments;
      final canContinueDocs = _areRequiredDocumentsUploaded(docs);
      final driverLoading = _driverController.loading.value;
      final canFinalize = _canFinalizeStripeStep;

      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: isDark ? AppColors.darkText : AppColors.lightText,
          title: const Text(
            'Driver Onboarding',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: [
            if (Get.isRegistered<HomeController>())
              TextButton(
                onPressed: _switchBackToPassenger,
                child: const Text('Not now'),
              ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                _StepHeader(
                  titles: _steps,
                  currentStep: _stepIndex,
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _buildStepBody(isDark),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _stepIndex == 0 ? null : _goBackStep,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.driverPrimary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Back',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _stepIndex == 0
                            ? (driverLoading
                                  ? null
                                  : _saveCarDetailsAndContinue)
                            : _stepIndex == 1
                            ? (canContinueDocs ? _continueToStripeStep : null)
                            : () => _completeOnboarding(
                                needsConfirmation: !canFinalize,
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.driverPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _stepIndex == 0 && driverLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _stepIndex == 0
                                    ? 'Save & Continue'
                                    : _stepIndex == 1
                                    ? 'Continue'
                                    : canFinalize
                                    ? 'Finish onboarding'
                                    : 'Finish later',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildStepBody(bool isDark) {
    switch (_stepIndex) {
      case 0:
        return _buildCarDetailsStep(isDark);
      case 1:
        return _buildDocumentsStep(isDark);
      case 2:
        return _buildStripeStep(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCarDetailsStep(bool isDark) {
    return Obx(() {
      final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
      final err = _driverController.error.value;

      return ListView(
        key: const ValueKey('car-step'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Text(
            'Step 1 of 3: Vehicle details',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your car and license details to create your driver profile.',
            style: TextStyle(color: muted, height: 1.35),
          ),
          const SizedBox(height: 16),
          ExoField(
            label: 'Car Make',
            hint: 'Toyota',
            onChanged: _driverController.setCarMake,
            errorText: _driverController.fieldError('carMake'),
          ),
          const SizedBox(height: 12),
          ExoField(
            label: 'Car Model',
            hint: 'Camry',
            onChanged: _driverController.setCarModel,
            errorText: _driverController.fieldError('carModel'),
          ),
          const SizedBox(height: 12),
          ExoField(
            label: 'Car Year',
            hint: '2022',
            keyboardType: TextInputType.number,
            onChanged: _driverController.setCarYear,
            errorText: _driverController.fieldError('carYear'),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
          ),
          const SizedBox(height: 12),
          ExoField(
            label: 'Car Color',
            hint: 'Silver',
            onChanged: _driverController.setCarColor,
            errorText: _driverController.fieldError('carColor'),
          ),
          const SizedBox(height: 12),
          ExoField(
            label: 'Plate Number',
            hint: 'ABC-1234',
            onChanged: _driverController.setPlateNumber,
            errorText: _driverController.fieldError('plateNumber'),
          ),
          const SizedBox(height: 12),
          ExoField(
            label: 'License Number',
            hint: 'LIC-987654',
            onChanged: _driverController.setLicenseNumber,
            errorText: _driverController.fieldError('licenseNumber'),
          ),
          const SizedBox(height: 12),
          ExoField(
            label: 'Insurance Info (optional)',
            hint: 'Provider / policy',
            onChanged: _driverController.setInsuranceInfo,
            errorText: _driverController.fieldError('insuranceInfo'),
          ),
          if (err != null && err.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              err,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      );
    });
  }

  Widget _buildDocumentsStep(bool isDark) {
    return Obx(() {
      final docs = _profileController.driverDocuments;
      final docsLoading = _profileController.docsLoading.value;
      final docsUploading = _profileController.docsUploading.value;
      final canContinue = _areRequiredDocumentsUploaded(docs);
      final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

      return ListView(
        key: const ValueKey('docs-step'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Text(
            'Step 2 of 3: Required documents',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Upload the required documents so we can review your driver account.',
            style: TextStyle(color: muted, height: 1.35),
          ),
          if (docsLoading) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 2),
          ],
          const SizedBox(height: 14),
          for (int i = 0; i < _onboardingDocRequirements.length; i++) ...[
            _DocumentUploadCard(
              requirement: _onboardingDocRequirements[i],
              documents: _documentsForRequirement(
                docs,
                _onboardingDocRequirements[i],
              ),
              isDark: isDark,
              busy: docsUploading || _uploadingType != null,
              isUploading:
                  docsUploading &&
                  _uploadingType == _onboardingDocRequirements[i].type,
              errorText: _typeErrors[_onboardingDocRequirements[i].type],
              onUpload: () => _pickAndUpload(_onboardingDocRequirements[i]),
            ),
            if (i != _onboardingDocRequirements.length - 1)
              const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          Text(
            canContinue
                ? 'All required documents uploaded. Continue to Stripe onboarding.'
                : 'Upload all required documents (license, insurance, ownership) to continue.',
            style: TextStyle(
              color: canContinue ? AppColors.passengerPrimary : muted,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStripeStep(bool isDark) {
    return Obx(() {
      final status = _profileController.stripeConnectStatus.value;
      final loading = _profileController.stripeStatusLoading.value;
      final onboardingLoading =
          _profileController.stripeOnboardingLoading.value;
      final dashboardLoading = _profileController.stripeDashboardLoading.value;
      final error = _profileController.stripeConnectError.value;

      final uiState = _stripeStepUiState(status, loading: loading);
      final isReady = uiState.ready;
      final requiresInformation = uiState.requiresInformation;
      final setupLabel = status.hasStripeAccount
          ? 'Continue Stripe setup'
          : 'Set up payouts';

      return ListView(
        key: const ValueKey('stripe-step'),
        children: [
          Text(
            'Step 3 of 3: Stripe payout setup',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Connect Stripe so we can send your payouts securely.',
            style: TextStyle(
              color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF232836)
                    : const Color(0xFFE6EAF2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Stripe Connect',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkText
                              : AppColors.lightText,
                        ),
                      ),
                    ),
                    _StripeStatusPill(
                      label: uiState.label,
                      ready: isReady,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  uiState.message,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                  ),
                ),
                if (status.requirementsCurrentlyDue.isNotEmpty &&
                    requiresInformation) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Required information',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ..._buildRequirementItems(
                    status.requirementsCurrentlyDue,
                    isDark: isDark,
                  ),
                ],
                if (status.requirementsPendingVerification.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Pending verification',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ..._buildRequirementItems(
                    status.requirementsPendingVerification,
                    isDark: isDark,
                  ),
                ],
                if ((status.disabledReason ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Status reason: ${_formatRequirement(status.disabledReason!)}',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkMuted
                          : AppColors.lightMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (error != null && error.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (uiState.showOnboardingButton)
                      ElevatedButton(
                        onPressed: onboardingLoading
                            ? null
                            : () => _openStripeOnboarding(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.driverPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: onboardingLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                setupLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    if (status.hasStripeAccount) ...[
                      if (uiState.showOnboardingButton)
                        const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: dashboardLoading
                            ? null
                            : () => _openStripeDashboard(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: dashboardLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Open payout dashboard',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Future<void> _saveCarDetailsAndContinue() async {
    final saved = await _driverController.submit(
      refreshSession: false,
      closeOnRoute: false,
    );
    if (!saved) return;

    if (!mounted) return;
    setState(() => _stepIndex = 1);
    await _profileController.refreshDriverProfile();
    await _profileController.refreshDriverDocuments();
    await _profileController.refreshStripeConnectStatus(silent: true);
  }

  Future<void> _continueToStripeStep() async {
    final ready = await _ensureDriverProfileReadyForStripe();
    if (!ready || !mounted) return;
    setState(() => _stepIndex = 2);
    await _profileController.refreshStripeConnectStatus();
  }

  void _goBackStep() {
    if (_stepIndex <= 0) return;
    setState(() => _stepIndex -= 1);
  }

  Future<void> _completeOnboarding({required bool needsConfirmation}) async {
    if (needsConfirmation) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Finish for now?'),
            content: const Text(
              'Stripe setup still needs action. You can finish now and complete Stripe later from your profile.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Finish now'),
              ),
            ],
          );
        },
      );
      if (proceed != true || !mounted) return;
    }

    await _session.bootstrap();

    if (!mounted) return;
    if (Get.currentRoute == DriverRoutes.onboarding) {
      Get.offAllNamed(AppRoutes.shell);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Driver onboarding complete.')),
    );
  }

  Future<void> _pickAndUpload(
    _OnboardingDocumentRequirement requirement,
  ) async {
    if (_uploadingType != null || _profileController.docsUploading.value) {
      return;
    }

    setState(() {
      _uploadingType = requirement.type;
      _typeErrors[requirement.type] = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (!mounted || result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final path = file.path;
      if (path == null || path.trim().isEmpty) {
        _setTypeError(requirement.type, 'Could not read selected file.');
        return;
      }

      final fileName = file.name.trim().isNotEmpty
          ? file.name.trim()
          : path.split('/').last;
      final mimeType =
          lookupMimeType(path, headerBytes: file.bytes) ??
          _mimeTypeForExt(file.extension);

      await _profileController.uploadDriverDocument(
        type: requirement.type,
        filePath: path,
        fileName: fileName,
        mimeType: mimeType,
      );

      _setTypeError(requirement.type, null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${requirement.title} uploaded successfully.')),
      );
    } catch (e) {
      _setTypeError(requirement.type, _cleanError(e));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_cleanError(e))));
    } finally {
      if (mounted) {
        setState(() => _uploadingType = null);
      }
    }
  }

  void _setTypeError(String type, String? message) {
    if (!mounted) return;
    setState(() => _typeErrors[type] = message);
  }

  bool get _canFinalizeStripeStep {
    final status = _profileController.stripeConnectStatus.value;
    return status.payoutsReady || status.pendingVerification;
  }

  bool _areRequiredDocumentsUploaded(List<DriverDocument> docs) {
    for (final requirement in _onboardingDocRequirements.where(
      (r) => r.required,
    )) {
      final uploaded = _documentsForRequirement(docs, requirement);
      if (uploaded.isEmpty) return false;
    }
    return true;
  }

  List<DriverDocument> _documentsForRequirement(
    List<DriverDocument> docs,
    _OnboardingDocumentRequirement requirement,
  ) {
    return docs.where((doc) {
      final normalized = _normalizeDocType(doc.type);
      if (normalized == requirement.type) return true;
      return requirement.aliases.contains(normalized);
    }).toList();
  }

  String _normalizeDocType(String raw) {
    return raw.trim().toLowerCase().replaceAll(RegExp(r'[\s\-]'), '_');
  }

  Future<void> _openStripeOnboarding(BuildContext context) async {
    try {
      final ready = await _ensureDriverProfileReadyForStripe();
      if (!ready) return;
      final uri = await _profileController.createStripeOnboardingUri();
      await _launchStripeInBrowser(
        uri,
        failureMessage: 'Could not open Stripe onboarding.',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_cleanError(e))));
    }
  }

  Future<void> _openStripeDashboard(BuildContext context) async {
    try {
      final uri = await _profileController.createStripeDashboardUri();
      await _launchStripeInBrowser(
        uri,
        failureMessage: 'Could not open Stripe dashboard.',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_cleanError(e))));
    }
  }

  Future<void> _launchStripeInBrowser(
    Uri uri, {
    required String failureMessage,
  }) async {
    final openedInExternalBrowser = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (openedInExternalBrowser) return;

    final openedInBrowserView = await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
    );
    if (!openedInBrowserView) {
      throw Exception(failureMessage);
    }
  }

  Future<void> _hydrateInitialStepState() async {
    await _profileController.refreshDriverProfile();
    await _profileController.refreshDriverDocuments(silent: true);
    await _profileController.refreshStripeConnectStatus(silent: true);
    if (!mounted) return;

    final hasDriverProfile =
        _session.user.value?.driverProfile != null ||
        _profileController.driverProfile.value != null;
    if (!hasDriverProfile) return;
    final docsReady = _areRequiredDocumentsUploaded(
      _profileController.driverDocuments,
    );
    setState(() => _stepIndex = docsReady ? 2 : 1);
  }

  Future<bool> _ensureDriverProfileReadyForStripe() async {
    await _profileController.refreshDriverProfile();

    final hasDriverProfile =
        _session.user.value?.driverProfile != null ||
        _profileController.driverProfile.value != null;
    if (hasDriverProfile) {
      return true;
    }

    final saved = await _driverController.submit(
      refreshSession: false,
      closeOnRoute: false,
    );
    if (!saved) return false;

    await _profileController.refreshDriverProfile();
    return _session.user.value?.driverProfile != null ||
        _profileController.driverProfile.value != null;
  }

  Future<void> _listenForStripeReturnLinks() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _handleIncomingAppLink(initial);
      }
    } catch (_) {
      // Ignore initial app-link read failures.
    }

    _stripeLinkSub = _appLinks.uriLinkStream.listen(
      _handleIncomingAppLink,
      onError: (_) {
        // Ignore stream failures.
      },
    );
  }

  void _handleIncomingAppLink(Uri uri) {
    if (!_isStripeReturnUri(uri)) return;
    unawaited(_closeInAppBrowserViewIfOpen());
    unawaited(_profileController.refreshStripeConnectStatus(silent: true));
  }

  bool _isStripeReturnUri(Uri uri) {
    final normalizedPath = uri.path.trim().toLowerCase().replaceFirst(
      RegExp(r'/+$'),
      '',
    );
    if (normalizedPath == '/stripe/return') {
      return true;
    }

    final normalizedHost = uri.host.trim().toLowerCase();
    return normalizedHost == 'stripe' && normalizedPath == '/return';
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
      // Ignore close failures when no browser view is active.
    } finally {
      _closingBrowserView = false;
    }
  }

  void _seedFormFromExistingProfile() {
    final profile = _session.user.value?.driverProfile;
    if (profile == null) return;

    _driverController.setCarMake(profile.carMake ?? '');
    _driverController.setCarModel(profile.carModel ?? '');
    _driverController.setCarYear(profile.carYear ?? '');
    _driverController.setCarColor(profile.carColor ?? '');
    _driverController.setPlateNumber(profile.plateNumber ?? '');
    _driverController.setLicenseNumber(profile.licenseNumber ?? '');
    _driverController.setInsuranceInfo(profile.insuranceInfo ?? '');
  }

  void _switchBackToPassenger() {
    if (!Get.isRegistered<HomeController>()) return;
    Get.find<HomeController>().setRole(HomeRole.passenger);
    Get.offAllNamed(AppRoutes.shell);
  }

  String _formatRequirement(String value) {
    final normalized = value
        .replaceAll('.', ' ')
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) return value;
    return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
  }

  List<Widget> _buildRequirementItems(
    List<String> rawItems, {
    required bool isDark,
    int maxVisible = 3,
  }) {
    final items = rawItems.map(_formatRequirement).toList(growable: false);
    if (items.isEmpty) return const <Widget>[];

    final visible = items.take(maxVisible).toList(growable: false);
    final hasMore = items.length > visible.length;
    final widgets = <Widget>[
      for (final item in visible)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Icon(
                  Icons.circle,
                  size: 6,
                  color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
    ];

    if (hasMore) {
      widgets.add(
        Text(
          '+${items.length - visible.length} more',
          style: TextStyle(
            color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return widgets;
  }

  _StripeStepUiState _stripeStepUiState(
    StripeConnectStatus status, {
    required bool loading,
  }) {
    if (loading) {
      return const _StripeStepUiState(
        label: 'Checking',
        message: 'Checking Stripe status...',
        ready: false,
        requiresInformation: false,
        showOnboardingButton: false,
      );
    }

    if (!status.hasStripeAccount) {
      return const _StripeStepUiState(
        label: 'Not started',
        message: 'Start Stripe onboarding to receive payouts.',
        ready: false,
        requiresInformation: false,
        showOnboardingButton: true,
      );
    }

    switch (status.statusSummary) {
      case StripeConnectStatusSummary.ready:
        return const _StripeStepUiState(
          label: 'Payouts ready',
          message: 'Your payout setup is complete.',
          ready: true,
          requiresInformation: false,
          showOnboardingButton: false,
        );
      case StripeConnectStatusSummary.pendingVerification:
        return const _StripeStepUiState(
          label: 'Pending review',
          message: 'Stripe is reviewing, no action needed yet.',
          ready: false,
          requiresInformation: false,
          showOnboardingButton: false,
        );
      case StripeConnectStatusSummary.requiresInformation:
        return const _StripeStepUiState(
          label: 'Action required',
          message: 'Continue onboarding',
          ready: false,
          requiresInformation: true,
          showOnboardingButton: true,
        );
      case StripeConnectStatusSummary.unknown:
        return _StripeStepUiState(
          label: status.payoutsReady ? 'Payouts ready' : 'Not started',
          message: status.payoutsReady
              ? 'Your payout setup is complete.'
              : 'Start Stripe onboarding to receive payouts.',
          ready: status.payoutsReady,
          requiresInformation: status.requiresInformation,
          showOnboardingButton:
              status.requiresInformation || !status.hasStripeAccount,
        );
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
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
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.titles,
    required this.currentStep,
    required this.isDark,
  });

  final List<String> titles;
  final int currentStep;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(titles.length, (index) {
        final active = index == currentStep;
        final done = index < currentStep;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == titles.length - 1 ? 0 : 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.driverPrimary.withValues(
                        alpha: isDark ? 0.30 : 0.14,
                      )
                    : done
                    ? AppColors.passengerPrimary.withValues(
                        alpha: isDark ? 0.28 : 0.14,
                      )
                    : (isDark
                          ? const Color(0xFF1B202B)
                          : const Color(0xFFF0F3F8)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active
                      ? AppColors.driverPrimary
                      : done
                      ? AppColors.passengerPrimary
                      : (isDark
                            ? const Color(0xFF2A3040)
                            : const Color(0xFFE0E6EF)),
                ),
              ),
              child: Text(
                '${index + 1}. ${titles[index]}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active
                      ? AppColors.driverPrimary
                      : done
                      ? AppColors.passengerPrimary
                      : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class ExoField extends StatelessWidget {
  const ExoField({
    super.key,
    required this.label,
    required this.hint,
    required this.onChanged,
    this.keyboardType,
    this.errorText,
    this.inputFormatters,
  });

  final String label;
  final String hint;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          keyboardType: keyboardType,
          onChanged: onChanged,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          inputFormatters: inputFormatters,
          decoration: appInputDecoration(
            context,
            hintText: hint,
            errorText: errorText,
            radius: 12,
          ),
        ),
      ],
    );
  }
}

class _OnboardingDocumentRequirement {
  const _OnboardingDocumentRequirement({
    required this.type,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.required,
    this.aliases = const [],
  });

  final String type;
  final String title;
  final String description;
  final String buttonLabel;
  final bool required;
  final List<String> aliases;
}

const _onboardingDocRequirements = <_OnboardingDocumentRequirement>[
  _OnboardingDocumentRequirement(
    type: 'license',
    title: 'Driver License',
    description: 'Upload a clear image or PDF of your valid driver license.',
    buttonLabel: 'license document',
    required: true,
    aliases: ['driver_license'],
  ),
  _OnboardingDocumentRequirement(
    type: 'insurance',
    title: 'Insurance Proof',
    description: 'Upload active insurance proof for this vehicle.',
    buttonLabel: 'insurance document',
    required: true,
    aliases: ['insurance_proof', 'proof_of_insurance'],
  ),
  _OnboardingDocumentRequirement(
    type: 'ownership',
    title: 'Ownership / Registration',
    description:
        'Upload ownership proof (vehicle title/ownership or registration).',
    buttonLabel: 'ownership document',
    required: true,
    aliases: [
      'registration',
      'vehicle_registration',
      'car_registration',
      'vehicle_ownership',
      'ownership_proof',
    ],
  ),
];

class _DocumentUploadCard extends StatelessWidget {
  const _DocumentUploadCard({
    required this.requirement,
    required this.documents,
    required this.isDark,
    required this.busy,
    required this.isUploading,
    required this.errorText,
    required this.onUpload,
  });

  final _OnboardingDocumentRequirement requirement;
  final List<DriverDocument> documents;
  final bool isDark;
  final bool busy;
  final bool isUploading;
  final String? errorText;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final hasDocs = documents.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF232836) : const Color(0xFFE6EAF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  requirement.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
              ),
              if (requirement.required)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.driverPrimary.withValues(
                      alpha: isDark ? 0.30 : 0.14,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Required',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: AppColors.driverPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            requirement.description,
            style: TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: busy ? null : onUpload,
              icon: isUploading
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: textPrimary,
                      ),
                    )
                  : const Icon(Icons.upload_file_outlined, size: 18),
              label: Text(
                isUploading
                    ? 'Uploading...'
                    : hasDocs
                    ? 'Replace ${requirement.buttonLabel}'
                    : 'Upload ${requirement.buttonLabel}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if ((errorText ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              errorText!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            hasDocs ? 'Uploaded (${documents.length})' : 'Not uploaded yet',
            style: TextStyle(
              color: hasDocs ? AppColors.passengerPrimary : muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StripeStepUiState {
  const _StripeStepUiState({
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

class _StripeStatusPill extends StatelessWidget {
  const _StripeStatusPill({
    required this.label,
    required this.ready,
    required this.isDark,
  });

  final String label;
  final bool ready;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = ready
        ? (isDark ? const Color(0xFF14382B) : const Color(0xFFE8FAF3))
        : (isDark ? const Color(0xFF1B202B) : const Color(0xFFF0F3F8));
    final color = ready
        ? AppColors.passengerPrimary
        : (isDark ? AppColors.darkMuted : AppColors.lightMuted);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
