import 'package:flutter/material.dart';
import '../models/tetromino.dart';

class NextMinoWidget extends StatelessWidget {
  final List<Tetromino> nextQueue;

  const NextMinoWidget({
    super.key,
    required this.nextQueue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.black54,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'NEXT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 4),
          ...nextQueue.take(5).map((tetromino) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: SizedBox(
              width: 48,
              height: 48,
              child: CustomPaint(
                painter: _NextMinoPainter(tetromino: tetromino),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class _NextMinoPainter extends CustomPainter {
  final Tetromino tetromino;

  _NextMinoPainter({required this.tetromino});

  @override
  void paint(Canvas canvas, Size size) {
    final shape = tetromino.shapes[0]; // 回転0の形状を表示

    // バウンディングボックスを計算
    int minX = 10, maxX = -10, minY = 10, maxY = -10;
    for (var p in shape) {
      if (p[0] < minX) minX = p[0];
      if (p[0] > maxX) maxX = p[0];
      if (p[1] < minY) minY = p[1];
      if (p[1] > maxY) maxY = p[1];
    }

    final width = maxX - minX + 1;
    final height = maxY - minY + 1;

    // セルサイズを計算（中央に配置）
    final cellSize = (size.width / 4).clamp(0.0, size.height / 4);
    final offsetX = (size.width - width * cellSize) / 2 - minX * cellSize;
    final offsetY = (size.height - height * cellSize) / 2 - minY * cellSize;

    final paint = Paint()
      ..color = tetromino.color
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
  bool shouldRepaint(covariant _NextMinoPainter oldDelegate) {
    return oldDelegate.tetromino != tetromino;
  }
}
