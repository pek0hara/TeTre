import 'package:flutter/material.dart';
import '../models/board_state.dart';
import '../models/tetromino.dart';

class BoardWidget extends StatefulWidget {
  final BoardState boardState;
  final Tetromino currentTetromino;
  final int rotationIndex;
  final Function(int x, int y) onPlace;

  const BoardWidget({
    super.key,
    required this.boardState,
    required this.currentTetromino,
    required this.rotationIndex,
    required this.onPlace,
  });

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  int? _previewX;
  int? _previewY;

  // ミノのバウンディングボックスの中心を計算
  List<double> _getBoundingBoxCenter(Tetromino tetromino, int rotationIndex) {
    final shape = tetromino.shapes[rotationIndex];
    int minX = 10, maxX = -10, minY = 10, maxY = -10;
    for (var p in shape) {
      if (p[0] < minX) minX = p[0];
      if (p[0] > maxX) maxX = p[0];
      if (p[1] < minY) minY = p[1];
      if (p[1] > maxY) maxY = p[1];
    }
    // ブロックの中心（セルの中央を考慮して+0.5）
    return [(minX + maxX) / 2.0 + 0.5, (minY + maxY) / 2.0 + 0.5];
  }

  void _updatePreview(Offset localPosition, double cellSize) {
    // タップ位置をセル座標に変換（小数点で正確に）
    final tapX = localPosition.dx / cellSize;
    final tapY = localPosition.dy / cellSize;

    // バウンディングボックスの中心を取得
    final center = _getBoundingBoxCenter(widget.currentTetromino, widget.rotationIndex);

    // 配置開始位置 = タップ位置 - 中心
    final startX = (tapX - center[0]).round();
    final startY = (tapY - center[1]).round();

    setState(() {
      _previewX = startX;
      _previewY = startY;
    });
  }

  void _clearPreview() {
    setState(() {
      _previewX = null;
      _previewY = null;
    });
  }

  void _confirmPlace() {
    if (_previewX != null && _previewY != null) {
      // _previewX/Yは既に配置開始位置なので、直接渡す
      widget.onPlace(_previewX!, _previewY!);
    }
    _clearPreview();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: BoardState.cols / BoardState.rows,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          color: Colors.black87,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellSize = constraints.maxWidth / BoardState.cols;

            return GestureDetector(
              onPanStart: (details) {
                _updatePreview(details.localPosition, cellSize);
              },
              onPanUpdate: (details) {
                _updatePreview(details.localPosition, cellSize);
              },
              onPanEnd: (details) {
                _confirmPlace();
              },
              onTapDown: (details) {
                _updatePreview(details.localPosition, cellSize);
              },
              onTapUp: (details) {
                _confirmPlace();
              },
              child: CustomPaint(
                painter: _BoardPainter(
                  boardState: widget.boardState,
                  cellSize: cellSize,
                  previewTetromino: (_previewX != null && _previewY != null)
                      ? widget.currentTetromino
                      : null,
                  previewRotationIndex: widget.rotationIndex,
                  previewX: _previewX,
                  previewY: _previewY,
                ),
                size: Size(constraints.maxWidth, constraints.maxHeight),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  final BoardState boardState;
  final double cellSize;
  final Tetromino? previewTetromino;
  final int previewRotationIndex;
  final int? previewX;
  final int? previewY;

  _BoardPainter({
    required this.boardState,
    required this.cellSize,
    this.previewTetromino,
    this.previewRotationIndex = 0,
    this.previewX,
    this.previewY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // プレビュー位置を計算
    Set<String> previewCells = {};
    bool canPlace = false;

    if (previewTetromino != null && previewX != null && previewY != null) {
      canPlace = boardState.canPlace(previewTetromino!, previewRotationIndex, previewX!, previewY!);
      final shape = previewTetromino!.shapes[previewRotationIndex];
      for (var point in shape) {
        final px = previewX! + point[0];
        final py = previewY! + point[1];
        previewCells.add('$px,$py');
      }
    }

    for (int y = 0; y < BoardState.rows; y++) {
      for (int x = 0; x < BoardState.cols; x++) {
        final color = boardState.getCell(x, y);
        final rect = Rect.fromLTWH(
          x * cellSize,
          y * cellSize,
          cellSize,
          cellSize,
        );

        // グリッド線
        canvas.drawRect(rect, borderPaint);

        // プレビュー描画
        final cellKey = '$x,$y';
        if (previewCells.contains(cellKey)) {
          if (canPlace) {
            // 配置可能: 半透明で表示
            paint.color = previewTetromino!.color.withOpacity(0.5);
          } else {
            // 配置不可: 赤く表示
            paint.color = Colors.red.withOpacity(0.5);
          }
          canvas.drawRect(rect.deflate(1.0), paint);
        }
        // 既存ブロック描画
        else if (color != null) {
          paint.color = color;
          canvas.drawRect(rect.deflate(1.0), paint);

          // ハイライト（立体感）
          final highlightPaint = Paint()..color = Colors.white30;
          canvas.drawRect(
            Rect.fromLTWH(rect.left + 2, rect.top + 2, cellSize - 4, cellSize / 3),
            highlightPaint
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) {
    return true;
  }
}
