import 'dart:math';
import 'package:chess/chess.dart' as chess;

enum ChessComputerLevel { normal, medium, skilled }

extension ChessComputerLevelLabel on ChessComputerLevel {
  String get label => switch (this) {
        ChessComputerLevel.normal => 'عادي',
        ChessComputerLevel.medium => 'متوسط',
        ChessComputerLevel.skilled => 'ماهر',
      };
}

class ChessMoveSummary {
  const ChessMoveSummary({
    required this.from,
    required this.to,
    required this.movedByWhite,
    this.capturedSymbol = '',
  });

  final String from;
  final String to;
  final bool movedByWhite;
  final String capturedSymbol;

  bool get isCapture => capturedSymbol.isNotEmpty;
}

class ChessGameController {
  ChessGameController() : _game = chess.Chess();

  chess.Chess _game;
  final Random _random = Random();
  ChessMoveSummary? _lastMove;
  final List<ChessMoveSummary> _moveHistory = <ChessMoveSummary>[];

  chess.Piece? pieceAt(String square) => _game.get(square);

  // دالة static للواجهة القديمة والاختبارات
  static String pieceSymbol(chess.Piece? piece) {
    if (piece == null) return '';
    const white = <String, String>{
      'p': '♙', 'n': '♘', 'b': '♗', 'r': '♖', 'q': '♕', 'k': '♔',
    };
    const black = <String, String>{
      'p': '♟', 'n': '♞', 'b': '♝', 'r': '♜', 'q': '♛', 'k': '♚',
    };
    final symbols = piece.color == chess.Color.WHITE ? white : black;
    return symbols[piece.type.name] ?? '';
  }

  // دالة instance للواجهة الجديدة
  String getPieceSymbol(chess.Piece? piece) => pieceSymbol(piece);

  /// أصل SVG محلي ثابت للقطعة، بدلاً من خط Unicode المتغير بين أجهزة Android.
  static String? pieceAssetPath(chess.Piece? piece) {
    if (piece == null) return null;
    final color = piece.color == chess.Color.WHITE ? 'w' : 'b';
    final type = switch (piece.type) {
      chess.Chess.PAWN => 'p',
      chess.Chess.KNIGHT => 'n',
      chess.Chess.BISHOP => 'b',
      chess.Chess.ROOK => 'r',
      chess.Chess.QUEEN => 'q',
      chess.Chess.KING => 'k',
      _ => null,
    };
    return type == null
        ? null
        : 'assets/images/chess/meridian_shaded/$color$type.svg';
  }

  bool get isWhiteTurn => _game.turn == chess.Color.WHITE;
  bool get gameOver => _game.game_over;
  
  // دعم التسميتين (القديمة والجديدة)
  bool get inCheckmate => _game.in_checkmate;
  bool get isCheckmate => _game.in_checkmate;

  bool get inDraw => _game.in_draw;
  bool get isDraw => _game.in_draw;

  bool get inCheck => _game.in_check;
  bool get isCheck => _game.in_check;

  String get pgn => _game.pgn();
  ChessMoveSummary? get lastMove => _lastMove;
  bool get canUndo => _moveHistory.isNotEmpty;

  List<String> legalMovesFrom(String square) {
    final legalTargets = <String>[];
    for (final move in _game.moves({'verbose': true})) {
      if (move is Map && move['from'] == square && move['to'] is String) {
        legalTargets.add(move['to'] as String);
      }
    }
    return legalTargets;
  }

  // دعم التسميتين للمحرك (moveHuman و makeMove)
  bool makeMove(String from, String to) {
    if (gameOver) return false;
    return _applyMove({'from': from, 'to': to, 'promotion': 'q'});
  }

  bool moveHuman(String from, String to) => makeMove(from, to);

  String? getBestMove({ChessComputerLevel level = ChessComputerLevel.medium}) {
    final moves = _verboseMoves();
    if (moves.isEmpty) return null;

    if (level == ChessComputerLevel.normal) {
      final m = moves[_random.nextInt(moves.length)];
      return "${m['from']} ➔ ${m['to']}";
    }

    var bestScore = isWhiteTurn ? -(1 << 30) : (1 << 30);
    Map<String, dynamic>? selectedMove;

    for (final move in moves) {
      final candidate = _game.copy();
      if (!_applyMoveTo(candidate, move)) continue;
      final score = _materialScore(candidate);

      if (isWhiteTurn) {
        if (score > bestScore) {
          bestScore = score;
          selectedMove = move;
        }
      } else {
        if (score < bestScore) {
          bestScore = score;
          selectedMove = move;
        }
      }
    }

    selectedMove ??= moves[_random.nextInt(moves.length)];
    return "${selectedMove['from']} ➔ ${selectedMove['to']}";
  }

  bool moveComputer({ChessComputerLevel level = ChessComputerLevel.medium}) {
    if (isWhiteTurn || gameOver) return false;
    final moves = _verboseMoves();
    if (moves.isEmpty) return false;

    if (level == ChessComputerLevel.normal) {
      return _applyMove(moves[_random.nextInt(moves.length)]);
    }

    var bestScore = 1 << 30;
    final bestMoves = <Map<String, dynamic>>[];
    for (final move in moves) {
      final candidate = _game.copy();
      if (!_applyMoveTo(candidate, move)) continue;
      final score = level == ChessComputerLevel.skilled
          ? _scoreAfterBestWhiteReply(candidate)
          : _materialScore(candidate);
      if (score < bestScore) {
        bestScore = score;
        bestMoves
          ..clear()
          ..add(move);
      } else if (score == bestScore) {
        bestMoves.add(move);
      }
    }
    if (bestMoves.isEmpty) return false;
    return _applyMove(bestMoves[_random.nextInt(bestMoves.length)]);
  }

  /// يرجع نقلة واحدة قانونياً ويسلّم ملخصها للواجهة لتحديث حالتها.
  ChessMoveSummary? undoLastMove() {
    if (_moveHistory.isEmpty || _game.history.isEmpty) return null;
    _game.undo_move();
    final undone = _moveHistory.removeLast();
    _lastMove = _moveHistory.isEmpty ? null : _moveHistory.last;
    return undone;
  }

  int _scoreAfterBestWhiteReply(chess.Chess position) {
    final replies = _verboseMoves(position);
    if (replies.isEmpty) return _materialScore(position);
    var whiteBestScore = -(1 << 30);
    for (final reply in replies) {
      final afterReply = position.copy();
      if (!_applyMoveTo(afterReply, reply)) continue;
      whiteBestScore = max(whiteBestScore, _materialScore(afterReply));
    }
    return whiteBestScore == -(1 << 30) ? _materialScore(position) : whiteBestScore;
  }

  List<Map<String, dynamic>> _verboseMoves([chess.Chess? position]) {
    final activeGame = position ?? _game;
    return activeGame
        .moves({'verbose': true})
        .whereType<Map>()
        .map((move) => Map<String, dynamic>.from(move))
        .where((move) => move['from'] is String && move['to'] is String)
        .toList();
  }

  bool _applyMove(Map<String, dynamic> move) {
    final from = move['from'] as String;
    final to = move['to'] as String;
    final movingPiece = _game.get(from);
    var capturedPiece = _game.get(to);
    if (capturedPiece == null &&
        movingPiece?.type == chess.Chess.PAWN &&
        from.substring(0, 1) != to.substring(0, 1)) {
      capturedPiece = _game.get('${to.substring(0, 1)}${from.substring(1, 2)}');
    }
    final movedByWhite = isWhiteTurn;
    if (!_applyMoveTo(_game, move)) return false;
    _lastMove = ChessMoveSummary(
      from: from,
      to: to,
      movedByWhite: movedByWhite,
      capturedSymbol: pieceSymbol(capturedPiece),
    );
    _moveHistory.add(_lastMove!);
    return true;
  }

  bool _applyMoveTo(chess.Chess position, Map<String, dynamic> move) {
    return position.move({
      'from': move['from'],
      'to': move['to'],
      'promotion': move['promotion'] ?? 'q',
    });
  }

  void reset() {
    _game = chess.Chess();
    _lastMove = null;
    _moveHistory.clear();
  }

  int _materialScore(chess.Chess position) {
    final values = {
      chess.Chess.PAWN: 100,
      chess.Chess.KNIGHT: 320,
      chess.Chess.BISHOP: 330,
      chess.Chess.ROOK: 500,
      chess.Chess.QUEEN: 900,
      chess.Chess.KING: 20000,
    };
    var score = 0;
    for (final file in const ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']) {
      for (var rank = 1; rank <= 8; rank++) {
        final piece = position.get('$file$rank');
        if (piece == null) continue;
        final value = values[piece.type] ?? 0;
        score += piece.color == chess.Color.WHITE ? value : -value;
      }
    }
    return score;
  }
}
