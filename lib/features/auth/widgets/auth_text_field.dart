import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.keyboardType,
    this.suffixIcon,
    this.obscureText = false,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final Icon? suffixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,

      decoration: InputDecoration(hintText: hint, suffixIcon: suffixIcon),
    );
  }
}
