import 'package:flutter/material.dart';
import '../domain/piece.dart';
import '../domain/board.dart';
import 'game_state.dart';

class ChessBoardWidget extends StatelessWidget {
  final ChessBoard board;
  final Position? selectedPiece;
  final List<Position> legalMoves;
  final Function(Position) onTap;
  final bool playerIsRed;
  final MoveRecord? lastMove;

  static const double padding = 24.0;

  const ChessBoardWidget({
    super.key,
    required this.board,
    this.selectedPiece,
    this.legalMoves = const [],
    required this.onTap,
    this.playerIsRed = true,
    this.lastMove,
  });

  Offset _posToPixel(Position pos, double cellSize) {
    return Offset(
      padding + pos.col * cellSize,
      padding + pos.row * cellSize,
    );
  }

  Position? _pixelToPos(Offset offset, double cellSize) {
    final col = ((offset.dx - padding) / cellSize + 0.5).floor();
    final row = ((offset.dy - padding) / cellSize + 0.5).floor();
    if (row >= 0 && row < 10 && col >= 0 && col < 9) {
      return Position(row, col);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSizeByWidth = (constraints.maxWidth - padding * 2) / 8;
        final cellSizeByHeight = (constraints.maxHeight - padding * 2) / 9;
        final cellSize = cellSizeByWidth < cellSizeByHeight
            ? cellSizeByWidth
            : cellSizeByHeight;
        final boardWidth = padding * 2 + cellSize * 8;
        final boardHeight = padding * 2 + cellSize * 9;
        final pieceSize = cellSize * 0.88;

        return GestureDetector(
          onTapUp: (details) {
            final pos = _pixelToPos(details.localPosition, cellSize);
            if (pos != null) onTap(pos);
          },
          child: Container(
            width: boardWidth,
            height: boardHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFF5D6A8),
              border: Border.all(color: Colors.brown, width: 2),
            ),
            child: CustomPaint(
              painter: _BoardPainter(cellSize: cellSize),
              child: Stack(
                children: _buildPieces(cellSize, pieceSize),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildPieces(double cellSize, double pieceSize) {
    final widgets = <Widget>[];

    // 合法走法指示
    for (final pos in legalMoves) {
      final pixel = _posToPixel(pos, cellSize);
      widgets.add(Positioned(
        left: pixel.dx - pieceSize / 2,
        top: pixel.dy - pieceSize / 2,
        child: Container(
          width: pieceSize,
          height: pieceSize,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
        ),
      ));
    }

    // 棋子
    for (final entry in board.pieces.entries) {
      final pos = entry.key;
      final piece = entry.value;
      final isSelected = selectedPiece == pos;
      final pixel = _posToPixel(pos, cellSize);
      final isAnimating = lastMove != null && lastMove!.to == pos;

      final pieceWidget = Container(
        width: pieceSize,
        height: pieceSize,
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
              offset: const Offset(1.5, 1.5),
              blurRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(pieceSize * 0.1),
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(
                piece.displayName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: piece.color == PieceColor.red
                      ? const Color(0xFFD32F2F)
                      : Colors.black,
                ),
              ),
            ),
          ),
        ),
      );

      if (isAnimating) {
        final fromPixel = _posToPixel(lastMove!.from, cellSize);
        widgets.add(_AnimatedPiece(
          key: ValueKey('anim_${pos.row}_${pos.col}_${DateTime.now().millisecondsSinceEpoch}'),
          fromPixel: fromPixel,
          toPixel: pixel,
          pieceSize: pieceSize,
          child: pieceWidget,
        ));
      } else {
        widgets.add(Positioned(
          left: pixel.dx - pieceSize / 2,
          top: pixel.dy - pieceSize / 2,
          child: pieceWidget,
        ));
      }
    }

    return widgets;
  }
}

class _AnimatedPiece extends StatefulWidget {
  final Offset fromPixel;
  final Offset toPixel;
  final double pieceSize;
  final Widget child;

  const _AnimatedPiece({
    super.key,
    required this.fromPixel,
    required this.toPixel,
    required this.pieceSize,
    required this.child,
  });

  @override
  State<_AnimatedPiece> createState() => _AnimatedPieceState();
}

class _AnimatedPieceState extends State<_AnimatedPiece>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _position = Tween<Offset>(
      begin: widget.fromPixel,
      end: widget.toPixel,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _position,
      builder: (context, child) {
        return Positioned(
          left: _position.value.dx - widget.pieceSize / 2,
          top: _position.value.dy - widget.pieceSize / 2,
          child: widget.child,
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  final double cellSize;
  static const double padding = ChessBoardWidget.padding;

  _BoardPainter({required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown
      ..strokeWidth = 1.5;

    Offset pt(int col, int row) => Offset(
      padding + col * cellSize,
      padding + row * cellSize,
    );

    // 竖线
    for (int col = 0; col <= 8; col++) {
      canvas.drawLine(pt(col, 0), pt(col, 4), paint);
      canvas.drawLine(pt(col, 5), pt(col, 9), paint);
    }

    // 左右完整竖线
    canvas.drawLine(pt(0, 0), pt(0, 9), paint);
    canvas.drawLine(pt(8, 0), pt(8, 9), paint);

    // 横线
    for (int row = 0; row <= 9; row++) {
      canvas.drawLine(pt(0, row), pt(8, row), paint);
    }

    // 楚河汉界 — 楚河对齐col2，汉界对齐col5
    final riverY = (pt(0, 4).dy + pt(0, 5).dy) / 2;
    final riverStyle = TextStyle(
      color: Colors.brown,
      fontSize: cellSize * 0.35,
      fontWeight: FontWeight.bold,
      letterSpacing: cellSize * 0.08,
    );
    // 楚河居中对齐 col 2（第二个兵）
    final chuTp = TextPainter(
      text: TextSpan(text: '楚 河', style: riverStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final chuX = pt(2, 0).dx - chuTp.width / 2;
    chuTp.paint(canvas, Offset(chuX, riverY - chuTp.height / 2));
    // 汉界居中对齐 col 4（第四个兵）
    final hanTp = TextPainter(
      text: TextSpan(text: '汉 界', style: riverStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final hanX = pt(6, 0).dx - hanTp.width / 2;
    hanTp.paint(canvas, Offset(hanX, riverY - hanTp.height / 2));

    // 九宫格斜线
    final palacePaint = Paint()
      ..color = Colors.brown.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;
    canvas.drawLine(pt(3, 0), pt(5, 2), palacePaint);
    canvas.drawLine(pt(5, 0), pt(3, 2), palacePaint);
    canvas.drawLine(pt(3, 7), pt(5, 9), palacePaint);
    canvas.drawLine(pt(5, 7), pt(3, 9), palacePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
