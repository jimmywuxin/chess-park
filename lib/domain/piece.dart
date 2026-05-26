enum PieceType {
  king,    // 将/帅
  advisor, // 仕/士
  elephant,// 相/象
  rook,    // 车
  knight,  // 马
  cannon,  // 炮
  pawn,    // 兵/卒
}

enum PieceColor {
  red,  // 红方
  black,// 黑方
}

class Piece {
  final PieceType type;
  final PieceColor color;

  const Piece(this.type, this.color);

  String get displayName {
    const redNames = {PieceType.king: '帅', PieceType.advisor: '仕', PieceType.elephant: '相', PieceType.rook: '车', PieceType.knight: '马', PieceType.cannon: '炮', PieceType.pawn: '兵'};
    const blackNames = {PieceType.king: '将', PieceType.advisor: '士', PieceType.elephant: '象', PieceType.rook: '車', PieceType.knight: '馬', PieceType.cannon: '砲', PieceType.pawn: '卒'};
    return (color == PieceColor.red ? redNames : blackNames)[type] ?? '';
  }

  @override
  bool operator ==(Object other) => other is Piece && other.type == type && other.color == color;
  @override
  int get hashCode => type.hashCode ^ color.hashCode;
}
