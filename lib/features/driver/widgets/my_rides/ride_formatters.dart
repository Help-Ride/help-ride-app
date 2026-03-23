String fmtDateTime(DateTime dt) {
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
  return '${months[dt.month - 1]} ${dt.day}, $h:$mm $ampm';
}

String fmtDateRange(DateTime start, DateTime end) {
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

  if (start.year == end.year && start.month == end.month) {
    return '${months[start.month - 1]} ${start.day} - ${end.day}';
  }

  if (start.year == end.year) {
    return '${months[start.month - 1]} ${start.day} - ${months[end.month - 1]} ${end.day}';
  }

  return '${months[start.month - 1]} ${start.day}, ${start.year} - ${months[end.month - 1]} ${end.day}, ${end.year}';
}

String fmtPrice(double value) {
  if ((value - value.roundToDouble()).abs() < 0.01) {
    return '\$${value.toStringAsFixed(0)}';
  }
  final fixed = value.toStringAsFixed(2);
  if (fixed.endsWith('0')) {
    return '\$${fixed.substring(0, fixed.length - 1)}';
  }
  return '\$$fixed';
}

String compactAddress(String value) {
  final parts = value
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.length >= 2) {
    return '${parts[0]}, ${parts[1]}';
  }
  return value.trim();
}

String compactAddressMeta(String value) {
  final parts = value
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.length <= 2) return '';
  final meta = parts.sublist(2);
  if (meta.isEmpty) return '';
  if (meta.length == 1) return meta.first;
  return '${meta.first}, ${meta.last}';
}
