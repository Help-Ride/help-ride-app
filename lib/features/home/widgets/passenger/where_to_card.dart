import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../common/app_card.dart';
import 'package:get/get.dart';

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

  bool get _canSearch =>
      _pickupCtrl.text.trim().isNotEmpty && _destCtrl.text.trim().isNotEmpty;

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
                              if (_pickupLatLng != null ||
                                  _destLatLng != null)
                                'radiusKm': _defaultRadiusKm,
                            },
                          );
                        }
                      : null, // ✅ disables button
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.passengerPrimary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE9EEF6),
                    disabledForegroundColor: const Color(0xFF9AA3B2),
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
                      p.structuredMainText ?? p.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      p.structuredSecondaryText ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
}
