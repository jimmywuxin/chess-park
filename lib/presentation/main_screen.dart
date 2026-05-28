import 'package:flutter/material.dart';
import '../domain/piece.dart';
import 'game_state.dart';
import 'chess_board_widget.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameState(),
      child: const _MainScreenContent(),
    );
  }
}

class _MainScreenContent extends StatelessWidget {
  const _MainScreenContent();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();

    return Scaffold(
      backgroundColor: const Color(0xFF2D1B00),
      appBar: AppBar(
        title: const Text('象棋乐园', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
      ),
      body: Column(
        children: [
          // 消息栏
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            decoration: BoxDecoration(
              color: state.phase == GamePhase.aiThinking
                  ? Colors.orange.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.phase == GamePhase.aiThinking)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                  ),
                if (state.phase == GamePhase.aiThinking) const SizedBox(width: 8),
                Text(
                  state.message,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: state.phase == GamePhase.gameOver
                        ? Colors.amber
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // 比分栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildScoreChip('胜', state.winCount, Colors.green),
                const SizedBox(width: 24),
                _buildScoreChip('负', state.loseCount, Colors.red),
              ],
            ),
          ),

          // 棋盘 — Expanded 让它填满剩余空间，LayoutBuilder 负责自适应
          Expanded(
            child: Center(
              child: ChessBoardWidget(
                board: state.board,
                selectedPiece: state.selectedPiece,
                legalMoves: state.legalMoves,
                playerIsRed: state.playerColor == PieceColor.red,
                lastMove: state.lastMove,
                onTap: (pos) {
                  final piece = state.board.getPieceAt(pos);
                  if (piece != null && piece.color == state.playerColor) {
                    state.selectPiece(pos);
                  } else if (state.selectedPiece != null) {
                    state.moveTo(pos);
                  }
                },
              ),
            ),
          ),

          // 控制按钮栏
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF3D2B00),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(Icons.replay, '悔棋', () => state.undoMove()),
                  _buildControlButton(Icons.refresh, '新局', () => state.newGame()),
                  _buildControlButton(Icons.swap_horiz, '换边', () => state.switchColor()),
                  _buildControlButton(Icons.tune, _difficultyLabel(state.aiDifficulty), () {
                    _showDifficultyDialog(context, state);
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF5D3B00),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  String _difficultyLabel(int level) {
    return level == 1 ? '简单' : (level == 2 ? '中等' : '困难');
  }

  void _showDifficultyDialog(BuildContext context, GameState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择难度'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDifficultyOption(ctx, state, 1, '简单', '适合初学者'),
            _buildDifficultyOption(ctx, state, 2, '中等', '有一定挑战'),
            _buildDifficultyOption(ctx, state, 3, '困难', '需要认真思考'),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(BuildContext ctx, GameState state, int level, String name, String desc) {
    final isSelected = state.aiDifficulty == level;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? Colors.orange : Colors.grey,
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(desc),
      onTap: () {
        state.setDifficulty(level);
        Navigator.pop(ctx);
      },
    );
  }
}
