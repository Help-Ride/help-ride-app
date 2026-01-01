import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OAuthButton extends StatelessWidget {
  final IconData? icon;          // OPTIONAL
  final String? imageAsset;      // OPTIONAL
  final double iconSize;
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const OAuthButton({
    super.key,
    this.icon,
    this.imageAsset,
    this.iconSize = 24,
    required this.label,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: Colors.black87,
        ),
        child: isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageAsset != null) ...[
              Image.asset(
                imageAsset!,
                height: 20,
                width: 20,
              ),
              const SizedBox(width: 8),
            ] else if (icon != null) ...[
              Icon(icon, size: iconSize, color: Colors.black87),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.arimo(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
