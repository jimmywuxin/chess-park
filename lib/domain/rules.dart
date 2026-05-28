import 'board.dart';
import 'piece.dart';

class MoveResult {
  final bool isValid;
  final bool isCheckmate;
  final bool isCheck;
  final ChessBoard newBoard;

  const MoveResult({
    required this.isValid,
    this.isCheckmate = false,
    this.isCheck = false,
    required this.newBoard,
  });
}

List<Position> _getKingMoves(Position from, ChessBoard board, PieceColor color) {
  final moves = <Position>[];
  for (final d in [const Position(-1, 0), const Position(1, 0), const Position(0, -1), const Position(0, 1)]) {
    final to = Position(from.row + d.row, from.col + d.col);
    if (to.isInsideBoard() && to.isInPalace(color)) {
      final target = board.getPieceAt(to);
      if (target == null || target.color != color) {
        moves.add(to);
      }
    }
  }

  // 检查将对帅：如果在同一列且之间无棋子，可以吃
  final opponentColor = color == PieceColor.red ? PieceColor.black : PieceColor.red;
  for (int row = from.row - 1; row >= 0; row--) {
    final p = board.getPieceAt(Position(row, from.col));
    if (p != null) {
      if (p.type == PieceType.king && p.color == opponentColor) {
        moves.add(Position(row, from.col));
      }
      break;
    }
  }
  for (int row = from.row + 1; row < 10; row++) {
    final p = board.getPieceAt(Position(row, from.col));
    if (p != null) {
      if (p.type == PieceType.king && p.color == opponentColor) {
        moves.add(Position(row, from.col));
      }
      break;
    }
  }
  return moves;
}

List<Position> _getAdvisorMoves(Position from, ChessBoard board, PieceColor color) {
  final moves = <Position>[];
  for (final d in const [Position(-1, -1), Position(-1, 1), Position(1, -1), Position(1, 1)]) {
    final to = Position(from.row + d.row, from.col + d.col);
    if (to.isInsideBoard() && to.isInPalace(color)) {
      final target = board.getPieceAt(to);
      if (target == null || target.color != color) {
        moves.add(to);
      }
    }
  }
  return moves;
}

List<Position> _getElephantMoves(Position from, ChessBoard board, PieceColor color) {
  final moves = <Position>[];
  final eyesCheck = [
    [const Position(-1, -1), const Position(-2, -2)],
    [const Position(-1, 1), const Position(-2, 2)],
    [const Position(1, -1), const Position(2, -2)],
    [const Position(1, 1), const Position(2, 2)],
  ];
  for (final check in eyesCheck) {
    final eye = Position(from.row + check[0].row, from.col + check[0].col);
    final to = Position(from.row + check[1].row, from.col + check[1].col);
    if (board.isEmpty(eye) && to.isInsideBoard()) {
      // 象不过河：红方在下方(row 7-9)，黑方在上方(row 0-4)
      final inOwnSide = color == PieceColor.red ? to.row >= 5 : to.row <= 4;
      if (inOwnSide) {
        final target = board.getPieceAt(to);
        if (target == null || target.color != color) {
          moves.add(to);
        }
      }
    }
  }
  return moves;
}

List<Position> _getRookMoves(Position from, ChessBoard board, PieceColor color) {
  final moves = <Position>[];
  final dirs = [const Position(0, 1), const Position(0, -1), const Position(1, 0), const Position(-1, 0)];
  for (final d in dirs) {
    for (int step = 1;; step++) {
      final to = Position(from.row + d.row * step, from.col + d.col * step);
      if (!to.isInsideBoard()) break;
      final target = board.getPieceAt(to);
      if (target == null) {
        moves.add(to);
      } else {
        if (target.color != color) moves.add(to);
        break;
      }
    }
  }
  return moves;
}

List<Position> _getKnightMoves(Position from, ChessBoard board, PieceColor color) {
  final moves = <Position>[];
  final legs = [
    [const Position(-1, 0), const Position(-2, -1)],
    [const Position(-1, 0), const Position(-2, 1)],
    [const Position(1, 0), const Position(2, -1)],
    [const Position(1, 0), const Position(2, 1)],
    [const Position(0, -1), const Position(-1, -2)],
    [const Position(0, -1), const Position(1, -2)],
    [const Position(0, 1), const Position(-1, 2)],
    [const Position(0, 1), const Position(1, 2)],
  ];
  for (final leg in legs) {
    final legPos = Position(from.row + leg[0].row, from.col + leg[0].col);
    final to = Position(from.row + leg[1].row, from.col + leg[1].col);
    if (board.isEmpty(legPos) && to.isInsideBoard()) {
      final target = board.getPieceAt(to);
      if (target == null || target.color != color) {
        moves.add(to);
      }
    }
  }
  return moves;
}

List<Position> _getCannonMoves(Position from, ChessBoard board, PieceColor color) {
  final moves = <Position>[];
  final dirs = [const Position(0, 1), const Position(0, -1), const Position(1, 0), const Position(-1, 0)];
  for (final d in dirs) {
    // 普通移动（无炮架）
    for (int step = 1;; step++) {
      final to = Position(from.row + d.row * step, from.col + d.col * step);
      if (!to.isInsideBoard()) break;
      final target = board.getPieceAt(to);
      if (target == null) {
        moves.add(to);
      } else {
        // 找到炮架，跳过一子后找目标
        for (int step2 = step + 1;; step2++) {
          final to2 = Position(from.row + d.row * step2, from.col + d.col * step2);
          if (!to2.isInsideBoard()) break;
          final target2 = board.getPieceAt(to2);
          if (target2 != null) {
            if (target2.color != color) moves.add(to2);
            break;
          }
        }
        break;
      }
    }
  }
  return moves;
}

List<Position> _getPawnMoves(Position from, ChessBoard board, PieceColor color) {
  final moves = <Position>[];
  // 红方在下方(row 9)，向上走(row 减小)；黑方在上方(row 0)，向下走(row 增大)
  final forward = color == PieceColor.red ? -1 : 1;
  // 红方过河：row <= 4；黑方过河：row >= 5
  final hasCrossed = color == PieceColor.red ? from.row <= 4 : from.row >= 5;

  // 前进
  final forwardPos = Position(from.row + forward, from.col);
  if (forwardPos.isInsideBoard()) {
    final target = board.getPieceAt(forwardPos);
    if (target == null || target.color != color) moves.add(forwardPos);
  }

  // 过河后可左右移动
  if (hasCrossed) {
    for (final d in [const Position(0, -1), const Position(0, 1)]) {
      final sidePos = Position(from.row + d.row, from.col + d.col);
      if (sidePos.isInsideBoard()) {
        final target = board.getPieceAt(sidePos);
        if (target == null || target.color != color) moves.add(sidePos);
      }
    }
  }
  return moves;
}

List<Position> getLegalMoves(Position from, ChessBoard board) {
  final piece = board.getPieceAt(from);
  if (piece == null) return [];

  List<Position> rawMoves;
  switch (piece.type) {
    case PieceType.king: rawMoves = _getKingMoves(from, board, piece.color);
    case PieceType.advisor: rawMoves = _getAdvisorMoves(from, board, piece.color);
    case PieceType.elephant: rawMoves = _getElephantMoves(from, board, piece.color);
    case PieceType.rook: rawMoves = _getRookMoves(from, board, piece.color);
    case PieceType.knight: rawMoves = _getKnightMoves(from, board, piece.color);
    case PieceType.cannon: rawMoves = _getCannonMoves(from, board, piece.color);
    case PieceType.pawn: rawMoves = _getPawnMoves(from, board, piece.color);
  }

  // 过滤掉让己方被将军的走法
  return rawMoves.where((to) {
    final newBoard = board.clone();
    newBoard.pieces.remove(from);
    newBoard.pieces[to] = piece;
    return !isKingInCheck(newBoard, piece.color);
  }).toList();
}

Position? findKing(ChessBoard board, PieceColor color) {
  for (final entry in board.pieces.entries) {
    if (entry.value.type == PieceType.king && entry.value.color == color) {
      return entry.key;
    }
  }
  return null;
}

bool isKingInCheck(ChessBoard board, PieceColor color) {
  final kingPos = findKing(board, color);
  if (kingPos == null) return true;

  final opponentColor = color == PieceColor.red ? PieceColor.black : PieceColor.red;

  // 检查对方将/帅对面
  for (final entry in board.pieces.entries) {
    if (entry.value.type == PieceType.king && entry.value.color == opponentColor) {
      if (kingPos.col == entry.key.col) {
        bool blocked = false;
        final minRow = kingPos.row < entry.key.row ? kingPos.row : entry.key.row;
        final maxRow = kingPos.row > entry.key.row ? kingPos.row : entry.key.row;
        for (int r = minRow + 1; r < maxRow; r++) {
          if (board.getPieceAt(Position(r, kingPos.col)) != null) {
            blocked = true;
            break;
          }
        }
        if (!blocked) return true;
      }
      break;
    }
  }

  // 检查对方每个棋子能否攻击到帅
  for (final entry in board.pieces.entries) {
    if (entry.value.color != opponentColor) continue;
    final rawMoves = _getRawMovesWithoutKingSafety(entry.key, board);
    if (rawMoves.any((m) => m == kingPos)) return true;
  }
  return false;
}

List<Position> _getRawMovesWithoutKingSafety(Position from, ChessBoard board) {
  final piece = board.getPieceAt(from);
  if (piece == null) return [];
  switch (piece.type) {
    case PieceType.king: return _getKingMoves(from, board, piece.color);
    case PieceType.advisor: return _getAdvisorMoves(from, board, piece.color);
    case PieceType.elephant: return _getElephantMoves(from, board, piece.color);
    case PieceType.rook: return _getRookMoves(from, board, piece.color);
    case PieceType.knight: return _getKnightMoves(from, board, piece.color);
    case PieceType.cannon: return _getCannonMoves(from, board, piece.color);
    case PieceType.pawn: return _getPawnMoves(from, board, piece.color);
  }
}

bool isCheckmate(ChessBoard board, PieceColor color) {
  for (final entry in board.pieces.entries) {
    if (entry.value.color != color) continue;
    if (getLegalMoves(entry.key, board).isNotEmpty) return false;
  }
  return true;
}

MoveResult makeMove(Position from, Position to, ChessBoard board) {
  final piece = board.getPieceAt(from);
  final rawMoves = _getRawMovesWithoutKingSafety(from, board);
  if (!rawMoves.any((m) => m == to)) {
    return MoveResult(isValid: false, newBoard: board);
  }

  final legalMoves = getLegalMoves(from, board);
  if (!legalMoves.any((m) => m == to)) {
    return MoveResult(isValid: false, newBoard: board);
  }

  final newBoard = board.clone();
  newBoard.pieces.remove(from);
  newBoard.pieces[to] = piece!;

  final opponentColor = piece.color == PieceColor.red ? PieceColor.black : PieceColor.red;
  final check = isKingInCheck(newBoard, opponentColor);
  final checkmate = check && isCheckmate(newBoard, opponentColor);

  return MoveResult(
    isValid: true,
    isCheck: check,
    isCheckmate: checkmate,
    newBoard: newBoard,
  );
}
