import 'package:flutter/material.dart';
import '../models/tetromino.dart';

class RotationSelector extends StatelessWidget {
  final Tetromino currentTetromino;
  final int selectedRotationIndex;
  final Function(int) onSelect;

  const RotationSelector({
    super.key,
    required this.currentTetromino,
    required this.selectedRotationIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: Colors.grey[900],
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SizedBox(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                final isSelected = selectedRotationIndex == index;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: GestureDetector(
                      onTap: () => onSelect(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blueAccent.withOpacity(0.3) : Colors.grey[850],
                          border: isSelected
                            ? Border.all(color: Colors.blueAccent, width: 2)
                            : Border.all(color: Colors.white24, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final size = constraints.biggest.shortestSide * 0.9;
                            return Center(
                              child: SizedBox(
                                width: size,
                                height: size,
                                child: CustomPaint(
                                  size: Size(size, size),
                                  painter: _MiniTetrominoPainter(
                                    tetromino: currentTetromino,
                                    rotationIndex: index,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniTetrominoPainter extends CustomPainter {
  final Tetromino tetromino;
  final int rotationIndex;

  _MiniTetrominoPainter({
    required this.tetromino,
    required this.rotationIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shape = tetromino.shapes[rotationIndex];
    
    // 4x4グリッドに収まるようにサイズ計算
    // ブロックサイズは親コンテナに合わせて計算
    final blockSize = size.width / 5.0; 
    final paint = Paint()..color = tetromino.color;
    
    // 描画の中心を合わせるためのオフセット計算
    // 図形のバウンディングボックスを計算
    int minX = 4, maxX = 0, minY = 4, maxY = 0;
    for (var point in shape) {
      if (point[0] < minX) minX = point[0];
      if (point[0] > maxX) maxX = point[0];
      if (point[1] < minY) minY = point[1];
      if (point[1] > maxY) maxY = point[1];
    }
    
    final contentWidth = (maxX - minX + 1) * blockSize;
    final contentHeight = (maxY - minY + 1) * blockSize;
    
    final offsetX = (size.width - contentWidth) / 2 - minX * blockSize;
    final offsetY = (size.height - contentHeight) / 2 - minY * blockSize;

    for (var point in shape) {
      final rect = Rect.fromLTWH(
        offsetX + point[0] * blockSize,
        offsetY + point[1] * blockSize,
        blockSize - 2, // 隙間
        blockSize - 2,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
