import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NeoColors {
  // Monochrome Palette
  static const Color primary = Colors.black;
  static const Color primaryDark = Color(0xFF171717); // Neutral 900
  static const Color secondary = Color(0xFFE5E5E5); // Neutral 200
  static const Color accent = Color(0xFF525252); // Neutral 600
  static const Color background = Colors.white;
  static const Color surface = Color(0xFFFAFAFA); // Neutral 50
  static const Color text = Colors.black;
  static const Color textSecondary = Color(0xFF737373); // Neutral 500
  static const Color border = Color(0xFFE5E5E5); // Light Gray Border

  // Semantic Colors
  static const Color success = Color(0xFF22C55E); // Green 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color info = Color(0xFF3B82F6); // Blue 500

  // Specifics
  static const Color cardBase = Colors.white;

  // Backwards compatibility aliases (Maps to monochrome/semantic)
  static const Color mint = success;
  static const Color salmon = error;
  static const Color indigo = primary;
  static const Color yellow = secondary;
}

class NeoStyle {
  static const double borderWidth = 1.0;
  static const double radius = 16.0;
  static const Offset shadowOffset = Offset(0, 4); // Soft drop shadow

  static BoxDecoration box({
    Color color = Colors.white,
    Color borderColor = NeoColors.border,
    double radius = NeoStyle.radius,
    bool noShadow = false,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: noShadow
          ? []
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: shadowOffset,
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
    );
  }

  static BoxDecoration circle({
    Color color = Colors.white,
    Color borderColor = NeoColors.border,
  }) {
    return BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          offset: shadowOffset,
          blurRadius: 12,
        ),
      ],
    );
  }

  // Text Styles
  static TextStyle bold({
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w700,
      color: color ?? NeoColors.text,
    );
  }

  static TextStyle regular({double? fontSize, Color? color}) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      color: color ?? NeoColors.text,
    );
  }

  // Input Decoration
  static InputDecoration inputDecoration({
    String? hintText,
    String? labelText,
    String? prefixText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      prefixText: prefixText,
      labelStyle: GoogleFonts.inter(color: NeoColors.textSecondary),
      prefixStyle: GoogleFonts.inter(
        color: NeoColors.text,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      hintStyle: GoogleFonts.inter(color: NeoColors.textSecondary),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: NeoColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(
          color: NeoColors.border,
          width: borderWidth,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(
          color: NeoColors.border,
          width: borderWidth,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(
          color: NeoColors.primary,
          width: borderWidth,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(
          color: NeoColors.error,
          width: borderWidth,
        ),
      ),
    );
  }

  static Future<T?> showNeoDialog<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: box(color: Colors.white, radius: radius),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: bold(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              content,
              if (actions != null) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class NeoCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final double? height;
  final double? width;
  final bool noShadow;

  const NeoCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(20),
    this.margin = const EdgeInsets.only(bottom: 16),
    this.onTap,
    this.height,
    this.width,
    this.noShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      height: height,
      width: width,
      margin: margin,
      padding: padding,
      decoration: NeoStyle.box(
        color: color ?? Colors.white,
        noShadow: noShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

class NeoButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final double? width;
  final bool outline;

  const NeoButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.textColor,
    this.width,
    this.outline = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = outline ? Colors.transparent : (color ?? NeoColors.primary);
    final fgColor = outline
        ? (textColor ?? NeoColors.text)
        : (textColor ?? Colors.white);

    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: Colors.grey.shade200,
          disabledForegroundColor: Colors.grey.shade400,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeoStyle.radius),
            side: outline
                ? const BorderSide(color: NeoColors.border, width: 1)
                : BorderSide.none,
          ),
          shadowColor: Colors.transparent,
        ),
        child: Text(
          text,
          style: NeoStyle.bold(fontSize: 16, color: fgColor),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
