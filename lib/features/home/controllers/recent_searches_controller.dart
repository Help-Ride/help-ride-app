import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/recent_search.dart';

class RecentSearchesController extends GetxController {
  static const _storageKey = 'recent_ride_searches';
  static const _maxItems = 5;

  final _box = GetStorage();
  final items = <RecentSearch>[].obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  void addSearch({
    required String from,
    required String to,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    double? radiusKm,
    int? seats,
  }) {
    final cleanFrom = from.trim();
    final cleanTo = to.trim();
    if (cleanFrom.isEmpty || cleanTo.isEmpty) return;

    items.removeWhere((item) =>
        item.from.toLowerCase() == cleanFrom.toLowerCase() &&
        item.to.toLowerCase() == cleanTo.toLowerCase());

    items.insert(
      0,
      RecentSearch(
        from: cleanFrom,
        to: cleanTo,
        when: DateTime.now(),
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
        radiusKm: radiusKm,
        seats: seats,
      ),
    );

    if (items.length > _maxItems) {
      items.removeRange(_maxItems, items.length);
    }

    _save();
  }

  String formatWhen(DateTime dt) {
    final now = DateTime.now();
    final isToday =
        now.year == dt.year && now.month == dt.month && now.day == dt.day;

    final time = _formatTime(dt);
    if (isToday) return 'Today, $time';

    final monthNames = [
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
    final m = monthNames[dt.month - 1];
    return '$m ${dt.day}, $time';
  }

  void _load() {
    final raw = _box.read(_storageKey);
    if (raw is List) {
      final list = raw.whereType<Map>().map((item) {
        return RecentSearch.fromJson(Map<String, dynamic>.from(item));
      }).toList();
      list.sort((a, b) => b.when.compareTo(a.when));
      items.assignAll(list);
    }
  }

  void _save() {
    final data = items.map((item) => item.toJson()).toList();
    _box.write(_storageKey, data);
  }

  String _formatTime(DateTime dt) {
    int h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'PM' : 'AM';
    h = h % 12;
    if (h == 0) h = 12;
    return '$h:$m $ampm';
  }
}
