import 'package:flutter/material.dart';
import '../models/tetromino.dart';

class HoldWidget extends StatelessWidget {
  final Tetromino? holdTetromino;
  final bool canHold;
  final VoidCallback onHold;

  const HoldWidget({
    super.key,
    required this.holdTetromino,
    required this.canHold,
    required this.onHold,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canHold ? onHold : null,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: canHold ? Colors.grey : Colors.grey.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(8.0),
          color: canHold ? Colors.black54 : Colors.black26,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HOLD',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: canHold ? Colors.white60 : Colors.white30,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 48,
              height: 48,
              child: holdTetromino != null
                  ? CustomPaint(
                      painter: _HoldMinoPainter(
                        tetromino: holdTetromino!,
                        enabled: canHold,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _HoldMinoPainter extends CustomPainter {
  final Tetromino tetromino;
  final bool enabled;

  _HoldMinoPainter({required this.tetromino, required this.enabled});

  @override
  void paint(Canvas canvas, Size size) {
    final shape = tetromino.shapes[0];

    int minX = 10, maxX = -10, minY = 10, maxY = -10;
    for (var p in shape) {
      if (p[0] < minX) minX = p[0];
      if (p[0] > maxX) maxX = p[0];
      if (p[1] < minY) minY = p[1];
      if (p[1] > maxY) maxY = p[1];
    }

    final width = maxX - minX + 1;
    final height = maxY - minY + 1;

    final cellSize = (size.width / 4).clamp(0.0, size.height / 4);
    final offsetX = (size.width - width * cellSize) / 2 - minX * cellSize;
    final offsetY = (size.height - height * cellSize) / 2 - minY * cellSize;

    final paint = Paint()
      ..color = enabled ? tetromino.color : tetromino.color.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var point in shape) {
      final rect = Rect.fromLTWH(
        offsetX + point[0] * cellSize,
        offsetY + point[1] * cellSize,
        cellSize,
        cellSize,
      );
      canvas.drawRect(rect.deflate(1.0), paint);
      canvas.drawRect(rect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HoldMinoPainter oldDelegate) {
    return oldDelegate.tetromino != tetromino || oldDelegate.enabled != enabled;
  }
}
