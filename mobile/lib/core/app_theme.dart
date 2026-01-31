import 'package:flutter/material.dart';

/// Premium App Theme for Pickleball Club Management
class AppTheme {
  // ============== COLORS ==============
  // Primary Gradient Colors
  static const Color primaryStart = Color(0xFF667EEA);
  static const Color primaryEnd = Color(0xFF764BA2);
  
  // Secondary/Accent Colors
  static const Color accentCyan = Color(0xFF06D6A0);
  static const Color accentOrange = Color(0xFFFFA726);
  static const Color accentPink = Color(0xFFFF6B9D);
  
  // Background Colors
  static const Color bgLight = Color(0xFFF8FAFF);
  static const Color bgCard = Colors.white;
  static const Color bgDark = Color(0xFF1A1F36);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1F36);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // ============== GRADIENTS ==============
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF06D6A0), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFF6B9D), Color(0xFFFFA726)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A1F36), Color(0xFF2D3561)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // ============== SHADOWS ==============
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF667EEA).withOpacity(0.15),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
  
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 30,
      offset: const Offset(0, 15),
    ),
  ];
  
  // ============== BORDER RADIUS ==============
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 100;
  
  // ============== SPACING ==============
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacing2Xl = 48;
  
  // ============== ANIMATION DURATIONS ==============
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
  
  // ============== DECORATIONS ==============
  static BoxDecoration get glassCard => BoxDecoration(
    color: Colors.white.withOpacity(0.9),
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.all(color: Colors.white.withOpacity(0.2)),
    boxShadow: cardShadow,
  );
  
  static BoxDecoration get premiumCard => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radiusXl),
    boxShadow: elevatedShadow,
  );
  
  static BoxDecoration gradientHeader(LinearGradient gradient) => BoxDecoration(
    gradient: gradient,
    borderRadius: const BorderRadius.only(
      bottomLeft: Radius.circular(32),
      bottomRight: Radius.circular(32),
    ),
  );
  
  // ============== TEXT STYLES ==============
  static const TextStyle headingXl = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.5,
  );
  
  static const TextStyle headingLg = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );
  
  static const TextStyle headingMd = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle bodyLg = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );
  
  static const TextStyle bodySm = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textMuted,
  );
  
  static const TextStyle labelBold = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: textMuted,
    letterSpacing: 0.5,
  );
}

/// Premium Card Widget
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final LinearGradient? gradient;
  final VoidCallback? onTap;
  
  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.gradient,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        padding: padding ?? const EdgeInsets.all(AppTheme.spacingMd),
        decoration: gradient != null 
          ? BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              boxShadow: AppTheme.cardShadow,
            )
          : AppTheme.premiumCard,
        child: child,
      ),
    );
  }
}

/// Animated Icon Button
class AnimatedIconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final Color? bgColor;
  
  const AnimatedIconBtn({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
    this.bgColor,
  });
  
  @override
  State<AnimatedIconBtn> createState() => _AnimatedIconBtnState();
}

class _AnimatedIconBtnState extends State<AnimatedIconBtn> {
  bool _pressed = false;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0,
        duration: AppTheme.animFast,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.bgColor ?? Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Icon(widget.icon, color: widget.color ?? Colors.white, size: 20),
        ),
      ),
    );
  }
}

/// Page Transitions
class SlidePageRoute extends PageRouteBuilder {
  final Widget page;
  
  SlidePageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: AppTheme.animNormal,
      );
}

class FadePageRoute extends PageRouteBuilder {
  final Widget page;
  
  FadePageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: AppTheme.animNormal,
      );
}
