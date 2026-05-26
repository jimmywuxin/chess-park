import 'package:flutter/material.dart';
import '../domain/piece.dart';
import '../domain/board.dart';

class ChessBoardWidget extends StatelessWidget {
  final ChessBoard board;
  final Position? selectedPiece;
  final List<Position> legalMoves;
  final Function(Position) onTap;
  final bool playerIsRed;

  const ChessBoardWidget({
    super.key,
    required this.board,
    this.selectedPiece,
    this.legalMoves = const [],
    required this.onTap,
    this.playerIsRed = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final boardSize = screenWidth - 32;
    final cellSize = boardSize / 9;

    return GestureDetector(
      onTapUp: (details) {
        final col = (details.localPosition.dx / cellSize).floor();
        final row = (details.localPosition.dy / cellSize).floor();
        if (row >= 0 && row < 10 && col >= 0 && col < 9) {
          onTap(Position(row, col));
        }
      },
      child: Container(
        width: boardSize,
        height: cellSize * 10,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5D6A8),
          border: Border.all(color: Colors.brown, width: 2),
        ),
        child: CustomPaint(
          painter: _BoardPainter(cellSize: cellSize),
          child: Stack(
            children: _buildPieces(cellSize, boardSize),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPieces(double cellSize, double boardSize) {
    final widgets = <Widget>[];

    // 绘制合法走法指示
    for (final pos in legalMoves) {
      widgets.add(Positioned(
        left: pos.col * cellSize - cellSize / 5,
        top: pos.row * cellSize - cellSize / 5,
        child: Container(
          width: cellSize * 0.4,
          height: cellSize * 0.4,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
        ),
      ));
    }

    // 绘制棋子
    for (final entry in board.pieces.entries) {
      final pos = entry.key;
      final piece = entry.value;
      final isSelected = selectedPiece == pos;

      widgets.add(Positioned(
        left: pos.col * cellSize - cellSize / 2,
        top: pos.row * cellSize - cellSize / 2,
        child: Container(
          width: cellSize * 0.85,
          height: cellSize * 0.85,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFEB3B) : const Color(0xFFFFF8E1),
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.orange : Colors.brown,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                offset: const Offset(2, 2),
                blurRadius: 3,
              ),
            ],
          ),
          child: Center(
            child: Text(
              piece.displayName,
              style: TextStyle(
                fontSize: cellSize * 0.45,
                fontWeight: FontWeight.bold,
                color: piece.color == PieceColor.red
                    ? const Color(0xFFD32F2F)
                    : Colors.black,
              ),
            ),
          ),
        ),
      ));
    }

    return widgets;
  }
}

class _BoardPainter extends CustomPainter {
  final double cellSize;

  _BoardPainter({required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown
      ..strokeWidth = 1.5;

    // 画网格线
    for (int i = 0; i <= 8; i++) {
      // 竖线
      final x = i * cellSize;
      // 上半部分竖线
      canvas.drawLine(Offset(x, 0), Offset(x, cellSize * 4), paint);
      // 下半部分竖线
      canvas.drawLine(Offset(x, cellSize * 5), Offset(x, cellSize * 9), paint);
    }

    // 左右两边完整竖线
    canvas.drawLine(Offset(0, 0), Offset(0, cellSize * 9), paint);
    canvas.drawLine(Offset(cellSize * 8, 0), Offset(cellSize * 8, cellSize * 9), paint);

    // 横线
    for (int i = 0; i <= 9; i++) {
      final y = i * cellSize;
      canvas.drawLine(Offset(0, y), Offset(cellSize * 8, y), paint);
    }

    // 楚河汉界
    final chuhe = cellSize * 4 + cellSize * 0.4;
    
    final tp = TextPainter(
      text: const TextSpan(
        text: '楚 河　　　汉 界',
        style: TextStyle(color: Colors.brown, fontSize: 14, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout(maxWidth: cellSize * 8);
    tp.paint(canvas, Offset(cellSize * 0.5, chuhe));

    // 九宫格斜线
    canvas.drawLine(
      Offset(cellSize * 3, 0),
      Offset(cellSize * 5, cellSize * 2),
      paint..color = Colors.brown.withValues(alpha: 0.5),
    );
    canvas.drawLine(
      Offset(cellSize * 5, 0),
      Offset(cellSize * 3, cellSize * 2),
      paint,
    );
    canvas.drawLine(
      Offset(cellSize * 3, cellSize * 7),
      Offset(cellSize * 5, cellSize * 9),
      paint,
    );
    canvas.drawLine(
      Offset(cellSize * 5, cellSize * 7),
      Offset(cellSize * 3, cellSize * 9),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
