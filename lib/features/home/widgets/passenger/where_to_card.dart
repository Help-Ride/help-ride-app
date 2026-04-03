import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/services/location_sync_service.dart';
import '../../../../shared/widgets/app_input_decoration.dart';
import '../../controllers/recent_searches_controller.dart';
import '../common/app_card.dart';

class WhereToCard extends StatefulWidget {
  const WhereToCard({super.key});

  @override
  State<WhereToCard> createState() => _WhereToCardState();
}

class _WhereToCardState extends State<WhereToCard> {
  late final _PlacesApi _places;

  final _pickupCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  _LatLng? _pickupLatLng;
  _LatLng? _destLatLng;
  bool _resolvingCurrentPickup = false;
  static const double _defaultRadiusKm = 10.0;

  @override
  void initState() {
    super.initState();

    // Keep keys out of git: load from .env or pass via --dart-define.
    final apiKey = dotenv.env['GMS_API_KEY'];

    assert(
      apiKey != null && apiKey.trim().isNotEmpty,
      'Google Places API key missing. Add GMS_API_KEY to .env.',
    );

    _places = _PlacesApi(apiKey!.trim());
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _destCtrl.dispose();
    super.dispose();
  }

  bool get _hasApiKey {
    final apiKey = dotenv.env['GMS_API_KEY'];
    return apiKey?.trim().isNotEmpty ?? false;
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
    if (controller == _pickupCtrl) {
      _pickupLatLng = picked.latLng;
    } else if (controller == _destCtrl) {
      _destLatLng = picked.latLng;
    }
    setState(() {});
    // If you want lat/lng later, you already have picked.latLng (can store in controller/state)
    debugPrint('Picked: ${picked.fullText} | ${picked.latLng}');
  }

  Future<void> _useCurrentLocationForPickup() async {
    if (_resolvingCurrentPickup) return;

    setState(() => _resolvingCurrentPickup = true);
    try {
      final sample = await LocationSyncService.instance.captureCurrentLocation(
        requestPermission: true,
        allowLastKnown: true,
      );

      if (!mounted) return;
      if (sample == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to get your current location. Check location permissions and try again.',
            ),
          ),
        );
        return;
      }

      final pickupLabel = await _resolveCurrentLocationAddress(
        sample.lat,
        sample.lng,
      );
      if (!mounted) return;
      if (pickupLabel == null || pickupLabel.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to resolve your current address. Please try again.',
            ),
          ),
        );
        return;
      }

      _pickupCtrl.text = pickupLabel;
      _pickupLatLng = _LatLng(sample.lat, sample.lng);
      setState(() {});
    } finally {
      if (mounted) {
        setState(() => _resolvingCurrentPickup = false);
      }
    }
  }

  void _swapRouteEndpoints() {
    final pickupText = _pickupCtrl.text;
    final destinationText = _destCtrl.text;
    final pickupLatLng = _pickupLatLng;
    final destinationLatLng = _destLatLng;

    _pickupCtrl.text = destinationText;
    _destCtrl.text = pickupText;
    _pickupLatLng = destinationLatLng;
    _destLatLng = pickupLatLng;
    setState(() {});
  }

  Future<String?> _resolveCurrentLocationAddress(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final formatted = _formatPlacemark(placemarks.first);
        if (formatted.isNotEmpty) return formatted;
      }
    } catch (_) {
      // Fall through to Google reverse geocoding.
    }

    try {
      final details = await _places.reverseGeocode(lat: lat, lng: lng);
      final formatted = (details.formattedAddress ?? '').trim();
      if (formatted.isNotEmpty) return formatted;
    } catch (_) {
      // Ignore and return null below.
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Text(
                  "Where to?",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              _QuickLocationButton(
                isDark: isDark,
                busy: _resolvingCurrentPickup,
                onTap: _useCurrentLocationForPickup,
              ),
            ],
          ),
          const SizedBox(height: 14),

          Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  _TextFieldTile(
                    controller: _pickupCtrl,
                    icon: Icons.my_location,
                    hintText: "Pickup location",
                    isDark: isDark,
                    trailingClearance: 34,
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
                    isDark: isDark,
                    trailingClearance: 34,
                    onTap: () => _openAutocomplete(
                      controller: _destCtrl,
                      title: "Destination",
                    ),
                  ),
                ],
              ),
              Positioned(
                right: -8,
                top: 40,
                child: _SwapRouteButton(
                  isDark: isDark,
                  onTap: _swapRouteEndpoints,
                  enabled:
                      _pickupCtrl.text.trim().isNotEmpty ||
                      _destCtrl.text.trim().isNotEmpty,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: Listenable.merge([_pickupCtrl, _destCtrl]),
              builder: (context, _) {
                final canSearch =
                    _pickupCtrl.text.trim().isNotEmpty &&
                    _destCtrl.text.trim().isNotEmpty;

                return ElevatedButton.icon(
                  onPressed: canSearch
                      ? () {
                          final from = _pickupCtrl.text.trim();
                          final to = _destCtrl.text.trim();
                          final recent =
                              Get.isRegistered<RecentSearchesController>()
                              ? Get.find<RecentSearchesController>()
                              : Get.put(RecentSearchesController());
                          recent.addSearch(
                            from: from,
                            to: to,
                            fromLat: _pickupLatLng?.lat,
                            fromLng: _pickupLatLng?.lng,
                            toLat: _destLatLng?.lat,
                            toLng: _destLatLng?.lng,
                            radiusKm:
                                _pickupLatLng != null || _destLatLng != null
                                ? _defaultRadiusKm
                                : null,
                            seats: 1,
                          );

                          Get.toNamed(
                            '/rides/search',
                            arguments: {
                              'fromCity': from,
                              'toCity': to,
                              'seats': 1,
                              if (_pickupLatLng != null) ...{
                                'fromLat': _pickupLatLng!.lat,
                                'fromLng': _pickupLatLng!.lng,
                              },
                              if (_destLatLng != null) ...{
                                'toLat': _destLatLng!.lat,
                                'toLng': _destLatLng!.lng,
                              },
                              if (_pickupLatLng != null || _destLatLng != null)
                                'radiusKm': _defaultRadiusKm,
                            },
                          );
                        }
                      : null, // ✅ disables button
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.passengerPrimary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark
                        ? const Color(0xFF1C2331)
                        : const Color(0xFFE9EEF6),
                    disabledForegroundColor: isDark
                        ? AppColors.darkMuted
                        : const Color(0xFF9AA3B2),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _formatPlacemark(Placemark placemark) {
  final parts = <String>[];

  void add(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return;
    if (parts.contains(text)) return;
    parts.add(text);
  }

  final streetParts = [
    placemark.subThoroughfare?.trim(),
    placemark.thoroughfare?.trim(),
  ].whereType<String>().where((value) => value.isNotEmpty).toList();

  if (streetParts.isNotEmpty) {
    add(streetParts.join(' '));
  } else {
    add(placemark.street);
    add(placemark.name);
  }

  add(placemark.locality);
  add(placemark.administrativeArea);
  add(placemark.postalCode);
  add(placemark.country);

  return parts.join(', ');
}

class _QuickLocationButton extends StatelessWidget {
  const _QuickLocationButton({
    required this.isDark,
    required this.busy,
    required this.onTap,
  });

  final bool isDark;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1C2331) : const Color(0xFFF4F7FC);
    final border = isDark ? const Color(0xFF2B3345) : const Color(0xFFDCE3EF);
    final accent = AppColors.passengerPrimary;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: busy ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.1,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                )
              else
                Icon(Icons.my_location_rounded, size: 16, color: accent),
              const SizedBox(width: 7),
              Text(
                busy ? 'Locating...' : 'Current',
                style: TextStyle(
                  color: busy ? muted : accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwapRouteButton extends StatelessWidget {
  const _SwapRouteButton({
    required this.isDark,
    required this.onTap,
    required this.enabled,
  });

  final bool isDark;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1C2331) : Colors.white;
    final border = isDark ? const Color(0xFF2B3345) : const Color(0xFFDCE3EF);
    final iconColor = enabled
        ? AppColors.passengerPrimary
        : (isDark ? AppColors.darkMuted : AppColors.lightMuted);

    return Material(
      color: bg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                blurRadius: 16,
                offset: const Offset(0, 8),
                color: isDark
                    ? Colors.black.withValues(alpha: 0.18)
                    : const Color(0x12000000),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(Icons.swap_vert_rounded, color: iconColor, size: 24),
        ),
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
    required this.isDark,
    this.trailingClearance = 0,
    this.iconColor,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hintText;
  final VoidCallback onTap;
  final bool isDark;
  final double trailingClearance;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final value = controller.text.trim();
        final isEmpty = value.isEmpty;

        return Material(
          color: isDark ? const Color(0xFF1C2331) : const Color(0xFFF3F5F8),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: EdgeInsets.fromLTRB(14, 10, 14 + trailingClearance, 10),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color:
                        iconColor ??
                        (isDark ? AppColors.darkMuted : AppColors.lightMuted),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEmpty ? hintText : value,
                      maxLines: 2,
                      softWrap: true,
                      style: TextStyle(
                        color: isEmpty
                            ? (isDark
                                  ? AppColors.darkMuted
                                  : AppColors.lightMuted)
                            : (isDark
                                  ? AppColors.darkText
                                  : AppColors.lightText),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                  ),
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
  final _PlacesApi places;
  final String initialText;

  @override
  State<_PlacesBottomSheet> createState() => _PlacesBottomSheetState();
}

class _PlacesBottomSheetState extends State<_PlacesBottomSheet> {
  final _queryCtrl = TextEditingController();
  Timer? _debounce;

  // Session token: generate once per autocomplete session (recommended by Google).
  late final String _sessionToken;

  bool _loading = false;
  String? _error;
  List<_AutocompletePrediction> _predictions = const [];

  @override
  void initState() {
    super.initState();
    _sessionToken = const Uuid().v4();

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
      final res = await widget.places.autocomplete(
        query: query,
        sessionToken: _sessionToken,
        country: 'CA',
      );

      if (!mounted) return;
      setState(() {
        _predictions = res;
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

  Future<void> _pick(_AutocompletePrediction p) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final details = await widget.places.placeDetails(
        placeId: p.placeId,
        sessionToken: _sessionToken,
      );

      if (!mounted) return;

      final display = (details.formattedAddress?.trim().isNotEmpty ?? false)
          ? details.formattedAddress!.trim()
          : p.description;

      Navigator.pop(
        context,
        _PlacePick(fullText: display, latLng: details.latLng),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to fetch place details: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: h * 0.88,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
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
                color: isDark
                    ? const Color(0xFF232836)
                    : const Color(0xFFE6EAF2),
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
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                decoration: appInputDecoration(
                  context,
                  hintText: "Search address / place",
                  radius: 16,
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
                      p.structuredMainText ?? p.description,
                      maxLines: 2,
                      softWrap: true,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      p.structuredSecondaryText ?? '',
                      maxLines: 2,
                      softWrap: true,
                    ),
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
  final _LatLng? latLng;
  const _PlacePick({required this.fullText, required this.latLng});
}

class _LatLng {
  final double lat;
  final double lng;
  const _LatLng(this.lat, this.lng);

  @override
  String toString() => '($lat, $lng)';
}

class _AutocompletePrediction {
  final String placeId;
  final String description;
  final String? structuredMainText;
  final String? structuredSecondaryText;

  const _AutocompletePrediction({
    required this.placeId,
    required this.description,
    this.structuredMainText,
    this.structuredSecondaryText,
  });

  factory _AutocompletePrediction.fromJson(Map<String, dynamic> json) {
    final structured = (json['structured_formatting'] as Map?)
        ?.cast<String, dynamic>();
    return _AutocompletePrediction(
      placeId: (json['place_id'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      structuredMainText: structured?['main_text']?.toString(),
      structuredSecondaryText: structured?['secondary_text']?.toString(),
    );
  }
}

class _PlaceDetails {
  final String? formattedAddress;
  final _LatLng? latLng;

  const _PlaceDetails({this.formattedAddress, this.latLng});

  factory _PlaceDetails.fromJson(Map<String, dynamic> json) {
    final result =
        (json['result'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final formattedAddress = result['formatted_address']?.toString();

    final geometry = (result['geometry'] as Map?)?.cast<String, dynamic>();
    final location = (geometry?['location'] as Map?)?.cast<String, dynamic>();

    _LatLng? latLng;
    final lat = location?['lat'];
    final lng = location?['lng'];
    if (lat != null && lng != null) {
      latLng = _LatLng((lat as num).toDouble(), (lng as num).toDouble());
    }

    return _PlaceDetails(formattedAddress: formattedAddress, latLng: latLng);
  }
}

class _PlacesApi {
  _PlacesApi(this.apiKey);

  final String apiKey;

  Future<List<_AutocompletePrediction>> autocomplete({
    required String query,
    required String sessionToken,
    String? country,
  }) async {
    final q = query.trim();
    if (q.isEmpty) {
      throw ArgumentError('Argument query can not be empty');
    }

    final uri =
        Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
          'input': q,
          'key': apiKey,
          'sessiontoken': sessionToken,
          if (country != null && country.trim().isNotEmpty)
            'components': 'country:${country.trim()}',
        });

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception(
        'Places autocomplete HTTP ${res.statusCode}: ${res.body}',
      );
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final status = (data['status'] ?? '').toString();

    if (status != 'OK' && status != 'ZERO_RESULTS') {
      final msg = (data['error_message'] ?? data['status'] ?? 'Unknown error')
          .toString();
      throw Exception('Places autocomplete error: $msg');
    }

    final preds = (data['predictions'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => _AutocompletePrediction.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);

    return preds;
  }

  Future<_PlaceDetails> placeDetails({
    required String placeId,
    required String sessionToken,
  }) async {
    final id = placeId.trim();
    if (id.isEmpty) {
      throw ArgumentError('placeId can not be empty');
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {
        'place_id': id,
        'key': apiKey,
        'sessiontoken': sessionToken,
        // Keep it minimal to reduce cost/latency.
        'fields': 'formatted_address,geometry/location',
      },
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Places details HTTP ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final status = (data['status'] ?? '').toString();

    if (status != 'OK') {
      final msg = (data['error_message'] ?? data['status'] ?? 'Unknown error')
          .toString();
      throw Exception('Places details error: $msg');
    }

    return _PlaceDetails.fromJson(data);
  }

  Future<_PlaceDetails> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'latlng': '$lat,$lng',
      'key': apiKey,
    });

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Reverse geocode HTTP ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final status = (data['status'] ?? '').toString();
    if (status != 'OK') {
      final msg = (data['error_message'] ?? data['status'] ?? 'Unknown error')
          .toString();
      throw Exception('Reverse geocode error: $msg');
    }

    final results = (data['results'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
    if (results.isEmpty) {
      return const _PlaceDetails();
    }

    return _PlaceDetails.fromJson({'result': results.first});
  }
}
