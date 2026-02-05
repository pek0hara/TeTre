import 'package:flutter/material.dart';
import 'dart:math';
import 'models/tetromino.dart';
import 'models/board_state.dart';
import 'widgets/board_widget.dart';
import 'widgets/rotation_selector.dart';
import 'widgets/next_mino_widget.dart';
import 'widgets/hold_widget.dart';

// ゲーム状態のスナップショット
class GameSnapshot {
  final List<List<Color?>> grid;
  final int score;
  final int linesCleared;
  final int ren;
  final bool lastWasDifficult;
  final Tetromino currentTetromino;
  final Tetromino? holdTetromino;
  final bool canHold;
  final List<Tetromino> nextQueue;
  final List<TetrominoType> bag;
  final GameMode mode;
  final int maxRen;

  GameSnapshot({
    required this.grid,
    required this.score,
    required this.linesCleared,
    required this.ren,
    required this.lastWasDifficult,
    required this.currentTetromino,
    required this.holdTetromino,
    required this.canHold,
    required this.nextQueue,
    required this.bag,
    required this.mode,
    required this.maxRen,
  });
}

void main() {
  runApp(const TetreApp());
}

class TetreApp extends StatelessWidget {
  const TetreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeTre',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
        ),
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late BoardState _boardState;
  late Tetromino _currentTetromino;
  Tetromino? _holdTetromino; // ホールド中のミノ
  bool _canHold = true; // ホールド可能かどうか（1回配置するまで再ホールド不可）
  final List<Tetromino> _nextQueue = []; // 5個のネクスト
  final List<TetrominoType> _bag = []; // 7-bag
  int _rotationIndex = 0;
  final Random _random = Random();
  final List<GameSnapshot> _undoHistory = []; // Undo履歴（無制限）
  bool _blindMode = false; // ブラインドモード

  @override
  void initState() {
    super.initState();
    _boardState = BoardState();
    _boardState.addListener(_onBoardChange);
    _initializeQueue();
  }

  void _initializeQueue() {
    _bag.clear();
    _nextQueue.clear();
    _holdTetromino = null;
    _canHold = true;
    // キューに6個入れる（現在のミノ + 5個のネクスト）
    for (int i = 0; i < 6; i++) {
      _nextQueue.add(_getNextFromBag());
    }
    _spawnTetromino();
  }

  Tetromino _getNextFromBag() {
    if (_bag.isEmpty) {
      // バッグを補充（7種すべてをシャッフル）
      _bag.addAll(TetrominoType.values);
      _bag.shuffle(_random);
    }
    final type = _bag.removeLast();
    return Tetromino.get(type);
  }
  
  void _onBoardChange() {
    setState(() {}); // 盤面更新時に再描画
  }

  @override
  void dispose() {
    _boardState.removeListener(_onBoardChange);
    _boardState.dispose();
    super.dispose();
  }

  void _spawnTetromino() {
    setState(() {
      _currentTetromino = _nextQueue.removeAt(0);
      _nextQueue.add(_getNextFromBag());
      _rotationIndex = 0;
      _canHold = true; // 配置後は再びホールド可能
    });
  }

  void _hold() {
    if (!_canHold) return; // 既にホールド済みの場合は無効

    setState(() {
      if (_holdTetromino == null) {
        // 初回ホールド: 現在のミノをホールドし、ネクストから取得
        _holdTetromino = _currentTetromino;
        _currentTetromino = _nextQueue.removeAt(0);
        _nextQueue.add(_getNextFromBag());
      } else {
        // 2回目以降: ホールド中のミノと交換
        final temp = _currentTetromino;
        _currentTetromino = _holdTetromino!;
        _holdTetromino = temp;
      }
      _rotationIndex = 0;
      _canHold = false; // 配置するまで再ホールド不可
    });
  }

  // スナップショットを保存
  void _saveSnapshot() {
    final snapshot = GameSnapshot(
      grid: _boardState.getGridCopy(),
      score: _boardState.score,
      linesCleared: _boardState.linesCleared,
      ren: _boardState.ren,
      lastWasDifficult: _boardState.lastWasDifficult,
      currentTetromino: _currentTetromino,
      holdTetromino: _holdTetromino,
      canHold: _canHold,
      nextQueue: List.from(_nextQueue),
      bag: List.from(_bag),
      mode: _boardState.mode,
      maxRen: _boardState.maxRen,
    );
    _undoHistory.add(snapshot);
  }

  // Undo実行
  void _undo() {
    if (_undoHistory.isEmpty) return;

    setState(() {
      final snapshot = _undoHistory.removeLast();
      _boardState.restoreState(
        snapshot.grid,
        snapshot.score,
        snapshot.linesCleared,
        snapshot.ren,
        snapshot.lastWasDifficult,
        mode: snapshot.mode,
        maxRen: snapshot.maxRen,
      );
      _currentTetromino = snapshot.currentTetromino;
      _holdTetromino = snapshot.holdTetromino;
      _canHold = snapshot.canHold;
      _nextQueue.clear();
      _nextQueue.addAll(snapshot.nextQueue);
      _bag.clear();
      _bag.addAll(snapshot.bag);
      _rotationIndex = 0;
    });
  }

  bool get _canUndo => _undoHistory.isNotEmpty;

  void _onRotationSelect(int index) {
    setState(() {
      _rotationIndex = index;
    });
  }

  void _onBoardTap(int startX, int startY) {
    if (_boardState.isGameOver) return;

    // 配置前にスナップショットを保存
    _saveSnapshot();

    final success = _boardState.place(_currentTetromino, _rotationIndex, startX, startY);

    if (success) {
      // クリア判定（Puzzleモード）
      if (_boardState.isCleared) {
        _showClearDialog();
      }
      // ゲームオーバー判定（Renモード：コンボ切れ）
      else if (_boardState.isGameOver) {
        _showRenGameOverDialog();
      } else {
        _spawnTetromino();
      }
    } else {
      // 配置失敗時はスナップショットを取り消し
      _undoHistory.removeLast();
    }
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'CLEAR!',
          style: TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          '40 Lines cleared!\nMoves: ${_undoHistory.length}',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void _showRenGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'GAME OVER',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Max REN: ${_boardState.maxRen}',
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Moves: ${_undoHistory.length}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          if (_canUndo)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _undo();
              },
              child: const Text('Undo'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startRenMode();
            },
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showModeSelectionDialog();
            },
            child: const Text('Change Mode'),
          ),
        ],
      ),
    );
  }

  void _showModeSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Select Mode',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _resetGame();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    '40LINE Practice',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _startRenMode();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'REN Practice',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  setDialogState(() {
                    setState(() {
                      _blindMode = !_blindMode;
                    });
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _blindMode ? Icons.visibility_off : Icons.visibility,
                      color: _blindMode ? Colors.purpleAccent : Colors.white60,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Blind Mode',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _blindMode ? Colors.purpleAccent : Colors.white60,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _blindMode ? 'ON' : 'OFF',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _blindMode ? Colors.purpleAccent : Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startRenMode() {
    final patternIndex = _random.nextInt(6);
    _boardState.initRenMode(patternIndex);
    _undoHistory.clear();
    _initializeQueue();
  }

  void _resetGame() {
    _boardState.reset();
    _undoHistory.clear();
    _initializeQueue();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ステータス表示
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // モード別ステータス表示
                  if (_boardState.mode == GameMode.puzzle)
                    // Puzzleモード: LINES と SCORE
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'LINES: ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white60,
                              ),
                            ),
                            Text(
                              '${_boardState.linesCleared}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            Text(
                              ' / ${BoardState.targetLines}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Text(
                              'SCORE: ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white60,
                              ),
                            ),
                            Text(
                              '${_boardState.score}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    // Renモード: REN表示
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orangeAccent),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${_boardState.ren}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orangeAccent,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'REN',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orangeAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MAX: ${_boardState.maxRen}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white60,
                              ),
                            ),
                            Text(
                              'LINES: ${_boardState.linesCleared}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  // アクション表示
                  if (_boardState.lastAction.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _boardState.mode == GameMode.ren
                            ? Colors.orangeAccent.withOpacity(0.3)
                            : Colors.blueAccent.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _boardState.lastAction,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _blindMode ? Icons.visibility_off : Icons.visibility,
                          size: 24,
                          color: _blindMode ? Colors.purpleAccent : null,
                        ),
                        onPressed: () {
                          setState(() {
                            _blindMode = !_blindMode;
                          });
                        },
                        tooltip: 'Blind Mode',
                      ),
                      IconButton(
                        icon: const Icon(Icons.menu, size: 24),
                        onPressed: _showModeSelectionDialog,
                        tooltip: 'Select Mode',
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 24),
                        onPressed: _boardState.mode == GameMode.ren ? _startRenMode : _resetGame,
                        tooltip: 'Reset Game',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 盤面 + ネクスト表示（右側）
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 盤面
                      Flexible(
                        child: BoardWidget(
                          boardState: _boardState,
                          currentTetromino: _currentTetromino,
                          rotationIndex: _rotationIndex,
                          onPlace: _onBoardTap,
                          blindMode: _blindMode,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // ネクスト + ホールド + Undo表示（右側）
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          NextMinoWidget(nextQueue: _nextQueue),
                          const SizedBox(height: 8),
                          HoldWidget(
                            holdTetromino: _holdTetromino,
                            canHold: _canHold,
                            onHold: _hold,
                          ),
                          const SizedBox(height: 8),
                          // Undoボタン
                          GestureDetector(
                            onTap: _canUndo ? _undo : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _canUndo ? Colors.grey : Colors.grey.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                                color: _canUndo ? Colors.black54 : Colors.black26,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.undo,
                                    size: 16,
                                    color: _canUndo ? Colors.white60 : Colors.white30,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'UNDO',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _canUndo ? Colors.white60 : Colors.white30,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${_undoHistory.length})',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _canUndo ? Colors.white38 : Colors.white24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 回転選択（コンパクト）
            RotationSelector(
              currentTetromino: _currentTetromino,
              selectedRotationIndex: _rotationIndex,
              onSelect: _onRotationSelect,
            ),
          ],
        ),
      ),
    );
  }
}