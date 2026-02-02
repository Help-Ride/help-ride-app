String shortId(String id) {
  final s = id.trim();
  if (s.length <= 6) return s;
  return s.substring(0, 6);
}

bool isPaymentPaidStatus(String status) {
  final v = status.toLowerCase().trim();
  if (v.isEmpty) return false;

  if (v.contains('unpaid') ||
      v.contains('not_paid') ||
      v.contains('not-paid') ||
      v.contains('pending') ||
      v.contains('processing') ||
      v.contains('failed') ||
      v.contains('cancel') ||
      v.contains('refund') ||
      v.contains('declined') ||
      v.contains('requires_')) {
    return false;
  }

  return v == 'paid' ||
      v.contains('succeed') ||
      v.contains('success') ||
      v.contains('complete') ||
      v.contains('captur') ||
      v.contains('settl') ||
      (v.contains('paid') && !v.contains('partially'));
}

String formatDateTime(DateTime dt) {
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  final mm = dt.minute.toString().padLeft(2, '0');
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[(dt.month - 1)]} ${dt.day}, $h:$mm $ampm';
}
