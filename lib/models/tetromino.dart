import 'package:flutter/material.dart';

enum TetrominoType { I, O, T, S, Z, J, L }

class Tetromino {
  final TetrominoType type;
  final Color color;
  // 各回転状態におけるブロックの相対座標 (4パターン x 4ブロック x (x, y))
  // 座標は左上を(0,0)とする相対的なもの、あるいは中心からのオフセット
  // ここでは扱いやすさのため、各パターンを 4x4 または 3x3 などのグリッド内での座標リストとして保持する
  final List<List<List<int>>> shapes; 

  const Tetromino({
    required this.type,
    required this.color,
    required this.shapes,
  });

  static const List<TetrominoType> allTypes = TetrominoType.values;

  static Tetromino get(TetrominoType type) {
    switch (type) {
      case TetrominoType.I:
        return i;
      case TetrominoType.O:
        return o;
      case TetrominoType.T:
        return t;
      case TetrominoType.S:
        return s;
      case TetrominoType.Z:
        return z;
      case TetrominoType.J:
        return j;
      case TetrominoType.L:
        return l;
    }
  }

  // 定義 (SRS準拠に近い形で定義するが、表示用に調整しても良い)
  // ここでは配置ロジックを簡単にするため、ブロックが存在する相対座標のリストを持つ
  // [パターンインデックス][ブロックインデックス][x, y]

  static const i = Tetromino(
    type: TetrominoType.I,
    color: Colors.cyan,
    shapes: [
      [[0, 1], [1, 1], [2, 1], [3, 1]], // 0: 水平
      [[2, 0], [2, 1], [2, 2], [2, 3]], // 1: 垂直
      [[0, 2], [1, 2], [2, 2], [3, 2]], // 2: 水平
      [[1, 0], [1, 1], [1, 2], [1, 3]], // 3: 垂直
    ],
  );

  static const o = Tetromino(
    type: TetrominoType.O,
    color: Colors.yellow,
    shapes: [
      [[1, 0], [2, 0], [1, 1], [2, 1]], // Oは回転しても同じだが、システム上4つ定義しておく
      [[1, 0], [2, 0], [1, 1], [2, 1]],
      [[1, 0], [2, 0], [1, 1], [2, 1]],
      [[1, 0], [2, 0], [1, 1], [2, 1]],
    ],
  );

  static const t = Tetromino(
    type: TetrominoType.T,
    color: Colors.purple,
    shapes: [
      [[1, 0], [0, 1], [1, 1], [2, 1]], // 上凸
      [[1, 0], [1, 1], [2, 1], [1, 2]], // 右凸
      [[0, 1], [1, 1], [2, 1], [1, 2]], // 下凸
      [[1, 0], [0, 1], [1, 1], [1, 2]], // 左凸
    ],
  );

  static const s = Tetromino(
    type: TetrominoType.S,
    color: Colors.green,
    shapes: [
      [[1, 0], [2, 0], [0, 1], [1, 1]], 
      [[1, 0], [1, 1], [2, 1], [2, 2]], 
      [[1, 1], [2, 1], [0, 2], [1, 2]], 
      [[0, 0], [0, 1], [1, 1], [1, 2]], 
    ],
  );

  static const z = Tetromino(
    type: TetrominoType.Z,
    color: Colors.red,
    shapes: [
      [[0, 0], [1, 0], [1, 1], [2, 1]], 
      [[2, 0], [1, 1], [2, 1], [1, 2]], 
      [[0, 1], [1, 1], [1, 2], [2, 2]], 
      [[1, 0], [0, 1], [1, 1], [0, 2]], 
    ],
  );

  static const j = Tetromino(
    type: TetrominoType.J,
    color: Colors.blue,
    shapes: [
      [[0, 0], [0, 1], [1, 1], [2, 1]], 
      [[1, 0], [2, 0], [1, 1], [1, 2]], 
      [[0, 1], [1, 1], [2, 1], [2, 2]], 
      [[1, 0], [1, 1], [0, 2], [1, 2]], 
    ],
  );

  static const l = Tetromino(
    type: TetrominoType.L,
    color: Colors.orange,
    shapes: [
      [[2, 0], [0, 1], [1, 1], [2, 1]], 
      [[1, 0], [1, 1], [1, 2], [2, 2]], 
      [[0, 1], [1, 1], [2, 1], [0, 2]], 
      [[0, 0], [1, 0], [1, 1], [1, 2]], 
    ],
  );
}
