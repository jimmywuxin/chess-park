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
              child: _PieceStack(
                board: board,
                selectedPiece: selectedPiece,
                legalMoves: legalMoves,
                lastMove: lastMove,
                cellSize: cellSize,
                pieceSize: pieceSize,
                posToPixel: _posToPixel,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PieceStack extends StatefulWidget {
  final ChessBoard board;
  final Position? selectedPiece;
  final List<Position> legalMoves;
  final MoveRecord? lastMove;
  final double cellSize;
  final double pieceSize;
  final Offset Function(Position, double) posToPixel;

  const _PieceStack({
    required this.board,
    required this.selectedPiece,
    required this.legalMoves,
    required this.lastMove,
    required this.cellSize,
    required this.pieceSize,
    required this.posToPixel,
  });

  @override
  State<_PieceStack> createState() => _PieceStackState();
}

class _PieceStackState extends State<_PieceStack>
    with TickerProviderStateMixin {
  // 两个独立的 controller，避免动态创建销毁
  late final AnimationController _playerAnimCtrl;
  late final AnimationController _aiAnimCtrl;
  Animation<Offset>? _animPosition;
  Position? _animatingTo;

  @override
  void initState() {
    super.initState();
    _playerAnimCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..addStatusListener(_onAnimComplete);
    _aiAnimCtrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..addStatusListener(_onAnimComplete);
  }

  void _onAnimComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _animatingTo = null;
            _animPosition = null;
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(_PieceStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lastMove != null &&
        (oldWidget.lastMove == null ||
         oldWidget.lastMove!.from != widget.lastMove!.from ||
         oldWidget.lastMove!.to != widget.lastMove!.to)) {
      final from = widget.lastMove!.from;
      final to = widget.lastMove!.to;
      final isAi = widget.lastMove!.isAiMove;
      final ctrl = isAi ? _aiAnimCtrl : _playerAnimCtrl;

      // 停止另一个 controller
      (isAi ? _playerAnimCtrl : _aiAnimCtrl).stop();

      _animatingTo = to;
      _animPosition = Tween<Offset>(
        begin: widget.posToPixel(from, widget.cellSize),
        end: widget.posToPixel(to, widget.cellSize),
      ).animate(CurvedAnimation(
        parent: ctrl,
        curve: Curves.easeOutCubic,
      ));
      ctrl.reset();
      ctrl.forward();
    }
  }

  @override
  void dispose() {
    _playerAnimCtrl.dispose();
    _aiAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    final cellSize = widget.cellSize;
    final pieceSize = widget.pieceSize;

    // 合法走法指示
    for (final pos in widget.legalMoves) {
      final pixel = widget.posToPixel(pos, cellSize);
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
    for (final entry in widget.board.pieces.entries) {
      final pos = entry.key;
      final piece = entry.value;
      final isSelected = widget.selectedPiece == pos;
      final pixel = widget.posToPixel(pos, cellSize);

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

      if (_animatingTo == pos && _animPosition != null) {
        widgets.add(AnimatedBuilder(
          animation: _animPosition!,
          builder: (context, child) {
            return Positioned(
              left: _animPosition!.value.dx - pieceSize / 2,
              top: _animPosition!.value.dy - pieceSize / 2,
              child: child!,
            );
          },
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

    return Stack(children: widgets);
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

    // 楚河汉界
    final riverY = (pt(0, 4).dy + pt(0, 5).dy) / 2;
    final riverStyle = TextStyle(
      color: Colors.brown,
      fontSize: cellSize * 0.35,
      fontWeight: FontWeight.bold,
      letterSpacing: cellSize * 0.08,
    );
    final chuTp = TextPainter(
      text: TextSpan(text: '楚 河', style: riverStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final chuX = pt(2, 0).dx - chuTp.width / 2;
    chuTp.paint(canvas, Offset(chuX, riverY - chuTp.height / 2));
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
