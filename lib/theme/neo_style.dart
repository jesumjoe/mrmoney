import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NeoColors {
  // Soft Neo-Brutalist Palette (Pastel Pop)
  static const Color primary = Color(0xFFD8B4FE); // Lavender
  static const Color primaryDark = Color(0xFFC084FC); // Darker Lavender
  static const Color secondary = Color(0xFFFDE047); // Soft Yellow
  static const Color accent = Color(0xFF86EFAC); // Mint Green
  static const Color background = Color(0xFFF8FAFC); // Off-White / Gray-50
  static const Color surface = Colors.white;
  static const Color text = Color(0xFF1F2937); // Gray-800
  static const Color border = Colors.black; // Keep strict black borders

  // Semantic Colors
  static const Color success = Color(0xFF86EFAC); // Mint
  static const Color warning = Color(0xFFFCD34D); // Amber
  static const Color error = Color(0xFFFCA5A5); // Soft Red / Salmon
  static const Color info = Color(0xFF93C5FD); // Soft Blue

  // Specifics
  static const Color cardBase = Colors.white;

  // Backwards compatibility aliases
  static const Color mint = success;
  static const Color salmon = error;
  static const Color indigo = primary;
  static const Color yellow = secondary;
}

class NeoStyle {
  static const double borderWidth = 2.0;
  static const double radius = 24.0; // Much rounder
  static const Offset shadowOffset = Offset(4, 4);

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
                color: borderColor,
                offset: shadowOffset,
                blurRadius: 0, // Hard shadow
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
        BoxShadow(color: borderColor, offset: shadowOffset, blurRadius: 0),
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
      fontWeight: fontWeight ?? FontWeight.w700, // SemiBold/Bold
      color: color ?? NeoColors.text,
    );
  }

  static TextStyle regular({double? fontSize, Color? color}) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: FontWeight.w500, // Medium
      color: color ?? NeoColors.text,
    );
  }

  // Input Decoration
  static InputDecoration inputDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(color: Colors.grey.shade600),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
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
  }) {
    return showDialog<T>(
      context: context,
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

class NeoCard extends StatefulWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final double? height;
  final double? width;

  const NeoCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 16),
    this.onTap,
    this.height,
    this.width,
  });

  @override
  State<NeoCard> createState() => _NeoCardState();
}

class _NeoCardState extends State<NeoCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            height: widget.height,
            width: widget.width,
            margin: widget.margin,
            padding: widget.padding,
            decoration: NeoStyle.box(color: widget.color ?? Colors.white),
            child: widget.child,
          ),
        ),
      );
    }
    return Container(
      height: widget.height,
      width: widget.width,
      margin: widget.margin,
      padding: widget.padding,
      decoration: NeoStyle.box(color: widget.color ?? Colors.white),
      child: widget.child,
    );
  }
}

class NeoButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final double? width;

  const NeoButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.textColor,
    this.width,
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: widget.width,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        transform: _isPressed
            ? Matrix4.translationValues(
                NeoStyle.shadowOffset.dx,
                NeoStyle.shadowOffset.dy,
                0,
              )
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: widget.onPressed == null
              ? Colors.grey.shade300
              : (widget.color ?? NeoColors.secondary),
          borderRadius: BorderRadius.circular(NeoStyle.radius),
          border: Border.all(
            color: NeoColors.border,
            width: NeoStyle.borderWidth,
          ),
          boxShadow: _isPressed || widget.onPressed == null
              ? []
              : [
                  const BoxShadow(
                    color: NeoColors.border,
                    offset: NeoStyle.shadowOffset,
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Text(
          widget.text,
          style: NeoStyle.bold(
            fontSize: 16,
            color: widget.textColor ?? NeoColors.text,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
