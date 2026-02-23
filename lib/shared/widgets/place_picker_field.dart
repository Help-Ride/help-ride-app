import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import 'app_input_decoration.dart';

class PlacePick {
  final String fullText;
  final LatLng? latLng;
  const PlacePick({required this.fullText, required this.latLng});
}

class LatLng {
  final double lat;
  final double lng;
  const LatLng(this.lat, this.lng);
}

class PlacePickerField extends StatefulWidget {
  const PlacePickerField({
    super.key,
    required this.label,
    required this.hintText,
    required this.icon,
    required this.controller,
    this.iconColor,
    this.onPicked,
    this.errorText,
  });

  final String label;
  final String hintText;
  final IconData icon;
  final Color? iconColor;
  final TextEditingController controller;
  final ValueChanged<PlacePick>? onPicked;
  final String? errorText;

  @override
  State<PlacePickerField> createState() => _PlacePickerFieldState();
}

class _PlacePickerFieldState extends State<PlacePickerField> {
  late final _PlacesApi _places;

  bool get _hasApiKey {
    final apiKey = dotenv.env['GMS_API_KEY'];
    return apiKey?.trim().isNotEmpty ?? false;
  }

  @override
  void initState() {
    super.initState();
    final apiKey = dotenv.env['GMS_API_KEY'];
    assert(
      apiKey != null && apiKey.trim().isNotEmpty,
      'Google Places API key missing. Add GMS_API_KEY to .env.',
    );
    _places = _PlacesApi(apiKey!.trim());
  }

  Future<void> _openAutocomplete() async {
    if (!_hasApiKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Places API key missing (GMS_API_KEY).'),
        ),
      );
      return;
    }

    final picked = await showModalBottomSheet<PlacePick>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlacesBottomSheet(
        title: widget.label,
        places: _places,
        initialText: widget.controller.text,
      ),
    );

    if (!mounted || picked == null) return;

    widget.controller.text = picked.fullText;
    widget.onPicked?.call(picked);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final value = widget.controller.text.trim();
        final isEmpty = value.isEmpty;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final hasError =
            widget.errorText != null && widget.errorText!.trim().isNotEmpty;
        final borderColor = hasError
            ? AppColors.error
            : (isDark ? const Color(0xFF2B3345) : const Color(0xFFDCE3EF));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            const SizedBox(height: 8),
            Material(
              color: isDark ? const Color(0xFF1C2331) : const Color(0xFFF3F5F8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: borderColor, width: hasError ? 1.2 : 1),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _openAutocomplete,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.icon,
                        color:
                            widget.iconColor ??
                            (isDark
                                ? AppColors.darkMuted
                                : AppColors.lightMuted),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isEmpty ? widget.hintText : value,
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
                        color: isDark
                            ? AppColors.darkMuted
                            : AppColors.lightMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  widget.errorText!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

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
        PlacePick(fullText: display, latLng: details.latLng),
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
  final LatLng? latLng;

  const _PlaceDetails({this.formattedAddress, this.latLng});

  factory _PlaceDetails.fromJson(Map<String, dynamic> json) {
    final result =
        (json['result'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final formattedAddress = result['formatted_address']?.toString();

    final geometry = (result['geometry'] as Map?)?.cast<String, dynamic>();
    final location = (geometry?['location'] as Map?)?.cast<String, dynamic>();

    LatLng? latLng;
    final lat = location?['lat'];
    final lng = location?['lng'];
    if (lat != null && lng != null) {
      latLng = LatLng((lat as num).toDouble(), (lng as num).toDouble());
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
    if (q.isEmpty) throw ArgumentError('Argument query can not be empty');

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
    if (id.isEmpty) throw ArgumentError('placeId can not be empty');

    final uri =
        Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
          'place_id': id,
          'key': apiKey,
          'sessiontoken': sessionToken,
          'fields': 'formatted_address,geometry/location',
        });

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
