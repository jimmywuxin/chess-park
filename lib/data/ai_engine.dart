import '../domain/board.dart';
import '../domain/piece.dart';
import '../domain/rules.dart';

class Move {
  final Position from;
  final Position to;
  int score;
  Move(this.from, this.to, {this.score = 0});
}

// ============ 置换表 ============
enum TTFlag { exact, lowerBound, upperBound }

class TTEntry {
  final int depth;
  final int score;
  final TTFlag flag;
  final Move? bestMove;
  const TTEntry(this.depth, this.score, this.flag, this.bestMove);
}

class AIEngine {
  final int maxDepth;
  final int timeLimitMs;

  // 置换表
  final Map<int, TTEntry> _tt = {};

  // 杀手走法：每层存 2 个
  static const int _maxPlies = 64;
  final List<List<Move?>> _killerMoves = List.generate(
    _maxPlies, (_) => [null, null],
  );

  // 历史启发式表
  final Map<String, int> _historyTable = {};

  int _nodeCount = 0;
  late Stopwatch _stopwatch;
  bool _timeUp = false;

  AIEngine({this.maxDepth = 6, this.timeLimitMs = 5000});

  // ============ 位置价值表 ============
  static const List<List<int>> _rookRed = [
    [194, 206, 204, 212, 200, 212, 204, 206, 194],
    [200, 208, 206, 212, 200, 212, 206, 208, 200],
    [198, 208, 204, 212, 212, 212, 204, 208, 198],
    [204, 209, 204, 212, 214, 212, 204, 209, 204],
    [208, 212, 212, 214, 215, 214, 212, 212, 208],
    [208, 211, 211, 214, 215, 214, 211, 211, 208],
    [206, 213, 213, 216, 216, 216, 213, 213, 206],
    [206, 208, 207, 214, 216, 214, 207, 208, 206],
    [206, 212, 209, 216, 233, 216, 209, 212, 206],
    [206, 208, 207, 213, 214, 213, 207, 208, 206],
  ];
  static const List<List<int>> _knightRed = [
    [88, 85, 90, 88, 90, 88, 90, 85, 88],
    [85, 90, 92, 93, 78, 93, 92, 90, 85],
    [93, 92, 94, 95, 92, 95, 94, 92, 93],
    [92, 94, 98, 95, 98, 95, 98, 94, 92],
    [90, 98, 101, 102, 103, 102, 101, 98, 90],
    [90, 100, 99, 103, 104, 103, 99, 100, 90],
    [93, 108, 100, 107, 100, 107, 100, 108, 93],
    [92, 98, 99, 103, 99, 103, 99, 98, 92],
    [90, 96, 103, 97, 94, 97, 103, 96, 90],
    [90, 90, 90, 96, 90, 96, 90, 90, 90],
  ];
  static const List<List<int>> _elephantRed = [
    [0, 0, 20, 0, 0, 0, 20, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [18, 0, 0, 0, 23, 0, 0, 0, 18],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 20, 0, 0, 0, 20, 0, 0],
    [0, 0, 20, 0, 0, 0, 20, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 23, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 20, 0, 0, 0, 20, 0, 0],
  ];
  static const List<List<int>> _advisorRed = [
    [0, 0, 0, 20, 0, 20, 0, 0, 0],
    [0, 0, 0, 0, 23, 0, 0, 0, 0],
    [0, 0, 0, 20, 0, 20, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 20, 0, 20, 0, 0, 0],
    [0, 0, 0, 0, 23, 0, 0, 0, 0],
    [0, 0, 0, 20, 0, 20, 0, 0, 0],
  ];
  static const List<List<int>> _kingRed = [
    [0, 0, 0, 8888, 8888, 8888, 0, 0, 0],
    [0, 0, 0, 8888, 8888, 8888, 0, 0, 0],
    [0, 0, 0, 8888, 8888, 8888, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 8888, 8888, 8888, 0, 0, 0],
    [0, 0, 0, 8888, 8888, 8888, 0, 0, 0],
    [0, 0, 0, 8888, 8888, 8888, 0, 0, 0],
  ];
  static const List<List<int>> _cannonRed = [
    [96, 96, 97, 99, 99, 99, 97, 96, 96],
    [96, 97, 98, 98, 98, 98, 98, 97, 96],
    [97, 96, 100, 99, 101, 99, 100, 96, 97],
    [96, 96, 96, 96, 96, 96, 96, 96, 96],
    [95, 96, 99, 96, 100, 96, 99, 96, 95],
    [96, 96, 96, 96, 100, 96, 96, 96, 96],
    [96, 99, 99, 98, 100, 98, 99, 99, 96],
    [97, 97, 96, 91, 92, 91, 96, 97, 97],
    [98, 98, 96, 92, 89, 92, 96, 98, 98],
    [100, 100, 96, 91, 90, 91, 96, 100, 100],
  ];
  static const List<List<int>> _pawnRed = [
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [7, 0, 7, 0, 15, 0, 7, 0, 7],
    [7, 0, 13, 0, 16, 0, 13, 0, 7],
    [14, 18, 20, 27, 29, 27, 20, 18, 14],
    [19, 23, 27, 29, 30, 29, 27, 23, 19],
    [19, 24, 32, 37, 37, 37, 32, 24, 19],
    [19, 24, 34, 42, 44, 42, 34, 24, 19],
    [9, 9, 9, 11, 13, 11, 9, 9, 9],
  ];

  static final Map<PieceType, List<List<int>>> _redTables = {
    PieceType.rook: _rookRed,
    PieceType.knight: _knightRed,
    PieceType.elephant: _elephantRed,
    PieceType.advisor: _advisorRed,
    PieceType.king: _kingRed,
    PieceType.cannon: _cannonRed,
    PieceType.pawn: _pawnRed,
  };

  int _posValue(PieceType type, PieceColor color, Position pos) {
    final table = _redTables[type];
    if (table == null) return 0;
    return color == PieceColor.red
        ? table[pos.row][pos.col]
        : table[9 - pos.row][pos.col];
  }

  // ============ 棋盘哈希 ============
  int _boardHash(ChessBoard board) {
    int hash = 0;
    for (final entry in board.pieces.entries) {
      final p = entry.key;
      final piece = entry.value;
      final typeIdx = piece.type.index;
      final colorIdx = piece.color == PieceColor.red ? 0 : 1;
      hash ^= (p.row * 9 + p.col + 1) * (typeIdx * 2 + colorIdx + 1) * 31;
    }
    return hash;
  }

  // ============ 评估函数 ============
  int evaluateBoard(ChessBoard board, PieceColor aiColor) {
    int score = 0;
    for (final entry in board.pieces.entries) {
      final v = _posValue(entry.value.type, entry.value.color, entry.key);
      score += entry.value.color == aiColor ? v : -v;
    }
    return score;
  }

  // ============ 走法生成与排序 ============
  List<Move> _getSortedMoves(ChessBoard board, PieceColor color, int ply, Move? ttMove) {
    final moves = <Move>[];
    for (final entry in board.pieces.entries) {
      if (entry.value.color != color) continue;
      for (final to in getLegalMoves(entry.key, board)) {
        moves.add(Move(entry.key, to));
      }
    }

    // 评分排序
    for (final m in moves) {
      int score = 0;

      // TT 走法最高优先
      if (ttMove != null && m.from == ttMove.from && m.to == ttMove.to) {
        score = 1000000;
      }
      // 吃子走法（MVV-LVA）
      else {
        final target = board.getPieceAt(m.to);
        if (target != null) {
          score = _posValue(target.type, target.color, m.to) * 10;
          final attacker = board.getPieceAt(m.from);
          if (attacker != null) {
            score -= _posValue(attacker.type, attacker.color, m.from);
          }
          score += 500000; // 吃子优先
        }
        // 杀手走法
        else if (ply < _maxPlies) {
          final killers = _killerMoves[ply];
          if (killers[0] != null && m.from == killers[0]!.from && m.to == killers[0]!.to) {
            score = 400000;
          } else if (killers[1] != null && m.from == killers[1]!.from && m.to == killers[1]!.to) {
            score = 390000;
          } else {
            // 历史启发式
            final key = '${m.from.row},${m.from.col}-${m.to.row},${m.to.col}';
            score = _historyTable[key] ?? 0;
          }
        }
      }
      m.score = score;
    }

    moves.sort((a, b) => b.score.compareTo(a.score));
    return moves;
  }

  // ============ 静默搜索（Quiescence Search）============
  int _quiescence(ChessBoard board, int alpha, int beta, PieceColor aiColor, PieceColor side) {
    _nodeCount++;
    if (_nodeCount % 1024 == 0 && _stopwatch.elapsedMilliseconds > timeLimitMs) {
      _timeUp = true;
      return 0;
    }

    final standPat = evaluateBoard(board, side);
    if (standPat >= beta) return beta;
    if (standPat > alpha) alpha = standPat;

    // 只搜索吃子走法
    final moves = <Move>[];
    for (final entry in board.pieces.entries) {
      if (entry.value.color != side) continue;
      for (final to in getLegalMoves(entry.key, board)) {
        if (board.getPieceAt(to) != null) {
          final target = board.getPieceAt(to)!;
          final score = _posValue(target.type, target.color, to) * 10;
          moves.add(Move(entry.key, to, score: score));
        }
      }
    }
    moves.sort((a, b) => b.score.compareTo(a.score));

    final opponent = side == PieceColor.red ? PieceColor.black : PieceColor.red;
    for (final move in moves) {
      if (_timeUp) break;
      final newBoard = board.clone();
      final piece = newBoard.getPieceAt(move.from)!;
      newBoard.pieces.remove(move.from);
      newBoard.pieces[move.to] = piece;

      final score = -_quiescence(newBoard, -beta, -alpha, aiColor, opponent);
      if (score >= beta) return beta;
      if (score > alpha) alpha = score;
    }

    return alpha;
  }

  // ============ Alpha-Beta + 置换表 + 空着裁剪 ============
  int _alphaBeta(ChessBoard board, int depth, int alpha, int beta, PieceColor aiColor, PieceColor side, int ply, bool allowNullMove) {
    _nodeCount++;
    if (_nodeCount % 1024 == 0 && _stopwatch.elapsedMilliseconds > timeLimitMs) {
      _timeUp = true;
      return 0;
    }

    final isRoot = (side == aiColor);
    final opponent = side == PieceColor.red ? PieceColor.black : PieceColor.red;

    // 置换表查询
    final hash = _boardHash(board);
    final ttEntry = _tt[hash];
    Move? ttMove;
    if (ttEntry != null && ttEntry.depth >= depth) {
      ttMove = ttEntry.bestMove;
      if (ttEntry.flag == TTFlag.exact) return ttEntry.score;
      if (ttEntry.flag == TTFlag.lowerBound && ttEntry.score > alpha) alpha = ttEntry.score;
      if (ttEntry.flag == TTFlag.upperBound && ttEntry.score < beta) beta = ttEntry.score;
      if (alpha >= beta) return ttEntry.score;
    } else if (ttEntry != null) {
      ttMove = ttEntry.bestMove;
    }

    // 叶子节点：静默搜索
    if (depth <= 0) {
      return _quiescence(board, alpha, beta, aiColor, side);
    }

    // 空着裁剪（Null Move Pruning）
    // 条件：不是根节点、不在将军中、允许空着
    if (allowNullMove && depth >= 3 && !isRoot) {
      if (!isKingInCheck(board, side)) {
        final R = depth >= 6 ? 3 : 2; // 动态空着裁剪深度
        final score = -_alphaBeta(board, depth - 1 - R, -beta, -beta + 1, aiColor, opponent, ply + 1, false);
        if (_timeUp) return 0;
        if (score >= beta) return beta;
      }
    }

    final moves = _getSortedMoves(board, side, ply, ttMove);

    if (moves.isEmpty) {
      if (isKingInCheck(board, side)) return -99999 + ply; // 被将死（越浅越好）
      return 0; // 和棋
    }

    int bestScore = -999999;
    Move? bestMove;
    TTFlag ttFlag = TTFlag.upperBound;

    for (int i = 0; i < moves.length; i++) {
      if (_timeUp) break;
      final move = moves[i];
      final newBoard = board.clone();
      final piece = newBoard.getPieceAt(move.from)!;
      newBoard.pieces.remove(move.from);
      newBoard.pieces[move.to] = piece;

      int score;

      // Late Move Reduction（LMR）：靠后的非吃子走法减少搜索深度
      if (i >= 4 && depth >= 3 && board.getPieceAt(move.to) == null && !isKingInCheck(newBoard, side)) {
        score = -_alphaBeta(newBoard, depth - 2, -alpha - 1, -alpha, aiColor, opponent, ply + 1, true);
        if (score > alpha) {
          score = -_alphaBeta(newBoard, depth - 1, -beta, -alpha, aiColor, opponent, ply + 1, true);
        }
      } else {
        score = -_alphaBeta(newBoard, depth - 1, -beta, -alpha, aiColor, opponent, ply + 1, true);
      }

      if (_timeUp) break;

      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }

      if (score > alpha) {
        alpha = score;
        ttFlag = TTFlag.exact;
      }

      if (alpha >= beta) {
        ttFlag = TTFlag.lowerBound;
        bestMove = move;

        // 更新杀手走法
        if (board.getPieceAt(move.to) == null && ply < _maxPlies) {
          if (_killerMoves[ply][0] == null || _killerMoves[ply][0]!.from != move.from || _killerMoves[ply][0]!.to != move.to) {
            _killerMoves[ply][1] = _killerMoves[ply][0];
            _killerMoves[ply][0] = move;
          }
        }

        // 更新历史启发式
        if (board.getPieceAt(move.to) == null) {
          final key = '${move.from.row},${move.from.col}-${move.to.row},${move.to.col}';
          _historyTable[key] = (_historyTable[key] ?? 0) + depth * depth;
        }

        break;
      }
    }

    // 写入置换表
    if (!_timeUp && bestMove != null) {
      _tt[hash] = TTEntry(depth, bestScore, ttFlag, bestMove);
    }

    return bestScore;
  }

  // ============ 迭代加深搜索 ============
  Move? findBestMove(ChessBoard board, PieceColor aiColor) {
    _stopwatch = Stopwatch()..start();
    _timeUp = false;
    _nodeCount = 0;

    final allMoves = _getSortedMoves(board, aiColor, 0, null);
    if (allMoves.isEmpty) return null;

    Move? bestMove = allMoves[0];
    int bestScore = -999999;

    // 迭代加深：从深度 1 逐步加深到 maxDepth
    for (int depth = 1; depth <= maxDepth; depth++) {
      if (_timeUp) break;

      int currentBestScore = -999999;
      Move? currentBestMove;

      // 用置换表的 bestMove 优化排序
      final hash = _boardHash(board);
      final ttEntry = _tt[hash];
      final sortedMoves = _getSortedMoves(board, aiColor, 0, ttEntry?.bestMove);

      for (final move in sortedMoves) {
        if (_timeUp) break;
        final newBoard = board.clone();
        final piece = newBoard.getPieceAt(move.from)!;
        newBoard.pieces.remove(move.from);
        newBoard.pieces[move.to] = piece;

        final opponent = aiColor == PieceColor.red ? PieceColor.black : PieceColor.red;
        final score = -_alphaBeta(newBoard, depth - 1, -999999, -currentBestScore, aiColor, opponent, 1, true);

        if (!_timeUp && score > currentBestScore) {
          currentBestScore = score;
          currentBestMove = move;
        }
      }

      if (!_timeUp && currentBestMove != null) {
        bestMove = currentBestMove;
        bestScore = currentBestScore;
      }

      // 如果找到必胜走法，立即返回
      if (bestScore > 90000) break;
    }

    _stopwatch.stop();
    return bestMove;
  }
}
