import 'package:flutter/material.dart';

class ZyncPalette {
  const ZyncPalette._();

  static const ink = Color(0xFF17181C);
  static const inkSoft = Color(0xFF5F626B);
  static const orange = Color(0xFFFF6A21);
  static const orangeDeep = Color(0xFFE65310);
  static const peach = Color(0xFFFFE5D6);
  static const cream = Color(0xFFFFFAF6);
  static const surface = Color(0xFFFFFFFF);
  static const line = Color(0xFFE9E4DF);
  static const mint = Color(0xFFBDECDD);
  static const blue = Color(0xFF9FC8FF);
  static const plum = Color(0xFF6E5AE6);
}

class ZyncTheme {
  const ZyncTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: ZyncPalette.orange,
      brightness: Brightness.light,
      surface: ZyncPalette.cream,
    ).copyWith(
      primary: ZyncPalette.orange,
      onPrimary: Colors.white,
      secondary: ZyncPalette.plum,
      surface: ZyncPalette.cream,
      onSurface: ZyncPalette.ink,
      outline: ZyncPalette.line,
      surfaceContainerHighest: const Color(0xFFF5F1ED),
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final text = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        color: ZyncPalette.ink,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        height: 1.04,
      ),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        color: ZyncPalette.ink,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.08,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        color: ZyncPalette.ink,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.55,
        height: 1.1,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        color: ZyncPalette.ink,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        color: ZyncPalette.ink,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        color: ZyncPalette.ink,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        color: ZyncPalette.ink,
        height: 1.45,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        color: ZyncPalette.inkSoft,
        height: 1.45,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        color: ZyncPalette.inkSoft,
        height: 1.4,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: ZyncPalette.cream,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ZyncPalette.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: ZyncPalette.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: ZyncPalette.line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: const BorderSide(color: ZyncPalette.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
          foregroundColor: ZyncPalette.ink,
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ZyncPalette.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: ZyncPalette.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: ZyncPalette.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: ZyncPalette.orange, width: 1.6),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: const BorderSide(color: ZyncPalette.line),
        backgroundColor: ZyncPalette.surface,
        selectedColor: ZyncPalette.peach,
        labelStyle: text.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(color: ZyncPalette.line, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ZyncPalette.ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class ZyncMark extends StatelessWidget {
  const ZyncMark({
    super.key,
    this.size = 42,
    this.color = ZyncPalette.orange,
    this.secondaryColor = ZyncPalette.plum,
    this.strokeWidth = 4.5,
  });

  final double size;
  final Color color;
  final Color secondaryColor;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _ZyncMarkPainter(
            primary: color,
            secondary: secondaryColor,
            strokeWidth: strokeWidth,
          ),
        ),
      );
}

class _ZyncMarkPainter extends CustomPainter {
  const _ZyncMarkPainter({
    required this.primary,
    required this.secondary,
    required this.strokeWidth,
  });

  final Color primary;
  final Color secondary;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide * 0.29;
    final y = size.height * 0.5;
    final left = Offset(size.width * 0.38, y);
    final right = Offset(size.width * 0.62, y);
    final primaryPaint = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final secondaryPaint = Paint()
      ..color = secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(left, r, primaryPaint);
    canvas.drawCircle(right, r, secondaryPaint);

    final centerPaint = Paint()..color = ZyncPalette.ink;
    canvas.drawCircle(Offset(size.width * 0.5, y), size.shortestSide * 0.055, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _ZyncMarkPainter oldDelegate) =>
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary ||
      oldDelegate.strokeWidth != strokeWidth;
}

class ConnectionBackdrop extends StatelessWidget {
  const ConnectionBackdrop({
    super.key,
    this.child,
    this.padding = EdgeInsets.zero,
  });

  final Widget? child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: const _ConnectionBackdropPainter(),
        child: Padding(padding: padding, child: child),
      );
}

class _ConnectionBackdropPainter extends CustomPainter {
  const _ConnectionBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = ZyncPalette.orange.withValues(alpha: 0.08)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    final plumLine = Paint()
      ..color = ZyncPalette.plum.withValues(alpha: 0.065)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    final node = Paint()..color = ZyncPalette.orange.withValues(alpha: 0.12);
    final node2 = Paint()..color = ZyncPalette.plum.withValues(alpha: 0.1);

    final points = <Offset>[
      Offset(size.width * 0.08, size.height * 0.12),
      Offset(size.width * 0.36, size.height * 0.06),
      Offset(size.width * 0.66, size.height * 0.16),
      Offset(size.width * 0.92, size.height * 0.08),
      Offset(size.width * 0.18, size.height * 0.42),
      Offset(size.width * 0.52, size.height * 0.36),
      Offset(size.width * 0.86, size.height * 0.48),
    ];

    void connect(int a, int b, Paint paint) => canvas.drawLine(points[a], points[b], paint);
    connect(0, 1, line);
    connect(1, 2, plumLine);
    connect(2, 3, line);
    connect(0, 4, plumLine);
    connect(1, 5, line);
    connect(2, 5, plumLine);
    connect(2, 6, line);

    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], i.isEven ? 4.2 : 3.2, i.isEven ? node : node2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ZyncSurface extends StatelessWidget {
  const ZyncSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.backgroundColor = ZyncPalette.surface,
    this.borderColor = ZyncPalette.line,
    this.radius = 24,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final double radius;
  final bool shadow;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor),
          boxShadow: shadow
              ? [
                  BoxShadow(
                    color: ZyncPalette.ink.withValues(alpha: 0.045),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: child,
      );
}

class ZyncIconTile extends StatelessWidget {
  const ZyncIconTile({
    super.key,
    required this.icon,
    this.backgroundColor = ZyncPalette.peach,
    this.foregroundColor = ZyncPalette.orangeDeep,
    this.size = 46,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(size * 0.34),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: foregroundColor, size: size * 0.46),
      );
}
