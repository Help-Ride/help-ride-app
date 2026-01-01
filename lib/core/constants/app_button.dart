import 'package:flutter/material.dart';

class GradientAppButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final bool enabled;
  final String? prefixImage;
  final Widget? suffix;
  final double height;
  final BorderRadius borderRadius;

  const GradientAppButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.enabled = true,
    this.prefixImage,
    this.suffix,
    this.height = 54,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    final disabled = !enabled || isLoading;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: disabled
                ? [
              const Color(0xFF00BC7D).withOpacity(0.5),
              const Color(0xFF009689).withOpacity(0.5),
            ]
                : const [
              Color(0xFF00BC7D),
              Color(0xFF009689),
            ],
          ),
          borderRadius: borderRadius,
        ),
        child: ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius,
            ),
          ),
          child: isLoading
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (prefixImage != null) ...[
                Image.asset(
                  prefixImage!,
                  height: 16,
                  width: 16,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 8),
                suffix!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
