import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/controllers/session_controller.dart';
import '../../../shared/widgets/app_input_decoration.dart';
import '../../home/controllers/home_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/models/driver_document.dart';
import '../controllers/driver_onboarding_controller.dart';
import '../routes/driver_routes.dart';

class DriverOnboardingView extends StatefulWidget {
  const DriverOnboardingView({super.key});

  @override
  State<DriverOnboardingView> createState() => _DriverOnboardingViewState();
}

class _DriverOnboardingViewState extends State<DriverOnboardingView> {
  static const _steps = <String>['Vehicle details', 'Documents'];

  late final DriverOnboardingController _driverController;
  late final ProfileController _profileController;
  late final SessionController _session;
  late final TextEditingController _carMakeCtrl;
  late final TextEditingController _carModelCtrl;
  late final TextEditingController _carYearCtrl;
  late final TextEditingController _carColorCtrl;
  late final TextEditingController _plateCtrl;
  int _stepIndex = 0;
  String? _uploadingType;
  final Map<String, String?> _typeErrors = <String, String?>{};

  @override
  void initState() {
    super.initState();

    _driverController = Get.isRegistered<DriverOnboardingController>()
        ? Get.find<DriverOnboardingController>()
        : Get.put(DriverOnboardingController(), permanent: false);

    _profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController(), permanent: false);

    _session = Get.find<SessionController>();
    _carMakeCtrl = TextEditingController();
    _carModelCtrl = TextEditingController();
    _carYearCtrl = TextEditingController();
    _carColorCtrl = TextEditingController();
    _plateCtrl = TextEditingController();

    _seedFormFromExistingProfile();
    unawaited(_hydrateInitialStepState());
  }

  @override
  void dispose() {
    _carMakeCtrl.dispose();
    _carModelCtrl.dispose();
    _carYearCtrl.dispose();
    _carColorCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final docs = _profileController.driverDocuments;
      final canContinueDocs = _areRequiredDocumentsUploaded(docs);
      final driverLoading = _driverController.loading.value;

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
                            : (canContinueDocs ? _completeOnboarding : null),
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
                                    : 'Finish onboarding',
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
            'Step 1 of 2: Vehicle details',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add the vehicle you will drive. Your selfie, license, and insurance uploads handle onboarding verification in the next step.',
            style: TextStyle(color: muted, height: 1.35),
          ),
          const SizedBox(height: 16),
          ExoField(
            controller: _carMakeCtrl,
            label: 'Car make',
            hint: 'Toyota',
            onChanged: _driverController.setCarMake,
            errorText: _driverController.fieldError('carMake'),
          ),
          const SizedBox(height: 14),
          ExoField(
            controller: _carModelCtrl,
            label: 'Car model',
            hint: 'Corolla',
            onChanged: _driverController.setCarModel,
            errorText: _driverController.fieldError('carModel'),
          ),
          const SizedBox(height: 14),
          ExoField(
            controller: _carYearCtrl,
            label: 'Car year',
            hint: '2020',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            onChanged: _driverController.setCarYear,
            errorText: _driverController.fieldError('carYear'),
          ),
          const SizedBox(height: 14),
          ExoField(
            controller: _carColorCtrl,
            label: 'Car color',
            hint: 'White',
            onChanged: _driverController.setCarColor,
            errorText: _driverController.fieldError('carColor'),
          ),
          const SizedBox(height: 14),
          ExoField(
            controller: _plateCtrl,
            label: 'Plate number',
            hint: 'ABC-123',
            onChanged: _driverController.setPlateNumber,
            errorText: _driverController.fieldError('plateNumber'),
          ),
          const SizedBox(height: 14),
          _OnboardingInfoCard(
            isDark: isDark,
            title: 'What happens next',
            message:
                'Upload your selfie, license, and insurance in step 2. Stripe payout setup and vehicle registration are only enforced after your first 5 completed rides.',
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
            'Step 2 of 2: Required documents',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Upload your selfie, license, and insurance to finish onboarding. Vehicle registration is deferred until after 5 completed rides.',
            style: TextStyle(color: muted, height: 1.35),
          ),
          if (docsLoading) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 2),
          ],
          const SizedBox(height: 14),
          for (final requirement in _onboardingDocRequirements.where(
            (item) => item.required,
          )) ...[
            _DocumentUploadCard(
              requirement: requirement,
              documents: _documentsForRequirement(docs, requirement),
              isDark: isDark,
              busy: docsUploading || _uploadingType != null,
              isUploading: docsUploading && _uploadingType == requirement.type,
              errorText: _typeErrors[requirement.type],
              onUpload: () => _pickAndUpload(requirement),
            ),
            const SizedBox(height: 12),
          ],
          _OnboardingInfoCard(
            isDark: isDark,
            title: 'Required later after 5 completed rides',
            message:
                'Upload your vehicle registration and finish Stripe payout setup from Profile before publishing ride number 6.',
          ),
          const SizedBox(height: 12),
          for (final requirement in _onboardingDocRequirements.where(
            (item) => !item.required,
          )) ...[
            _DocumentUploadCard(
              requirement: requirement,
              documents: _documentsForRequirement(docs, requirement),
              isDark: isDark,
              busy: docsUploading || _uploadingType != null,
              isUploading: docsUploading && _uploadingType == requirement.type,
              errorText: _typeErrors[requirement.type],
              onUpload: () => _pickAndUpload(requirement),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          Text(
            canContinue
                ? 'Selfie, license, and insurance received. You can finish onboarding now.'
                : 'Upload your selfie, license, and insurance to finish onboarding.',
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
  }

  void _goBackStep() {
    if (_stepIndex <= 0) return;
    setState(() => _stepIndex -= 1);
  }

  Future<void> _completeOnboarding() async {
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
      final pickedFile = await _pickUploadFile(requirement);
      if (!mounted || pickedFile == null) return;
      final messenger = ScaffoldMessenger.of(context);

      await _profileController.uploadDriverDocument(
        type: requirement.type,
        filePath: pickedFile.path,
        fileName: pickedFile.fileName,
        mimeType: pickedFile.mimeType,
      );

      _setTypeError(requirement.type, null);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            requirement.type == 'selfie'
                ? '${requirement.title} uploaded and set as your profile photo.'
                : '${requirement.title} uploaded successfully.',
          ),
        ),
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

  Future<_PickedDriverDocumentFile?> _pickUploadFile(
    _OnboardingDocumentRequirement requirement,
  ) async {
    if (requirement.photoOnly) {
      return _pickSelfiePhoto();
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (!mounted || result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final path = file.path;
    if (path == null || path.trim().isEmpty) {
      _setTypeError(requirement.type, 'Could not read selected file.');
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
        final textColor = isDark ? AppColors.darkText : AppColors.lightText;
        final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

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
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Use a clear front-facing photo that matches your driver documents. This selfie will also become your profile photo.',
                  style: TextStyle(color: muted, height: 1.35),
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

  bool _areRequiredDocumentsUploaded(List<DriverDocument> docs) {
    for (final requirement in _onboardingDocRequirements.where(
      (r) => r.required,
    )) {
      final uploaded = _documentsForRequirement(docs, requirement);
      final hasAcceptedUpload = uploaded.any((document) {
        final status = (document.status ?? '').trim().toLowerCase();
        return status != 'rejected';
      });
      if (!hasAcceptedUpload) return false;
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

  Future<void> _hydrateInitialStepState() async {
    await _profileController.refreshDriverProfile();
    await _profileController.refreshDriverDocuments(silent: true);
    if (!mounted) return;

    final hasDriverProfile =
        _session.user.value?.driverProfile != null ||
        _profileController.driverProfile.value != null;
    if (!hasDriverProfile) return;
    setState(() => _stepIndex = 1);
  }

  void _seedFormFromExistingProfile() {
    final profile = _session.user.value?.driverProfile;
    if (profile == null) return;

    _driverController.setCarMake(profile.carMake ?? '');
    _driverController.setCarModel(profile.carModel ?? '');
    _driverController.setCarYear(profile.carYear ?? '');
    _driverController.setCarColor(profile.carColor ?? '');
    _driverController.setPlateNumber(profile.plateNumber ?? '');
    _carMakeCtrl.text = profile.carMake ?? '';
    _carModelCtrl.text = profile.carModel ?? '';
    _carYearCtrl.text = profile.carYear ?? '';
    _carColorCtrl.text = profile.carColor ?? '';
    _plateCtrl.text = profile.plateNumber ?? '';
    _driverController.setLicenseNumber(profile.licenseNumber ?? '');
    _driverController.setInsuranceInfo(profile.insuranceInfo ?? '');
  }

  void _switchBackToPassenger() {
    if (!Get.isRegistered<HomeController>()) return;
    Get.find<HomeController>().setRole(HomeRole.passenger);
    Get.offAllNamed(AppRoutes.shell);
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
    this.controller,
    required this.label,
    required this.hint,
    required this.onChanged,
    this.keyboardType,
    this.errorText,
    this.inputFormatters,
  });

  final TextEditingController? controller;
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
          controller: controller,
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
    this.photoOnly = false,
  });

  final String type;
  final String title;
  final String description;
  final String buttonLabel;
  final bool required;
  final List<String> aliases;
  final bool photoOnly;
}

const _onboardingDocRequirements = <_OnboardingDocumentRequirement>[
  _OnboardingDocumentRequirement(
    type: 'selfie',
    title: 'Selfie Photo',
    description:
        'Take or upload a clear selfie photo so HelpRide can match your account to your driver documents and use it as your profile photo.',
    buttonLabel: 'selfie photo',
    required: true,
    aliases: ['driver_selfie', 'photo_selfie'],
    photoOnly: true,
  ),
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
        'Upload ownership proof or vehicle registration before you publish ride number 6.',
    buttonLabel: 'registration document',
    required: false,
    aliases: [
      'registration',
      'vehicle_registration',
      'car_registration',
      'vehicle_ownership',
      'ownership_proof',
    ],
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: requirement.required
                      ? AppColors.driverPrimary.withValues(
                          alpha: isDark ? 0.30 : 0.14,
                        )
                      : (isDark
                            ? const Color(0xFF1B202B)
                            : const Color(0xFFF0F3F8)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  requirement.required ? 'Required' : 'Later',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: requirement.required
                        ? AppColors.driverPrimary
                        : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
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

class _OnboardingInfoCard extends StatelessWidget {
  const _OnboardingInfoCard({
    required this.isDark,
    required this.title,
    required this.message,
  });

  final bool isDark;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF7F9FD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF232836) : const Color(0xFFE1E7F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(
              color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
