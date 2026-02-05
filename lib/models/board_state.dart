import 'package:flutter/material.dart';
import 'tetromino.dart';

enum GameMode { puzzle, ren }

class BoardState extends ChangeNotifier {
  static const int rows = 20;
  static const int cols = 10;
  static const int targetLines = 40; // クリア目標ライン数

  // 盤面データ: nullなら空、Colorならブロックあり
  final List<List<Color?>> _grid;

  // 消去したライン数
  int _linesCleared = 0;
  int get linesCleared => _linesCleared;
  int get linesRemaining => targetLines - _linesCleared;

  // 現在のスコア
  int _score = 0;
  int get score => _score;

  // REN(コンボ)カウント
  int _ren = 0;
  int get ren => _ren;

  // Back-to-Back判定用（前回がTetrisまたはT-Spinだったか）
  bool _lastWasDifficult = false;
  bool get lastWasDifficult => _lastWasDifficult;

  // ゲームオーバー状態
  bool _isGameOver = false;
  bool get isGameOver => _isGameOver;

  // ゲームクリア状態
  bool _isCleared = false;
  bool get isCleared => _isCleared;

  // 最後のアクション情報（UI表示用）
  String _lastAction = '';
  String get lastAction => _lastAction;

  // ゲームモード
  GameMode _mode = GameMode.puzzle;
  GameMode get mode => _mode;

  // Renモード用：最大REN記録
  int _maxRen = 0;
  int get maxRen => _maxRen;

  // Renモード用：壁の色
  static const Color _wallColor = Color(0xFF505050);

  BoardState() : _grid = List.generate(rows, (_) => List.filled(cols, null));

  Color? getCell(int x, int y) {
    if (x < 0 || x >= cols || y < 0 || y >= rows) return null;
    return _grid[y][x];
  }

  // 盤面外または埋まっているかチェック
  bool _isBlocked(int x, int y) {
    if (x < 0 || x >= cols || y < 0 || y >= rows) return true;
    return _grid[y][x] != null;
  }

  // 指定された位置（左上基準）にブロックを配置できるか判定
  bool canPlace(Tetromino tetromino, int rotationIndex, int startX, int startY) {
    final shape = tetromino.shapes[rotationIndex];
    for (var point in shape) {
      final x = startX + point[0];
      final y = startY + point[1];

      // 盤面外チェック
      if (x < 0 || x >= cols || y < 0 || y >= rows) {
        return false;
      }

      // 既存ブロックとの衝突チェック
      if (_grid[y][x] != null) {
        return false;
      }
    }
    return true;
  }

  // T-Spin判定（配置後、落下前に呼ぶ）
  bool _checkTSpin(Tetromino tetromino, int rotationIndex, int startX, int startY) {
    if (tetromino.type != TetrominoType.T) return false;

    // Tミノの中心位置（回転状態に関係なく(1,1)が中心）
    final centerX = startX + 1;
    final centerY = startY + 1;

    // 四隅のチェック
    final corners = [
      [centerX - 1, centerY - 1], // 左上
      [centerX + 1, centerY - 1], // 右上
      [centerX - 1, centerY + 1], // 左下
      [centerX + 1, centerY + 1], // 右下
    ];

    int blockedCorners = 0;
    for (var corner in corners) {
      if (_isBlocked(corner[0], corner[1])) {
        blockedCorners++;
      }
    }

    // 3つ以上の角が埋まっていればT-Spin
    return blockedCorners >= 3;
  }

  // ブロックを配置し、重力落下後にライン消去判定を行う
  // 戻り値: 配置できたかどうか
  bool place(Tetromino tetromino, int rotationIndex, int startX, int startY) {
    if (!canPlace(tetromino, rotationIndex, startX, startY)) {
      return false;
    }

    final shape = tetromino.shapes[rotationIndex];

    // 配置するブロックの座標を収集
    final placedBlocks = <List<int>>[];
    for (var point in shape) {
      final x = startX + point[0];
      final y = startY + point[1];
      placedBlocks.add([x, y]);
      _grid[y][x] = tetromino.color;
    }

    // T-Spin判定（落下前に判定）
    final isTSpin = _checkTSpin(tetromino, rotationIndex, startX, startY);

    // 配置したミノだけを落下させる
    _dropGroup(placedBlocks);

    // 落下後の位置でライン消去判定
    _clearLines(isTSpin);

    notifyListeners();
    return true;
  }

  // 指定したブロック群を形を維持したまま落下させる
  void _dropGroup(List<List<int>> group) {
    if (group.isEmpty) return;

    // 落下可能な距離を計算
    int maxDrop = rows;

    for (var block in group) {
      final x = block[0];
      final y = block[1];

      // このブロックが落下できる距離を計算
      int drop = 0;
      for (var newY = y + 1; newY < rows; newY++) {
        // 下のセルが空、またはグループ内のブロックなら落下可能
        final cellBelow = _grid[newY][x];
        if (cellBelow == null || group.any((b) => b[0] == x && b[1] == newY)) {
          drop++;
        } else {
          break;
        }
      }
      maxDrop = maxDrop < drop ? maxDrop : drop;
    }

    if (maxDrop == 0) return;

    // 色を保存（文字列キーを使用）
    final colors = <String, Color>{};
    for (var block in group) {
      final x = block[0];
      final y = block[1];
      colors['$x,$y'] = _grid[y][x]!;
      _grid[y][x] = null;
    }

    // 新しい位置に配置
    for (var block in group) {
      final x = block[0];
      final y = block[1];
      _grid[y + maxDrop][x] = colors['$x,$y']!;
    }
  }

  // RENボーナスを計算
  int _getRenBonus(int ren) {
    if (ren <= 1) return 0;
    if (ren <= 3) return 1;
    if (ren <= 5) return 2;
    if (ren <= 7) return 3;
    if (ren <= 12) return 4;
    return 5;
  }

  void _clearLines(bool isTSpin) {
    int lineCount = 0;

    List<List<Color?>> newGrid = [];

    // 保持する行だけ抽出（コピーを作成）
    for (var y = 0; y < rows; y++) {
      bool isFull = true;
      for (var x = 0; x < cols; x++) {
        if (_grid[y][x] == null) {
          isFull = false;
          break;
        }
      }

      if (!isFull) {
        // 行のコピーを追加（参照ではなく新しいリスト）
        newGrid.add(List<Color?>.from(_grid[y]));
      } else {
        lineCount++;
      }
    }

    // 消えた行の分だけ上に空行を追加
    while (newGrid.length < rows) {
      newGrid.insert(0, List<Color?>.filled(cols, null));
    }

    // グリッド更新
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        _grid[y][x] = newGrid[y][x];
      }
    }

    // Renモード時は壁を再生成
    if (_mode == GameMode.ren && lineCount > 0) {
      _fillWalls();
    }

    // スコア計算
    if (lineCount > 0) {
      _linesCleared += lineCount;
      _ren++;

      // Renモード用：最大REN更新
      if (_mode == GameMode.ren && _ren > _maxRen) {
        _maxRen = _ren;
      }

      int points = 0;
      List<String> actions = [];

      // パーフェクトクリア判定（Renモードでは壁があるので常にfalse）
      bool isPerfectClear = false;
      if (_mode == GameMode.puzzle) {
        isPerfectClear = true;
        for (var y = 0; y < rows; y++) {
          for (var x = 0; x < cols; x++) {
            if (_grid[y][x] != null) {
              isPerfectClear = false;
              break;
            }
          }
          if (!isPerfectClear) break;
        }
      }

      if (isPerfectClear) {
        points = 10;
        actions.add('Perfect Clear');
      } else if (isTSpin) {
        // T-Spinスコア
        switch (lineCount) {
          case 1:
            points = 2;
            actions.add('T-Spin Single');
            break;
          case 2:
            points = 4;
            actions.add('T-Spin Double');
            break;
          case 3:
            points = 6;
            actions.add('T-Spin Triple');
            break;
        }
      } else {
        // 通常消し
        switch (lineCount) {
          case 1:
            points = 0; // Singleは0点
            actions.add('Single');
            break;
          case 2:
            points = 1;
            actions.add('Double');
            break;
          case 3:
            points = 2;
            actions.add('Triple');
            break;
          case 4:
            points = 4;
            actions.add('Tetris');
            break;
        }
      }

      // Back-to-Back判定（TetrisまたはT-Spin）
      bool isDifficult = (lineCount == 4) || isTSpin;
      if (isDifficult && _lastWasDifficult && !isPerfectClear) {
        points += 1;
        actions.add('B2B');
      }
      // ライン消去があった場合のみB2B状態を更新
      // （Single/Double/Tripleで途切れる、Tetris/T-Spinで継続）
      _lastWasDifficult = isDifficult;

      // RENボーナス
      int renBonus = _getRenBonus(_ren);
      if (renBonus > 0) {
        points += renBonus;
        actions.add('${_ren}REN');
      }

      _score += points;
      _lastAction = actions.join(' ');

      // 40ライン達成でクリア（Puzzleモードのみ）
      if (_mode == GameMode.puzzle && _linesCleared >= targetLines) {
        _isCleared = true;
      }
    } else {
      // ライン消去なしでRENリセット
      _ren = 0;
      _lastAction = '';

      // Renモード時はコンボ切れでゲームオーバー
      if (_mode == GameMode.ren) {
        _isGameOver = true;
      }
    }
  }

  void reset() {
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        _grid[y][x] = null;
      }
    }
    _score = 0;
    _linesCleared = 0;
    _ren = 0;
    _lastWasDifficult = false;
    _isGameOver = false;
    _isCleared = false;
    _lastAction = '';
    _mode = GameMode.puzzle;
    _maxRen = 0;
    notifyListeners();
  }

  // Renモード用：6つの初期パターン
  // 各パターンは [row, col] のリスト（3セル分）
  // 列3-6がウェル（中央4列）、列0-2と7-9は壁
  static const List<List<List<int>>> _renPatterns = [
    // パターン1: ■■■□
    [[19, 3], [19, 4], [19, 5]],
    // パターン2: ■■□□ / ■□□□ (L字左)
    [[19, 3], [19, 4], [18, 3]],
    // パターン3: ■■□□ / ■□□□ (逆L字左)
    [[18, 3], [18, 4], [19, 3]],
    // パターン4: □□■■ / □□□■ (逆L字右)
    [[18, 5], [18, 6], [19, 6]],
    // パターン5: □□■■ / □□□■ (L字右)
    [[19, 5], [19, 6], [18, 6]],
    // パターン6: □■■■
    [[19, 4], [19, 5], [19, 6]],
  ];

  // Renモード初期化
  void initRenMode(int patternIndex) {
    // グリッドをクリア
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        _grid[y][x] = null;
      }
    }

    _mode = GameMode.ren;
    _score = 0;
    _linesCleared = 0;
    _ren = 0;
    _maxRen = 0;
    _lastWasDifficult = false;
    _isGameOver = false;
    _isCleared = false;
    _lastAction = '';

    // 壁を配置（左3列と右3列）
    _fillWalls();

    // 初期パターンを配置
    final pattern = _renPatterns[patternIndex % _renPatterns.length];
    for (var cell in pattern) {
      _grid[cell[0]][cell[1]] = _wallColor;
    }

    notifyListeners();
  }

  // 壁を埋める（左3列と右3列）
  void _fillWalls() {
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < 3; x++) {
        _grid[y][x] = _wallColor;
      }
      for (var x = 7; x < cols; x++) {
        _grid[y][x] = _wallColor;
      }
    }
  }

  // ブラインドモード用: 壁セルかどうか判定（RENモードの壁と初期パターン）
  bool isWallCell(int x, int y) {
    if (x < 0 || x >= cols || y < 0 || y >= rows) return false;
    return _mode == GameMode.ren && _grid[y][x] == _wallColor;
  }

  // スナップショット用: グリッドのコピーを取得
  List<List<Color?>> getGridCopy() {
    return List.generate(rows, (y) => List.from(_grid[y]));
  }

  // スナップショット用: 状態を復元
  void restoreState(List<List<Color?>> grid, int score, int linesCleared, int ren, bool lastWasDifficult, {GameMode? mode, int? maxRen}) {
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        _grid[y][x] = grid[y][x];
      }
    }
    _score = score;
    _linesCleared = linesCleared;
    _ren = ren;
    _lastWasDifficult = lastWasDifficult;
    if (mode != null) _mode = mode;
    if (maxRen != null) _maxRen = maxRen;
    _isGameOver = false;
    _isCleared = false;
    _lastAction = '';
    notifyListeners();
  }
}
