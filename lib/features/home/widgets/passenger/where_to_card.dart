import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/theme/app_colors.dart';
import '../common/app_card.dart';

class WhereToCard extends StatefulWidget {
  const WhereToCard({super.key});

  @override
  State<WhereToCard> createState() => _WhereToCardState();
}

class _WhereToCardState extends State<WhereToCard> {
  late final FlutterGooglePlacesSdk _places;

  final _pickupCtrl = TextEditingController();
  final _destCtrl = TextEditingController();

  Timer? _debounce;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    final key = dotenv.env['GMS_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('Missing GMS_API_KEY (dotenv not loaded or key empty)');
    }
    _places = FlutterGooglePlacesSdk(key);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pickupCtrl.dispose();
    _destCtrl.dispose();
    super.dispose();
  }

  void _onChanged(TextEditingController controller, String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final q = value.trim();
      if (q.length < 2) return; // don’t spam API for 0-1 chars
      await _openAutocomplete(controller, q);
    });
  }

  Future<void> _openAutocomplete(
    TextEditingController controller,
    String query,
  ) async {
    try {
      setState(() => _loading = true);

      final res = await _places.findAutocompletePredictions(
        query,
        countries: const ['CA'],
        // placeTypesFilter: PlaceTypeFilter.address, // <-- remove; not supported in your SDK version
      );

      if (!mounted) return;

      final predictions = res.predictions;
      if (predictions.isEmpty) return;

      final selected = await showModalBottomSheet<AutocompletePrediction>(
        context: context,
        showDragHandle: true,
        backgroundColor: Colors.white,
        builder: (_) {
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: predictions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = predictions[i];
              return ListTile(
                title: Text(p.fullText),
                subtitle: p.secondaryText == null
                    ? null
                    : Text(p.secondaryText!),
                onTap: () => Navigator.pop(context, p),
              );
            },
          );
        },
      );

      if (!mounted || selected == null) return;

      controller.text = selected.fullText;
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
    } catch (e) {
      debugPrint('Places error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Where to?",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),

          _TextFieldTile(
            controller: _pickupCtrl,
            icon: Icons.my_location,
            hintText: "Pickup location",
            loading: _loading,
            onChanged: (v) => _onChanged(_pickupCtrl, v),
          ),
          const SizedBox(height: 12),

          _TextFieldTile(
            controller: _destCtrl,
            icon: Icons.place,
            iconColor: AppColors.passengerPrimary,
            hintText: "Destination",
            loading: _loading,
            onChanged: (v) => _onChanged(_destCtrl, v),
          ),

          const SizedBox(height: 14),

          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                debugPrint('Pickup: ${_pickupCtrl.text}');
                debugPrint('Destination: ${_destCtrl.text}');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.passengerPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.search, size: 18),
              label: const Text(
                "Search rides",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextFieldTile extends StatelessWidget {
  const _TextFieldTile({
    required this.controller,
    required this.icon,
    required this.hintText,
    required this.onChanged,
    this.iconColor,
    this.loading = false,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hintText;
  final ValueChanged<String> onChanged;
  final Color? iconColor;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? AppColors.lightMuted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: AppColors.lightMuted),
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          if (loading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}
