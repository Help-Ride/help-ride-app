import '../../profile/models/driver_document.dart';
import '../../profile/services/stripe_connect_api.dart';

const int deferredDriverComplianceRideLimit = 5;

const Set<String> _ownershipDocTypes = {
  'ownership',
  'registration',
  'vehicle_registration',
  'car_registration',
  'vehicle_ownership',
  'ownership_proof',
};

bool hasUploadedVehicleRegistration(List<DriverDocument> documents) {
  for (final document in documents) {
    final type = document.type.trim().toLowerCase().replaceAll(
      RegExp(r'[\s\-]'),
      '_',
    );
    final status = document.status?.trim().toLowerCase();
    if (!_ownershipDocTypes.contains(type)) continue;
    if (status == 'rejected') continue;
    return true;
  }
  return false;
}

bool hasCompletedStripeSetup(StripeConnectStatus status) {
  return status.payoutsReady ||
      status.pendingVerification ||
      status.detailsSubmitted;
}

List<String> missingDeferredDriverComplianceItems({
  required List<DriverDocument> documents,
  required StripeConnectStatus stripeStatus,
}) {
  final missing = <String>[];
  if (!hasCompletedStripeSetup(stripeStatus)) {
    missing.add('Stripe payout setup');
  }
  if (!hasUploadedVehicleRegistration(documents)) {
    missing.add('Vehicle registration');
  }
  return missing;
}

bool requiresDeferredDriverCompliance({
  required int completedRides,
  required List<DriverDocument> documents,
  required StripeConnectStatus stripeStatus,
}) {
  if (completedRides < deferredDriverComplianceRideLimit) {
    return false;
  }
  return missingDeferredDriverComplianceItems(
    documents: documents,
    stripeStatus: stripeStatus,
  ).isNotEmpty;
}
