import 'package:flutter/foundation.dart';
import '../domain/board.dart';
import '../domain/piece.dart';
import '../domain/rules.dart';
import '../data/ai_engine.dart';

enum GamePhase { playerTurn, aiThinking, gameOver }

class GameState extends ChangeNotifier {
  ChessBoard _board = ChessBoard();
  PieceColor _playerColor = PieceColor.red;
  int _aiDifficulty = 2; // 1=简单, 2=中等, 3=困难
  GamePhase _phase = GamePhase.playerTurn;
  Position? _selectedPiece;
  List<Position> _legalMoves = [];
  String _message = '红方先行';
  int _winCount = 0;
  int _loseCount = 0;
  List<String> _moveHistory = [];

  ChessBoard get board => _board;
  PieceColor get playerColor => _playerColor;
  int get aiDifficulty => _aiDifficulty;
  GamePhase get phase => _phase;
  Position? get selectedPiece => _selectedPiece;
  List<Position> get legalMoves => _legalMoves;
  String get message => _message;
  int get winCount => _winCount;
  int get loseCount => _loseCount;
  List<String> get moveHistory => _moveHistory;

  void selectPiece(Position pos) {
    if (_phase != GamePhase.playerTurn) return;
    final piece = _board.getPieceAt(pos);
    if (piece != null && piece.color == _playerColor) {
      _selectedPiece = pos;
      _legalMoves = getLegalMoves(pos, _board);
      notifyListeners();
    }
  }

  void moveTo(Position to) {
    if (_selectedPiece == null || _phase != GamePhase.playerTurn) return;
    if (!_legalMoves.contains(to)) {
      _selectedPiece = null;
      _legalMoves = [];
      notifyListeners();
      return;
    }

    final result = makeMove(_selectedPiece!, to, _board);
    if (!result.isValid) return;

    _board = result.newBoard;
    _selectedPiece = null;
    _legalMoves = [];
    _moveHistory.add('player: $to');
    notifyListeners();

    if (result.isCheckmate) {
      _phase = GamePhase.gameOver;
      _message = '你赢了！红方胜利！';
      _winCount++;
      notifyListeners();
      return;
    } else if (result.isCheck) {
      _message = '将军！';
    } else {
      _message = 'AI思考中...';
    }

    // AI回合
    _phase = GamePhase.aiThinking;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 500), () {
      _aiMove();
    });
  }

  void _aiMove() {
    final aiColor = _playerColor == PieceColor.red ? PieceColor.black : PieceColor.red;
    final depth = _aiDifficulty == 1 ? 2 : (_aiDifficulty == 2 ? 4 : 6);
    final ai = AIEngine(maxDepth: depth);
    final bestMove = ai.findBestMove(_board, aiColor);

    if (bestMove == null) {
      _phase = GamePhase.gameOver;
      _message = '你赢了！AI无法移动！';
      _winCount++;
      notifyListeners();
      return;
    }

    final result = makeMove(bestMove.from, bestMove.to, _board);
    _board = result.newBoard;
    _moveHistory.add('AI: ${bestMove.from}->${bestMove.to}'.replaceAll(RegExp(r'[()]'), ''));
    notifyListeners();

    if (result.isCheckmate) {
      _phase = GamePhase.gameOver;
      _message = '将死！AI赢了！';
      _loseCount++;
      notifyListeners();
      return;
    } else if (result.isCheck) {
      _message = 'AI将军，到你了';
    } else {
      _message = '轮到你了';
    }

    _phase = GamePhase.playerTurn;
    notifyListeners();
  }

  void undoMove() {
    if (_moveHistory.length < 2 || _phase != GamePhase.playerTurn) return;
    _moveHistory.removeLast(); // 移除AI的棋
    _moveHistory.removeLast(); // 移除玩家的棋
    resetGame(_moveHistory.length ~/ 2);
  }

  void newGame() {
    _board = ChessBoard();
    _selectedPiece = null;
    _legalMoves = [];
    _phase = GamePhase.playerTurn;
    _message = '红方先行';
    _moveHistory = [];
    notifyListeners();
  }

  void resetGame(int movesToReplay) {
    _board = ChessBoard();
    _selectedPiece = null;
    _legalMoves = [];
    // 简化的重置方式：直接重建
    _phase = GamePhase.playerTurn;
    _message = '重新开始';
    _moveHistory = [];
    notifyListeners();
  }

  void setDifficulty(int level) {
    _aiDifficulty = level;
    // 难度改变时重置游戏
    newGame();
  }

  void switchColor() {
    // 切换玩家和AI的颜色
    _playerColor = _playerColor == PieceColor.red ? PieceColor.black : PieceColor.red;
    newGame();
    if (_playerColor == PieceColor.black) {
      _phase = GamePhase.aiThinking;
      _message = 'AI先手，思考中...';
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 300), () {
        _aiMove();
      });
    }
  }
}
