import 'package:flutter/material.dart';
import 'package:help_ride/features/driver/models/ride_pricing_preview.dart';

import '../../../../core/theme/app_colors.dart';

class RidePricePreview extends StatelessWidget {
  const RidePricePreview({super.key, required this.preview});

  final RidePricingPreview preview;

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
    final classification = _classificationLabel(preview.rideTiming);
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
            _title(preview),
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
            'Entered: \$${_formatPrice(preview.inputPricePerSeat)} • Floor: \$${_formatPrice(preview.marketFloorPricePerSeat)} • $classification',
            style: TextStyle(
              color: muted,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${preview.distanceKm.toStringAsFixed(1)} km • ${preview.estimatedDurationMinutes} min est. • Trip est. \$${_formatPrice(preview.estimatedTripTotal)}',
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

  String _title(RidePricingPreview preview) {
    switch (preview.strategy) {
      case RidePricingStrategy.fixedRoute:
        return 'Fixed route price applies';
      case RidePricingStrategy.marketMinimum:
        return 'Market minimum will apply';
      case RidePricingStrategy.driverInput:
        return 'Pricing preview';
    }
  }

  List<String> _appliedRules(RidePricingPreview preview) {
    final out = <String>[];
    if (preview.fixedRoutePricePerSeat != null) {
      out.add('Fixed route \$${_formatPrice(preview.fixedRoutePricePerSeat!)}');
    }
    if (preview.appliedOntimeMarkup) out.add('On-time demand applied');
    if (preview.sharedSeatDivisor > 1.01) {
      out.add('Shared factor ÷${_formatPrice(preview.sharedSeatDivisor)}');
    }
    if (preview.strategy == RidePricingStrategy.marketMinimum) {
      out.add('Entered price is below the market minimum');
    }
    return out;
  }

  String _classificationLabel(RideTimingClass type) {
    switch (type) {
      case RideTimingClass.prebooked:
        return 'PREBOOKED';
      case RideTimingClass.ontime:
        return 'ONTIME';
      case RideTimingClass.standard:
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
