import 'package:flutter/material.dart';
import 'package:help_ride/shared/widgets/place_picker_field.dart';
import '../../../core/theme/app_colors.dart';

typedef ConfirmBookingSubmit =
    void Function({
      required String pickupName,
      required String dropoffName,
      required double pickupLat,
      required double pickupLng,
      required double dropoffLat,
      required double dropoffLng,
    });

class ConfirmBookingSheet extends StatefulWidget {
  const ConfirmBookingSheet({
    super.key,
    required this.routeText,
    required this.dateText,
    required this.seats,
    required this.total,
    required this.initialPickup,
    required this.initialDropoff,
    this.initialPickupLat,
    this.initialPickupLng,
    this.initialDropoffLat,
    this.initialDropoffLng,
    required this.onCancel,
    required this.onConfirm,
  });

  final String routeText;
  final String dateText;
  final int seats;
  final double total;
  final String initialPickup;
  final String initialDropoff;
  final double? initialPickupLat;
  final double? initialPickupLng;
  final double? initialDropoffLat;
  final double? initialDropoffLng;
  final VoidCallback onCancel;
  final ConfirmBookingSubmit onConfirm;

  @override
  State<ConfirmBookingSheet> createState() => _ConfirmBookingSheetState();
}

class _ConfirmBookingSheetState extends State<ConfirmBookingSheet> {
  late final TextEditingController _pickupController;
  late final TextEditingController _dropoffController;
  LatLng? _pickupLatLng;
  LatLng? _dropoffLatLng;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _pickupController = TextEditingController(text: widget.initialPickup);
    _dropoffController = TextEditingController(text: widget.initialDropoff);
    final pickupLat = widget.initialPickupLat;
    final pickupLng = widget.initialPickupLng;
    final dropoffLat = widget.initialDropoffLat;
    final dropoffLng = widget.initialDropoffLng;
    if (pickupLat != null && pickupLng != null) {
      _pickupLatLng = LatLng(pickupLat, pickupLng);
    }
    if (dropoffLat != null && dropoffLng != null) {
      _dropoffLatLng = LatLng(dropoffLat, dropoffLng);
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  void _submit() {
    final pickup = _pickupController.text.trim();
    final dropoff = _dropoffController.text.trim();
    if (pickup.isEmpty || dropoff.isEmpty) {
      setState(() => _errorText = 'Pickup and drop-off are required.');
      return;
    }
    final pickupLatLng = _pickupLatLng;
    final dropoffLatLng = _dropoffLatLng;
    if (pickupLatLng == null || dropoffLatLng == null) {
      setState(
        () =>
            _errorText = 'Please pick both locations from Google suggestions.',
      );
      return;
    }
    if (_errorText != null) {
      setState(() => _errorText = null);
    }
    widget.onConfirm(
      pickupName: pickup,
      dropoffName: dropoff,
      pickupLat: pickupLatLng.lat,
      pickupLng: pickupLatLng.lng,
      dropoffLat: dropoffLatLng.lat,
      dropoffLng: dropoffLatLng.lng,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6EAF2),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Confirm Booking Request',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE6EAF2)),
                    ),
                    child: Column(
                      children: [
                        _Row(label: 'Route', value: widget.routeText),
                        const SizedBox(height: 10),
                        _Row(label: 'Date & Time', value: widget.dateText),
                        const SizedBox(height: 10),
                        _Row(label: 'Seats', value: '${widget.seats}'),
                        const Divider(height: 20),
                        _Row(
                          label: 'Total',
                          value: '\$${widget.total.toStringAsFixed(0)}',
                          bold: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),
                  PlacePickerField(
                    label: 'Passenger pickup',
                    controller: _pickupController,
                    hintText: 'Enter your pickup location',
                    icon: Icons.my_location,
                    onPicked: (picked) {
                      _pickupLatLng = picked.latLng;
                      if (_errorText != null) {
                        setState(() => _errorText = null);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  PlacePickerField(
                    label: 'Passenger drop-off',
                    controller: _dropoffController,
                    hintText: 'Enter your destination',
                    icon: Icons.place,
                    iconColor: AppColors.passengerPrimary,
                    onPicked: (picked) {
                      _dropoffLatLng = picked.latLng;
                      if (_errorText != null) {
                        setState(() => _errorText = null);
                      }
                    },
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _errorText!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onCancel,
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.passengerPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                          child: const Text(
                            'Request',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92, // keeps columns aligned
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.lightMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
