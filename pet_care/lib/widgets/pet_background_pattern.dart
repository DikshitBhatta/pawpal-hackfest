import 'package:flutter/material.dart';
import 'dart:math';

/// A widget that paints a fun, semi-random pattern of pet-themed emojis as a background.
///
/// - [opacity]: Controls the transparency of the pattern (default: 0.8)
/// - [symbolSize]: The size of each emoji (default: 80.0)
/// - [density]: How dense the pattern is (0.0 to 1.0, default: 0.3)
class PetBackgroundPattern extends StatelessWidget {
  final double opacity;
  final double symbolSize;
  final double density;
  final bool usePositioned;

  const PetBackgroundPattern({
    Key? key,
    this.opacity = 0.8,
    this.symbolSize = 80.0,
    this.density = 0.3,
    this.usePositioned = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content = Opacity(
      opacity: opacity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use MediaQuery as fallback for unbounded constraints
          final size = Size(
            constraints.maxWidth.isInfinite 
              ? MediaQuery.of(context).size.width 
              : constraints.maxWidth,
            constraints.maxHeight.isInfinite 
              ? MediaQuery.of(context).size.height 
              : constraints.maxHeight,
          );
          
          return CustomPaint(
            size: size,
            painter: _ScatteredPetPatternPainter(
              symbolSize: symbolSize,
              density: density,
            ),
          );
        },
      ),
    );

    // If usePositioned is true (default), wrap in Positioned.fill for Stack usage
    // Otherwise, return the content directly for other layouts
    return usePositioned ? Positioned.fill(child: content) : content;
  }
}

class _ScatteredPetPatternPainter extends CustomPainter {
  final double symbolSize;
  final double density;
  final List<_PetSymbol> symbols = const [
    _PetSymbol('🐾', Color(0xFF008080)), // Teal paws
    _PetSymbol('🦴', Color(0xFFD2B48C)), // Tan bone 
  ];

  _ScatteredPetPatternPainter({required this.symbolSize, required this.density});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = Random(42); // Seed for repeatability
    final cols = (size.width / symbolSize).ceil();
    final rows = (size.height / symbolSize).ceil();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        if (rand.nextDouble() > density) continue;
        final symbol = symbols[rand.nextInt(symbols.length)];
        final dx = (col + rand.nextDouble() * 0.5) * symbolSize;
        final dy = (row + rand.nextDouble() * 0.5) * symbolSize;
        final textPainter = TextPainter(
          text: TextSpan(
            text: symbol.emoji,
            style: TextStyle(
              fontSize: symbolSize,
              color: symbol.color,
              shadows: [
                Shadow(
                  blurRadius: 6,
                  color: Colors.black.withOpacity(0.08),
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(dx, dy));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PetSymbol {
  final String emoji;
  final Color color;
  const _PetSymbol(this.emoji, this.color);
}
