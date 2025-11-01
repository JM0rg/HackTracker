import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../theme/app_colors.dart';

/// Field Diagram Widget
/// 
/// Interactive softball field diagram that:
/// - Displays a softball field using an SVG image
/// - Detects tap locations (x, y) in normalized 0.0-1.0 coordinates
/// - Shows visual feedback with an arc trajectory to the hit location
/// - Calls onTap callback with normalized coordinates
/// - Calls onLongPress callback when held for 2 seconds to clear
class FieldDiagram extends StatefulWidget {
  final void Function(double x, double y) onTap;
  final VoidCallback onLongPress;
  final Map<String, double>? hitLocation; // Current hit location (normalized 0.0-1.0)

  const FieldDiagram({
    super.key,
    required this.onTap,
    required this.onLongPress,
    this.hitLocation,
  });

  @override
  State<FieldDiagram> createState() => _FieldDiagramState();
}

class _FieldDiagramState extends State<FieldDiagram> {
  Offset? _tapPosition;

  @override
  void didUpdateWidget(FieldDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear local tap position when hit location is cleared from parent
    if (widget.hitLocation == null && oldWidget.hitLocation != null) {
      setState(() {
        _tapPosition = null;
      });
    }
  }

  void _handleTap(TapDownDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = details.localPosition;
    final size = box.size;

    // Normalize coordinates to 0.0-1.0
    final normalizedX = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final normalizedY = (localPosition.dy / size.height).clamp(0.0, 1.0);

    setState(() {
      _tapPosition = localPosition;
    });

    widget.onTap(normalizedX, normalizedY);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Convert normalized coordinates to pixel coordinates if provided
        Offset? displayLocation;
        if (widget.hitLocation != null) {
          displayLocation = Offset(
            widget.hitLocation!['x']! * constraints.maxWidth,
            widget.hitLocation!['y']! * constraints.maxHeight,
          );
        } else if (_tapPosition != null) {
          displayLocation = _tapPosition;
        }

        return GestureDetector(
          onTapDown: _handleTap,
          onLongPress: widget.onLongPress,
          child: Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            color: AppColors.background, // Match app background color
            child: Stack(
              children: [
                // Background field SVG image
                Align(
                  alignment: Alignment.topCenter,
                  child: SvgPicture.asset(
                    'assets/images/softball_field.svg',
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    fit: BoxFit.fitWidth, // Fit to width, crop bottom if needed
                    alignment: Alignment.topCenter,
                  ),
                ),
                // Hit location marker on top
                if (displayLocation != null)
                  CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: HitLocationPainter(
                      hitLocation: displayLocation,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Custom Painter for Hit Location Arc
/// 
/// Draws a trajectory arc from home plate to the hit location
/// with a glow effect and a dot marker at the landing point
class HitLocationPainter extends CustomPainter {
  final Offset hitLocation;

  HitLocationPainter({required this.hitLocation});

  @override
  void paint(Canvas canvas, Size size) {
    // Home plate is at bottom center
    final homePlate = Offset(size.width / 2, size.height * 0.85);
    
    // Draw trajectory arc from home plate to hit location
    final arcPaint = Paint()
      ..color = AppColors.accent.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = AppColors.accent.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    // Create a parabolic arc path from home plate to hit location
    final path = Path();
    path.moveTo(homePlate.dx, homePlate.dy);

    // Calculate control point for quadratic bezier (makes it arc upward)
    final midX = (homePlate.dx + hitLocation.dx) / 2;
    final midY = (homePlate.dy + hitLocation.dy) / 2;
    
    // Make the arc height proportional to the distance
    final distance = (hitLocation - homePlate).distance;
    final arcHeight = distance * 0.3; // 30% of distance for arc height
    
    final controlPoint = Offset(midX, midY - arcHeight);

    // Draw quadratic bezier curve
    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      hitLocation.dx,
      hitLocation.dy,
    );

    // Draw glow first (behind)
    canvas.drawPath(path, glowPaint);
    
    // Draw main arc
    canvas.drawPath(path, arcPaint);

    // Draw a small dot at the hit location
    final dotPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    final outerDotPaint = Paint()
      ..color = AppColors.accent.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // Draw outer glow
    canvas.drawCircle(hitLocation, 6, outerDotPaint);
    
    // Draw inner dot
    canvas.drawCircle(hitLocation, 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant HitLocationPainter oldDelegate) {
    return oldDelegate.hitLocation != hitLocation;
  }
}

