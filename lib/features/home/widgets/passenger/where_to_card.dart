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

  @override
  void initState() {
    super.initState();
    // NOTE: The SDK constructor requires a non-null apiKey string.
    // Keep the key out of git by using .env (flutter_dotenv) or --dart-define.
    final apiKey = dotenv.env['GMS_API_KEY'] ?? '';
    assert(
      apiKey.isNotEmpty,
      'GMS_API_KEY is missing. Add it to .env or pass via --dart-define.',
    );
    _places = FlutterGooglePlacesSdk(apiKey);
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _destCtrl.dispose();
    super.dispose();
  }

  bool get _hasApiKey {
    final apiKey = dotenv.env['GMS_API_KEY'] ?? '';
    return apiKey.trim().isNotEmpty;
  }

  Future<void> _openAutocomplete({
    required TextEditingController controller,
    required String title,
  }) async {
    if (!_hasApiKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Places API key missing (GMS_API_KEY).'),
        ),
      );
      return;
    }
    final picked = await showModalBottomSheet<_PlacePick>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlacesBottomSheet(
        title: title,
        places: _places,
        initialText: controller.text,
      ),
    );

    if (!mounted || picked == null) return;

    controller.text = picked.fullText;
    setState(() {});
    // If you want lat/lng later, you already have picked.latLng (can store in controller/state)
    debugPrint('Picked: ${picked.fullText} | ${picked.latLng}');
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
            onTap: () => _openAutocomplete(
              controller: _pickupCtrl,
              title: "Pickup location",
            ),
          ),
          const SizedBox(height: 12),

          _TextFieldTile(
            controller: _destCtrl,
            icon: Icons.place,
            iconColor: AppColors.passengerPrimary,
            hintText: "Destination",
            onTap: () =>
                _openAutocomplete(controller: _destCtrl, title: "Destination"),
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
    required this.onTap,
    this.iconColor,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hintText;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final value = controller.text.trim();
        final isEmpty = value.isEmpty;

        return Material(
          color: const Color(0xFFF3F5F8),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(icon, color: iconColor ?? AppColors.lightMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEmpty ? hintText : value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isEmpty
                            ? AppColors.lightMuted
                            : AppColors.lightText,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.lightMuted),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Bottom sheet that:
/// - debounces typing
/// - uses a session token
/// - shows predictions list
/// - resolves place details to get lat/lng
class _PlacesBottomSheet extends StatefulWidget {
  const _PlacesBottomSheet({
    required this.title,
    required this.places,
    this.initialText = '',
  });

  final String title;
  final FlutterGooglePlacesSdk places;
  final String initialText;

  @override
  State<_PlacesBottomSheet> createState() => _PlacesBottomSheetState();
}

class _PlacesBottomSheetState extends State<_PlacesBottomSheet> {
  final _queryCtrl = TextEditingController();
  Timer? _debounce;

  // Session token not supported by the current flutter_google_places_sdk API we’re using.

  bool _loading = false;
  String? _error;
  List<AutocompletePrediction> _predictions = const [];

  @override
  void initState() {
    super.initState();
    _queryCtrl.text = widget.initialText;
    _queryCtrl.addListener(_onQueryChanged);

    // If you already have text, prefetch
    if (_queryCtrl.text.trim().isNotEmpty) {
      _search(_queryCtrl.text.trim());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryCtrl.removeListener(_onQueryChanged);
    _queryCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final q = _queryCtrl.text.trim();
    _debounce?.cancel();

    // Don’t call API for short strings (wasteful + noisy)
    if (q.length < 3) {
      setState(() {
        _predictions = const [];
        _error = null;
        _loading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () => _search(q));
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await widget.places.findAutocompletePredictions(
        query,
        countries: const ['CA'],
        // placeTypesFilter can be null, or you can use other filters supported by your plugin version
        // placeTypesFilter: PlaceTypeFilter.address, // <-- depends on plugin version; keep null to avoid enum issues
      );

      if (!mounted) return;
      setState(() {
        _predictions = res.predictions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pick(AutocompletePrediction p) async {
    setState(() => _loading = true);

    try {
      final details = await widget.places.fetchPlace(
        p.placeId,
        fields: [
          PlaceField.Name,
          PlaceField.AddressComponents,
          PlaceField.Location,
        ],
      );

      final place = details.place;
      final text = p.fullText;
      final latLng = place?.latLng;

      if (!mounted) return;

      Navigator.pop(context, _PlacePick(fullText: text, latLng: latLng));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Failed to fetch place details: $e";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Container(
      height: h * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE6EAF2),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _queryCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Search address / place",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFF3F5F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
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
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                itemCount: _predictions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final p = _predictions[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.place_outlined),
                    title: Text(
                      p.primaryText,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(p.secondaryText),
                    onTap: () => _pick(p),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlacePick {
  final String fullText;
  final LatLng? latLng;
  const _PlacePick({required this.fullText, required this.latLng});
}
