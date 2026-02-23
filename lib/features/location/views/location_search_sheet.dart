import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_input_decoration.dart';
import '../models/place_result.dart';
import '../services/places_service.dart';
import '../widgets/place_tile.dart';

class LocationSearchSheet extends StatefulWidget {
  const LocationSearchSheet({
    super.key,
    required this.title,
    required this.places,
    this.countryCode = "ca",
  });

  final String title;
  final PlacesService places;
  final String? countryCode;

  static Future<PlaceResult?> open({
    required String title,
    required PlacesService places,
    String? countryCode = "ca",
  }) {
    final isDark = Get.isDarkMode;
    return Get.bottomSheet<PlaceResult>(
      LocationSearchSheet(
        title: title,
        places: places,
        countryCode: countryCode,
      ),
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
    );
  }

  @override
  State<LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<LocationSearchSheet> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  String? _error;
  List<PlaceResult> _results = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () async {
      final q = v.trim();
      if (q.length < 2) {
        setState(() => _results = const []);
        return;
      }

      setState(() {
        _loading = true;
        _error = null;
      });

      try {
        final res = await widget.places.autocomplete(
          q,
          countryCode: widget.countryCode,
        );
        if (!mounted) return;
        setState(() => _results = res);
      } catch (e) {
        if (!mounted) return;
        setState(() => _error = e.toString());
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  Future<void> _pick(PlaceResult p) async {
    setState(() => _loading = true);
    try {
      final full = await widget.places.details(p.placeId);
      if (!mounted) return;
      Get.back(result: full ?? p);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF232836)
                    : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark
                            ? AppColors.darkText
                            : AppColors.lightText,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                    color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: _onQueryChanged,
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                decoration: appInputDecoration(
                  context,
                  hintText: "Search a place...",
                  radius: 14,
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                  ),
                ),
              ),
            ),

            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: CircularProgressIndicator(),
              ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),

            Expanded(
              child: ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: isDark
                      ? const Color(0xFF232836)
                      : const Color(0xFFE5E7EB),
                ),
                itemBuilder: (_, i) => PlaceTile(
                  place: _results[i],
                  onTap: () => _pick(_results[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
