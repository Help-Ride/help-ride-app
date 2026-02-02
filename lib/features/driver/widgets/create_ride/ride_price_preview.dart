import 'package:flutter/material.dart';
import 'package:help_ride/features/driver/utils/ride_price_policy.dart';
import '../../../../core/theme/app_colors.dart';

class RidePricePreview extends StatelessWidget {
  const RidePricePreview({super.key, required this.preview});

  final RidePriceResolution preview;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final toneBg = preview.adjusted
        ? (isDark ? const Color(0xFF2A2414) : const Color(0xFFFFF7E6))
        : (isDark ? const Color(0xFF13232E) : const Color(0xFFEFF8FF));
    final toneBorder = preview.adjusted
        ? const Color(0xFFF0D49C)
        : const Color(0xFFCFE4FF);
    final titleColor = preview.adjusted
        ? const Color(0xFF8A5A00)
        : AppColors.driverPrimary;
    final classification = _classificationLabel(preview.classification);
    final appliedRules = _appliedRules(preview);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: toneBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: toneBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preview.adjusted ? 'Safety caps applied' : 'Pricing preview',
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Final: \$${_formatPrice(preview.finalPricePerSeat)}/seat',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            'Entered: \$${_formatPrice(preview.basePricePerSeat)} • $classification • ${preview.distanceKm.toStringAsFixed(1)} km',
            style: TextStyle(
              color: muted,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          if (appliedRules.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              appliedRules.join(' • '),
              style: TextStyle(
                color: muted,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _appliedRules(RidePriceResolution preview) {
    final out = <String>[];
    if (preview.appliedOntimeMarkup) out.add('ONTIME +30%');
    if (preview.appliedMinimumProtection) out.add('Min \$20 protected');
    if (preview.appliedSameDropCeiling) out.add('Same-drop ceiling \$15');
    if (preview.appliedUpperSafetyCap) out.add('Upper cap enforced');
    return out;
  }

  String _classificationLabel(RideTypeClassification type) {
    switch (type) {
      case RideTypeClassification.prebooked:
        return 'PREBOOKED';
      case RideTypeClassification.ontime:
        return 'ONTIME';
      case RideTypeClassification.standard:
        return 'STANDARD';
    }
  }
}

String _formatPrice(double value) {
  final fixed = value.toStringAsFixed(2);
  if (fixed.endsWith('.00')) return value.toStringAsFixed(0);
  if (fixed.endsWith('0')) return fixed.substring(0, fixed.length - 1);
  return fixed;
}
