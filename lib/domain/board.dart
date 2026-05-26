import 'piece.dart';

class Position {
  final int row; // 0-9
  final int col; // 0-8
  const Position(this.row, this.col);

  bool isInsideBoard() => row >= 0 && row < 10 && col >= 0 && col < 9;

  bool isInPalace(PieceColor color) {
    if (color == PieceColor.red) {
      return col >= 3 && col <= 5 && row >= 0 && row <= 2;
    } else {
      return col >= 3 && col <= 5 && row >= 7 && row <= 9;
    }
  }

  @override
  bool operator ==(Object other) => other is Position && other.row == row && other.col == col;
  @override
  int get hashCode => row.hashCode ^ col.hashCode;
  @override
  String toString() => '($row, $col)';
}

class ChessBoard {
  final Map<Position, Piece> pieces = {};

  ChessBoard() {
    _initializeBoard();
  }

  void _initializeBoard() {
    // 红方（下方，row 0-4）
    pieces[const Position(0, 0)] = const Piece(PieceType.rook, PieceColor.red);
    pieces[const Position(0, 1)] = const Piece(PieceType.knight, PieceColor.red);
    pieces[const Position(0, 2)] = const Piece(PieceType.elephant, PieceColor.red);
    pieces[const Position(0, 3)] = const Piece(PieceType.advisor, PieceColor.red);
    pieces[const Position(0, 4)] = const Piece(PieceType.king, PieceColor.red);
    pieces[const Position(0, 5)] = const Piece(PieceType.advisor, PieceColor.red);
    pieces[const Position(0, 6)] = const Piece(PieceType.elephant, PieceColor.red);
    pieces[const Position(0, 7)] = const Piece(PieceType.knight, PieceColor.red);
    pieces[const Position(0, 8)] = const Piece(PieceType.rook, PieceColor.red);
    pieces[const Position(2, 1)] = const Piece(PieceType.cannon, PieceColor.red);
    pieces[const Position(2, 7)] = const Piece(PieceType.cannon, PieceColor.red);
    pieces[const Position(3, 0)] = const Piece(PieceType.pawn, PieceColor.red);
    pieces[const Position(3, 2)] = const Piece(PieceType.pawn, PieceColor.red);
    pieces[const Position(3, 4)] = const Piece(PieceType.pawn, PieceColor.red);
    pieces[const Position(3, 6)] = const Piece(PieceType.pawn, PieceColor.red);
    pieces[const Position(3, 8)] = const Piece(PieceType.pawn, PieceColor.red);

    // 黑方（上方，row 5-9）
    pieces[const Position(9, 0)] = const Piece(PieceType.rook, PieceColor.black);
    pieces[const Position(9, 1)] = const Piece(PieceType.knight, PieceColor.black);
    pieces[const Position(9, 2)] = const Piece(PieceType.elephant, PieceColor.black);
    pieces[const Position(9, 3)] = const Piece(PieceType.advisor, PieceColor.black);
    pieces[const Position(9, 4)] = const Piece(PieceType.king, PieceColor.black);
    pieces[const Position(9, 5)] = const Piece(PieceType.advisor, PieceColor.black);
    pieces[const Position(9, 6)] = const Piece(PieceType.elephant, PieceColor.black);
    pieces[const Position(9, 7)] = const Piece(PieceType.knight, PieceColor.black);
    pieces[const Position(9, 8)] = const Piece(PieceType.rook, PieceColor.black);
    pieces[const Position(7, 1)] = const Piece(PieceType.cannon, PieceColor.black);
    pieces[const Position(7, 7)] = const Piece(PieceType.cannon, PieceColor.black);
    pieces[const Position(6, 0)] = const Piece(PieceType.pawn, PieceColor.black);
    pieces[const Position(6, 2)] = const Piece(PieceType.pawn, PieceColor.black);
    pieces[const Position(6, 4)] = const Piece(PieceType.pawn, PieceColor.black);
    pieces[const Position(6, 6)] = const Piece(PieceType.pawn, PieceColor.black);
    pieces[const Position(6, 8)] = const Piece(PieceType.pawn, PieceColor.black);
  }

  Piece? getPieceAt(Position pos) => pieces[pos];
  bool isEmpty(Position pos) => !pieces.containsKey(pos);

  ChessBoard clone() {
    final copy = ChessBoard._empty();
    copy.pieces.addAll(pieces.map((k, v) => MapEntry(Position(k.row, k.col), v)));
    return copy;
  }

  ChessBoard._empty();
}
