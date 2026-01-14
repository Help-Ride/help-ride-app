import '../models/trip.dart';
import '../models/ride_card_vm.dart';

class RideMapper {
  static RideCardVM toCardVM(Trip t) {
    final departure = _formatDeparture(t.startTime);

    // duration: if arrivalTime is null, you can show "-" or estimate later
    final duration = t.arrivalTime == null
        ? '-'
        : _formatDuration(t.arrivalTime!.difference(t.startTime));

    // Placeholder driver data (until you have driver endpoint)
    final driverName = 'Driver'; // you can set from driverId short
    final driverInitials = 'DR';

    return RideCardVM(
      rideId: t.id,
      driverId: t.driverId,
      driverName: driverName,
      driverInitials: driverInitials,
      verified: true, // until you have this from backend
      rating: 4.8, // until you have this from backend
      ridesCount: 0, // until you have this from backend
      departureLabel: departure,
      durationLabel: duration,
      seatsAvailable: t.seatsAvailable,
      pricePerSeat: t.pricePerSeat,
    );
  }

  static String _formatDeparture(DateTime dt) {
    // Simple formatter (no intl dependency)
    // Example: Today, 2:30 PM OR Dec 20, 8:00 AM
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

  static String _formatTime(DateTime dt) {
    int h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'PM' : 'AM';
    h = h % 12;
    if (h == 0) h = 12;
    return '$h:$m $ampm';
  }

  static String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    if (mins <= 0) return '-';
    if (mins < 60) return '${mins} min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}
