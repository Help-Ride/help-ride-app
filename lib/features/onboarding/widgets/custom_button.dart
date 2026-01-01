import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isLoading;
  final double? height;
  final double? width;
  final double radius;
  final List<Color>? gradientColors;
  final Color? bgColor;
  final Color textColor;
  final FontWeight fontWeight;
  final double fontSize;
  final IconData? icon;
  final Color? iconColor;

  final String? imagePath;   // <-- NEW: Asset image
  final EdgeInsetsGeometry? margin;   // <-- NEW
  final EdgeInsetsGeometry? padding;  // <-- NEW (inner spacing)

  const CustomButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isLoading = false,
    this.height,
    this.width,
    this.radius = 30,
    this.gradientColors,
    this.bgColor,
    this.textColor = Colors.white,
    this.fontWeight = FontWeight.w600,
    this.fontSize = 16,
    this.icon,
    this.iconColor,
    this.imagePath,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin, // ← NEW
      child: GestureDetector(
        onTap: isLoading ? () {} : onTap,
        child: Container(
          height: height ?? 55,
          width: width ?? double.infinity,
          padding: padding ?? EdgeInsets.symmetric(horizontal: 14), // ← NEW
          decoration: BoxDecoration(
            color: gradientColors == null ? bgColor ?? Colors.green : null,
            gradient: gradientColors != null
                ? LinearGradient(colors: gradientColors!)
                : null,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            )
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- IMAGE BEFORE TEXT ---
                if (imagePath != null) ...[
                  Image.asset(
                    imagePath!,
                    height: 20,
                    width: 20,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: 8),
                ],

                // --- TEXT ---
                Text(
                  text,
                  style: GoogleFonts.inter(
                    color: textColor,
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                  ),
                ),

                // --- ICON AFTER TEXT ---
                if (icon != null) ...[
                  SizedBox(width: 8),
                  Icon(
                    icon,
                    color: iconColor ?? Colors.white,
                    size: 14,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
