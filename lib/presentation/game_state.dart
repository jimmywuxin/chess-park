import 'package:flutter/foundation.dart';
import '../domain/board.dart';
import '../domain/piece.dart';
import '../domain/rules.dart';
import '../data/ai_engine.dart';
import '../data/opening_book.dart';

enum GamePhase { playerTurn, aiThinking, gameOver }

class MoveRecord {
  final Position from;
  final Position to;
  final bool isAiMove;
  const MoveRecord(this.from, this.to, {this.isAiMove = false});
}

class GameState extends ChangeNotifier {
  ChessBoard _board = ChessBoard();
  PieceColor _playerColor = PieceColor.red;
  int _aiDifficulty = 2;
  GamePhase _phase = GamePhase.playerTurn;
  Position? _selectedPiece;
  List<Position> _legalMoves = [];
  String _message = '红方先行';
  int _winCount = 0;
  int _loseCount = 0;
  List<ChessBoard> _boardHistory = [];
  List<String> _moveHistory = [];
  MoveRecord? _lastMove;
  final List<Move> _allMoves = [];

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
  MoveRecord? get lastMove => _lastMove;

  /// 根据难度返回 (maxDepth, timeLimitMs)
  (int, int) get _aiParams {
    switch (_aiDifficulty) {
      case 1: return (4, 2000);   // 简单：4层，2秒
      case 2: return (6, 4000);   // 中等：6层，4秒
      case 3: return (8, 8000);   // 困难：8层，8秒
      default: return (6, 4000);
    }
  }

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

    final from = _selectedPiece!;
    final result = makeMove(from, to, _board);
    if (!result.isValid) return;

    _boardHistory.add(_board.clone());
    _board = result.newBoard;
    _lastMove = MoveRecord(from, to, isAiMove: false);
    _selectedPiece = null;
    _legalMoves = [];
    _moveHistory.add('player: $to');
    _allMoves.add(Move(from, to));

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

    _phase = GamePhase.aiThinking;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 500), () {
      _aiMove();
    });
  }

  void _aiMove() {
    final aiColor = _playerColor == PieceColor.red ? PieceColor.black : PieceColor.red;

    // 先查开局库
    Move? bestMove = OpeningBook.getNextMove(_allMoves);

    // 开局库没有匹配，用增强 AI 搜索
    if (bestMove == null) {
      final (depth, timeMs) = _aiParams;
      final ai = AIEngine(maxDepth: depth, timeLimitMs: timeMs);
      bestMove = ai.findBestMove(_board, aiColor);
    }

    if (bestMove == null) {
      _phase = GamePhase.gameOver;
      _message = '你赢了！AI无法移动！';
      _winCount++;
      notifyListeners();
      return;
    }

    // 验证走法合法
    final legalMoves = getLegalMoves(bestMove.from, _board);
    if (!legalMoves.contains(bestMove.to)) {
      final (depth, timeMs) = _aiParams;
      final ai = AIEngine(maxDepth: depth, timeLimitMs: timeMs);
      bestMove = ai.findBestMove(_board, aiColor);
      if (bestMove == null) {
        _phase = GamePhase.gameOver;
        _message = '你赢了！AI无法移动！';
        _winCount++;
        notifyListeners();
        return;
      }
    }

    _boardHistory.add(_board.clone());
    final result = makeMove(bestMove.from, bestMove.to, _board);
    _board = result.newBoard;
    _lastMove = MoveRecord(bestMove.from, bestMove.to, isAiMove: true);
    _moveHistory.add('AI: ${bestMove.from}->${bestMove.to}'.replaceAll(RegExp(r'[()]'), ''));
    _allMoves.add(bestMove);

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
    if (_boardHistory.length < 2 || _phase != GamePhase.playerTurn) return;
    _boardHistory.removeLast();
    _board = _boardHistory.removeLast();
    _moveHistory.removeLast();
    _moveHistory.removeLast();
    if (_allMoves.length >= 2) {
      _allMoves.removeLast();
      _allMoves.removeLast();
    }
    _selectedPiece = null;
    _legalMoves = [];
    _lastMove = null;
    _phase = GamePhase.playerTurn;
    _message = '已悔棋，轮到你了';
    notifyListeners();
  }

  void newGame() {
    _board = ChessBoard();
    _selectedPiece = null;
    _legalMoves = [];
    _phase = GamePhase.playerTurn;
    _message = '红方先行';
    _moveHistory = [];
    _boardHistory = [];
    _lastMove = null;
    _allMoves.clear();
    notifyListeners();
  }

  void setDifficulty(int level) {
    _aiDifficulty = level;
    newGame();
  }

  void switchColor() {
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
