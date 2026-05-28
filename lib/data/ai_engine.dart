import '../domain/board.dart';
import '../domain/piece.dart';
import '../domain/rules.dart';

class Move {
  final Position from;
  final Position to;
  final int score; // 用于走法排序
  const Move(this.from, this.to, {this.score = 0});
}

class AIEngine {
  final int maxDepth;

  const AIEngine({this.maxDepth = 3});

  // 棋子基础分值
  static const Map<PieceType, int> _pieceValues = {
    PieceType.king: 10000,
    PieceType.advisor: 20,
    PieceType.elephant: 20,
    PieceType.rook: 90,
    PieceType.knight: 40,
    PieceType.cannon: 45,
    PieceType.pawn: 10,
  };

  // 位置加分表（针对红方在下方的视角，黑方翻转使用）
  static const Map<PieceType, List<int>> _positionBonus = {
    PieceType.king: [
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 1, 1, 1, 0, 0, 0,
      0, 0, 0, 2, 2, 2, 0, 0, 0,
      0, 0, 0, 11, 15, 11, 0, 0, 0,
    ],
    PieceType.advisor: [
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 20, 0, 20, 0, 0, 0,
      0, 0, 0, 0, 23, 0, 0, 0, 0,
      0, 0, 0, 20, 0, 20, 0, 0, 0,
    ],
    PieceType.elephant: [
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 20, 0, 0, 0, 20, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      18, 0, 0, 0, 23, 0, 0, 0, 18,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 20, 0, 0, 0, 20, 0, 0,
    ],
    PieceType.knight: [
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, -1, 3, 0, 0, 0, 3, -1, 0,
      -1, 0, 2, 4, 4, 4, 2, 0, -1,
      0, 2, 4, 5, 6, 5, 4, 2, 0,
      0, 4, 4, 5, 6, 5, 4, 4, 0,
      0, 2, 4, 5, 6, 5, 4, 2, 0,
      -1, 0, 2, 4, 4, 4, 2, 0, -1,
      0, -1, 3, 0, 0, 0, 3, -1, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
    ],
    PieceType.rook: [
      0, -2, 0, 0, 0, 0, 0, -2, 0,
      2, 2, 2, 2, 2, 2, 2, 2, 2,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      2, 2, 2, 2, 2, 2, 2, 2, 2,
      0, -2, 0, 0, 0, 0, 0, -2, 0,
    ],
    PieceType.cannon: [
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 1, 0, 0, 0, 0, 0, 1, 0,
      0, 0, 1, 0, 0, 0, 1, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 1, 0, 0, 0, 0, 0, 0,
      0, 1, 0, 0, 0, 0, 0, 1, 0,
      2, 0, 2, 0, -1, 0, 2, 0, 2,
    ],
    PieceType.pawn: [
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, -1, 0, 4, 0, -1, 0, 0,
      3, 4, 4, 5, 8, 5, 4, 4, 3,
      5, 6, 7, 8, 12, 8, 7, 6, 5,
      3, 4, 4, 5, 8, 5, 4, 4, 3,
      0, 0, -1, 0, 4, 0, -1, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0,
    ],
  };

  int evaluateBoard(ChessBoard board, PieceColor aiColor) {
    int score = 0;
    for (final entry in board.pieces.entries) {
      final pos = entry.key;
      final piece = entry.value;
      int pieceValue = _pieceValues[piece.type] ?? 0;

      // 位置加分
      final bonusTable = _positionBonus[piece.type];
      if (bonusTable != null) {
        // 红方在下方(row 7-9)，位置表也是红方视角(row 9 在最后)
        final idx = piece.color == PieceColor.red
            ? pos.row * 9 + pos.col
            : (9 - pos.row) * 9 + pos.col;
        pieceValue += bonusTable[idx];
      }

      if (piece.color == aiColor) {
        score += pieceValue;
      } else {
        score -= pieceValue;
      }
    }
    return score;
  }

  // 评估单步走法的启发式分数，用于走法排序
  int _moveScore(Move move, ChessBoard board, PieceColor aiColor) {
    int score = 0;
    final target = board.getPieceAt(move.to);
    if (target != null) {
      // 吃子优先：被吃棋子价值 - 吃子棋子价值（MVV-LVA）
      score += (_pieceValues[target.type] ?? 0) * 10 -
               (_pieceValues[board.getPieceAt(move.from)?.type] ?? 0);
    }
    // 位置加分变化
    final piece = board.getPieceAt(move.from);
    if (piece != null) {
      final bonusTable = _positionBonus[piece.type];
      if (bonusTable != null) {
        final oldIdx = piece.color == PieceColor.red
            ? move.from.row * 9 + move.from.col
            : (9 - move.from.row) * 9 + move.from.col;
        final newIdx = piece.color == PieceColor.red
            ? move.to.row * 9 + move.to.col
            : (9 - move.to.row) * 9 + move.to.col;
        score += bonusTable[newIdx] - bonusTable[oldIdx];
      }
    }
    return score;
  }

  // 生成并排序走法
  List<Move> _getSortedMoves(ChessBoard board, PieceColor color, PieceColor aiColor) {
    final moves = <Move>[];
    for (final entry in board.pieces.entries) {
      if (entry.value.color != color) continue;
      for (final to in getLegalMoves(entry.key, board)) {
        final score = _moveScore(Move(entry.key, to), board, aiColor);
        moves.add(Move(entry.key, to, score: score));
      }
    }
    // 按分数降序排列（高分优先）
    moves.sort((a, b) => b.score.compareTo(a.score));
    return moves;
  }

  Move? findBestMove(ChessBoard board, PieceColor aiColor) {
    int bestScore = -999999;
    Move? bestMove;

    final allMoves = _getSortedMoves(board, aiColor, aiColor);
    if (allMoves.isEmpty) return null;

    for (final move in allMoves) {
      final newBoard = board.clone();
      final piece = newBoard.getPieceAt(move.from)!;
      newBoard.pieces.remove(move.from);
      newBoard.pieces[move.to] = piece;

      final score = -_minimax(newBoard, maxDepth - 1, -999999, 999999, false, aiColor);
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    return bestMove;
  }

  int _minimax(ChessBoard board, int depth, int alpha, int beta, bool isAI, PieceColor aiColor) {
    if (depth == 0) {
      return evaluateBoard(board, aiColor);
    }

    final currentColor = isAI ? aiColor : (aiColor == PieceColor.red ? PieceColor.black : PieceColor.red);

    final moves = _getSortedMoves(board, currentColor, aiColor);

    if (moves.isEmpty) {
      if (isKingInCheck(board, currentColor)) {
        return isAI ? -99999 : 99999;
      }
      return evaluateBoard(board, aiColor);
    }

    if (isAI) {
      int maxScore = -999999;
      for (final move in moves) {
        final newBoard = board.clone();
        final piece = newBoard.getPieceAt(move.from)!;
        newBoard.pieces.remove(move.from);
        newBoard.pieces[move.to] = piece;
        final score = _minimax(newBoard, depth - 1, alpha, beta, false, aiColor);
        if (score > maxScore) maxScore = score;
        if (score > alpha) alpha = score;
        if (alpha >= beta) break;
      }
      return maxScore;
    } else {
      int minScore = 999999;
      for (final move in moves) {
        final newBoard = board.clone();
        final piece = newBoard.getPieceAt(move.from)!;
        newBoard.pieces.remove(move.from);
        newBoard.pieces[move.to] = piece;
        final score = _minimax(newBoard, depth - 1, alpha, beta, true, aiColor);
        if (score < minScore) minScore = score;
        if (score < beta) beta = score;
        if (alpha >= beta) break;
      }
      return minScore;
    }
  }
}
