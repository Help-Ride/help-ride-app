import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:help_ride/shared/controllers/session_controller.dart';
import 'package:help_ride/shared/models/user.dart';
import '../../bookings/services/payments_api.dart';
import '../../../shared/services/api_exception.dart';
import '../../../shared/services/api_client.dart';
import '../../../shared/utils/input_validators.dart';
import '../../../shared/utils/phone_number_utils.dart';
import '../models/driver_document.dart';
import '../services/profile_api.dart';
import '../services/stripe_connect_api.dart';

class ProfileController extends GetxController {
  late final ProfileApi _api;
  late final StripeConnectApi _stripeConnectApi;
  late final PaymentsApi _paymentsApi;
  late final SessionController _session;
  bool _servicesReady = false;

  final driverProfile = Rxn<DriverProfile>();
  final driverDocuments = <DriverDocument>[].obs;
  final loading = false.obs;
  final driverLoading = false.obs;
  final docsLoading = false.obs;
  final docsUploading = false.obs;
  final docsError = RxnString();
  final avatarUploading = false.obs;
  final avatarUploadError = RxnString();
  final deleteAccountLoading = false.obs;
  final paymentMethodsLoading = false.obs;
  final stripeConnectStatus = const StripeConnectStatus.empty().obs;
  final stripeStatusLoading = false.obs;
  final stripeOnboardingLoading = false.obs;
  final stripeDashboardLoading = false.obs;
  final stripeResetLoading = false.obs;
  final stripeConnectError = RxnString();

  @override
  Future<void> onInit() async {
    super.onInit();
    _session = Get.find<SessionController>();
    final client = await ApiClient.create();
    _api = ProfileApi(client);
    _stripeConnectApi = StripeConnectApi(client);
    _paymentsApi = PaymentsApi(client);
    _servicesReady = true;
    driverProfile.value = _session.user.value?.driverProfile;
    await refreshDriverProfile();
    await refreshDriverDocuments();
    await refreshStripeConnectStatus();
  }

  Future<void> refreshDriverProfile() async {
    final userId = _session.user.value?.id ?? '';
    if (userId.isEmpty) return;
    driverLoading.value = true;
    try {
      final profile = await _api.getDriverProfile(userId);
      if (profile != null) {
        driverProfile.value = profile;
      }
    } catch (_) {
      // Ignore missing driver profile for passengers.
    } finally {
      driverLoading.value = false;
    }
  }

  Future<void> refreshDriverDocuments({bool silent = false}) async {
    final userId = _session.user.value?.id ?? '';
    if (userId.isEmpty) return;
    if (!silent) {
      docsLoading.value = true;
    }
    docsError.value = null;
    try {
      final docs = await _api.getDriverDocuments(userId);
      driverDocuments.assignAll(docs);
    } catch (_) {
      driverDocuments.clear();
      docsError.value = 'Could not load documents right now.';
    } finally {
      docsLoading.value = false;
    }
  }

  Future<void> uploadDriverLicenseDocument({
    required String filePath,
    required String fileName,
    required String mimeType,
  }) async {
    return uploadDriverDocument(
      type: 'license',
      filePath: filePath,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  Future<void> uploadDriverDocument({
    required String type,
    required String filePath,
    required String fileName,
    required String mimeType,
  }) async {
    final userId = _session.user.value?.id ?? '';
    if (userId.isEmpty) return;
    final docType = type.trim().toLowerCase();
    if (docType.isEmpty) {
      throw Exception('Document type is required.');
    }
    docsUploading.value = true;
    docsError.value = null;
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Selected file is empty.');
      }

      final presign = await _api.getDriverDocumentPresign(
        userId,
        type: docType,
        fileName: fileName,
        mimeType: mimeType,
      );

      await _api.uploadFileToPresignedUrl(
        uploadUrl: presign.uploadUrl,
        bytes: bytes,
        mimeType: mimeType,
      );
      await refreshDriverDocuments(silent: true);
    } catch (e) {
      docsError.value = e.toString();
      rethrow;
    } finally {
      docsUploading.value = false;
    }
  }

  Future<String> uploadProfilePhoto({
    required String filePath,
    required String fileName,
    required String mimeType,
  }) async {
    final userId = _session.user.value?.id ?? '';
    if (userId.isEmpty) {
      throw Exception('Missing user session.');
    }

    avatarUploading.value = true;
    avatarUploadError.value = null;
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Selected file is empty.');
      }

      final presign = await _api.getUserAvatarPresign(
        userId,
        fileName: fileName,
        mimeType: mimeType,
      );

      await _api.uploadFileToPresignedUrl(
        uploadUrl: presign.uploadUrl,
        bytes: bytes,
        mimeType: mimeType,
      );

      final candidate = (presign.publicUrl ?? '').trim().isNotEmpty
          ? presign.publicUrl!.trim()
          : (presign.key ?? '').trim();
      if (candidate.isEmpty) {
        throw Exception('Upload succeeded but image URL is missing.');
      }
      return candidate;
    } catch (e) {
      avatarUploadError.value = e.toString();
      rethrow;
    } finally {
      avatarUploading.value = false;
    }
  }

  Future<User> updateUserProfile({
    required String name,
    String? email,
    required String phone,
    required String avatarUrl,
  }) async {
    final userId = _session.user.value?.id ?? '';
    if (userId.isEmpty) {
      throw Exception('Missing user session.');
    }
    loading.value = true;
    try {
      final trimmedEmail = email?.trim().toLowerCase() ?? '';
      if (trimmedEmail.isNotEmpty) {
        final emailError = InputValidators.email(trimmedEmail);
        if (emailError != null) {
          throw Exception(emailError);
        }
      }

      final normalizedPhone = phone.trim().isEmpty
          ? null
          : PhoneNumberUtils.normalizeToE164(phone.trim());
      if (phone.trim().isNotEmpty && normalizedPhone == null) {
        throw Exception('Enter a valid mobile number.');
      }

      final updatedUser = await _api.updateUserProfile(
        userId,
        name: name.trim().isEmpty ? null : name.trim(),
        email: trimmedEmail.isEmpty ? null : trimmedEmail,
        phone: normalizedPhone,
        providerAvatarUrl: avatarUrl.trim().isEmpty ? null : avatarUrl.trim(),
      );
      await _session.bootstrap();
      return updatedUser;
    } catch (error) {
      throw Exception(_normalizeError(error));
    } finally {
      loading.value = false;
    }
  }

  Future<void> deleteMyAccount() async {
    deleteAccountLoading.value = true;
    try {
      await _api.deleteMyAccount();
      await _session.clearLocalSession();
    } catch (error) {
      throw Exception(_normalizeError(error));
    } finally {
      deleteAccountLoading.value = false;
    }
  }

  Future<bool> openPaymentMethodsSheet() async {
    if (!_servicesReady) {
      throw Exception('Profile service is still initializing.');
    }

    paymentMethodsLoading.value = true;
    try {
      final session = await _paymentsApi.createCustomerSheetSession();
      await Stripe.instance.initCustomerSheet(
        customerSheetInitParams: CustomerSheetInitParams.adapter(
          setupIntentClientSecret: session.setupIntentClientSecret,
          customerId: session.customerId,
          customerEphemeralKeySecret: session.customerEphemeralKeySecret,
          merchantDisplayName: 'HelpRide',
          style: ThemeMode.system,
          headerTextForSelectionScreen: 'Payment methods',
          applePayEnabled: false,
          googlePayEnabled: false,
        ),
      );
      await Stripe.instance.presentCustomerSheet();
      return true;
    } on StripeException catch (error) {
      final code = error.error.code.toString().toLowerCase();
      if (code.contains('cancel')) {
        return false;
      }

      final message = error.error.message?.trim();
      if (message != null && message.isNotEmpty) {
        throw Exception(message);
      }
      throw Exception('Could not open payment methods.');
    } finally {
      paymentMethodsLoading.value = false;
    }
  }

  Future<void> upsertDriverProfile({
    required String carMake,
    required String carModel,
    String? carYear,
    String? carColor,
    required String plateNumber,
    required String licenseNumber,
    String? insuranceInfo,
  }) async {
    final userId = _session.user.value?.id ?? '';
    if (userId.isEmpty) return;
    driverLoading.value = true;
    try {
      final existing = driverProfile.value;
      if (existing == null) {
        await _api.createDriverProfile(
          carMake: carMake.trim(),
          carModel: carModel.trim(),
          carYear: carYear?.trim(),
          carColor: carColor?.trim(),
          plateNumber: plateNumber.trim(),
          licenseNumber: licenseNumber.trim(),
          insuranceInfo: insuranceInfo?.trim(),
        );
      } else {
        await _api.updateDriverProfile(
          userId,
          carMake: carMake.trim(),
          carModel: carModel.trim(),
          carYear: carYear?.trim(),
          carColor: carColor?.trim(),
          plateNumber: plateNumber.trim(),
          licenseNumber: licenseNumber.trim(),
          insuranceInfo: insuranceInfo?.trim(),
        );
      }
      await refreshDriverProfile();
      await _session.bootstrap();
      await refreshStripeConnectStatus(silent: true);
    } finally {
      driverLoading.value = false;
    }
  }

  Future<void> refreshStripeConnectStatus({bool silent = false}) async {
    if (!_servicesReady) return;

    final canManageStripeConnect = await _ensureStripeConnectAccess();
    if (!canManageStripeConnect) {
      stripeConnectStatus.value = const StripeConnectStatus.empty();
      stripeConnectError.value = null;
      stripeStatusLoading.value = false;
      return;
    }

    if (!silent) {
      stripeStatusLoading.value = true;
    }
    stripeConnectError.value = null;
    try {
      stripeConnectStatus.value = await _stripeConnectApi.getConnectStatus();
    } catch (e) {
      final normalized = _normalizeError(e);
      stripeConnectError.value = normalized;
    } finally {
      stripeStatusLoading.value = false;
    }
  }

  Future<Uri> createStripeOnboardingUri() async {
    if (!_servicesReady) {
      throw Exception('Profile service is still initializing.');
    }

    final canManageStripeConnect = await _ensureStripeConnectAccess();
    if (!canManageStripeConnect) {
      throw Exception('Stripe Connect is only available for driver accounts.');
    }

    stripeOnboardingLoading.value = true;
    stripeConnectError.value = null;
    try {
      final link = await _stripeConnectApi.createOnboardLink();
      final uri = Uri.tryParse(link.onboardingUrl.trim());
      if (uri == null) {
        throw Exception('Invalid Stripe onboarding URL.');
      }
      return uri;
    } catch (e) {
      stripeConnectError.value = _normalizeError(e);
      rethrow;
    } finally {
      stripeOnboardingLoading.value = false;
    }
  }

  Future<Uri> createStripeDashboardUri() async {
    if (!_servicesReady) {
      throw Exception('Profile service is still initializing.');
    }

    final canManageStripeConnect = await _ensureStripeConnectAccess();
    if (!canManageStripeConnect) {
      throw Exception('Stripe Connect is only available for driver accounts.');
    }

    stripeDashboardLoading.value = true;
    stripeConnectError.value = null;
    try {
      final link = await _stripeConnectApi.getDashboardLink();
      final uri = Uri.tryParse(link.url.trim());
      if (uri == null) {
        throw Exception('Invalid Stripe dashboard URL.');
      }
      return uri;
    } catch (e) {
      stripeConnectError.value = _normalizeError(e);
      rethrow;
    } finally {
      stripeDashboardLoading.value = false;
    }
  }

  Future<Uri> resetStripeConnectUri() async {
    if (!_servicesReady) {
      throw Exception('Profile service is still initializing.');
    }

    final canManageStripeConnect = await _ensureStripeConnectAccess();
    if (!canManageStripeConnect) {
      throw Exception('Stripe Connect is only available for driver accounts.');
    }

    stripeResetLoading.value = true;
    stripeConnectError.value = null;
    try {
      final link = await _stripeConnectApi.resetConnect();
      final uri = Uri.tryParse(link.onboardingUrl.trim());
      if (uri == null) {
        throw Exception('Invalid Stripe onboarding URL.');
      }
      return uri;
    } catch (e) {
      stripeConnectError.value = _normalizeError(e);
      rethrow;
    } finally {
      stripeResetLoading.value = false;
    }
  }

  bool get _canManageStripeConnect {
    final user = _session.user.value;
    if (user == null) return false;
    return user.driverProfile != null ||
        driverProfile.value != null ||
        user.roleDefault == 'driver';
  }

  Future<bool> _ensureStripeConnectAccess() async {
    if (_canManageStripeConnect) return true;
    await refreshDriverProfile();
    return _canManageStripeConnect;
  }

  String _normalizeError(Object error) {
    if (error is DioException && error.error is ApiException) {
      return (error.error as ApiException).message;
    }
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
