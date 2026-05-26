
import '../domain/board.dart';
import '../domain/piece.dart';
import '../domain/rules.dart';

class Move {
  final Position from;
  final Position to;
  const Move(this.from, this.to);
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

  // 位置加分表（针对红方，黑方翻转）
  static const Map<PieceType, List<int>> _positionBonus = {
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
        final idx = piece.color == PieceColor.red ? pos.row * 9 + pos.col : (9 - pos.row) * 9 + pos.col;
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

  Move? findBestMove(ChessBoard board, PieceColor aiColor) {
    int bestScore = -999999;
    Move? bestMove;
    final allMoves = <Move>[];

    for (final entry in board.pieces.entries) {
      if (entry.value.color != aiColor) continue;
      for (final to in getLegalMoves(entry.key, board)) {
        allMoves.add(Move(entry.key, to));
      }
    }

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

    final moves = <Move>[];
    for (final entry in board.pieces.entries) {
      if (entry.value.color != currentColor) continue;
      for (final to in getLegalMoves(entry.key, board)) {
        moves.add(Move(entry.key, to));
      }
    }

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
