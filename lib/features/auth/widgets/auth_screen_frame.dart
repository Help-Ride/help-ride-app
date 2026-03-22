import 'package:flutter/material.dart';

class AuthScreenFrame extends StatelessWidget {
  const AuthScreenFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final compact = MediaQuery.sizeOf(context).width < 540;

    final content = compact
        ? Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: child,
          )
        : Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF232836)
                    : const Color(0xFFE6EAF2),
              ),
              boxShadow: isDark
                  ? null
                  : const [
                      BoxShadow(
                        blurRadius: 30,
                        offset: Offset(0, 18),
                        color: Color(0x14000000),
                      ),
                    ],
            ),
            child: child,
          );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 0 : 24,
            vertical: compact ? 0 : 20,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
