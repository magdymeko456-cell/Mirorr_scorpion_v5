import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/games/chess_game_controller.dart';

void main() {
  test('starts with legal white pawn moves and alternates with local computer', () {
    final game = ChessGameController();

    expect(game.legalMovesFrom('e2'), containsAll(<String>['e3', 'e4']));
    expect(game.moveHuman('e2', 'e4'), isTrue);
    expect(game.isWhiteTurn, isFalse);
    expect(game.moveComputer(), isTrue);
    expect(game.isWhiteTurn, isTrue);
  });

  test('allows both human sides in local two-player mode', () {
    final game = ChessGameController();

    expect(game.moveHuman('e2', 'e4'), isTrue);
    expect(game.moveHuman('d7', 'd5'), isTrue);
  });

  test('computer makes a legal move at every local difficulty', () {
    for (final level in ChessComputerLevel.values) {
      final game = ChessGameController();
      expect(game.moveHuman('e2', 'e4'), isTrue);
      expect(game.moveComputer(level: level), isTrue);
      expect(game.isWhiteTurn, isTrue);
    }
  });

  test('computer does not move during white turn or after game over', () {
    final game = ChessGameController();
    expect(game.moveComputer(), isFalse);

    expect(game.moveHuman('f2', 'f3'), isTrue);
    expect(game.moveHuman('e7', 'e5'), isTrue);
    expect(game.moveHuman('g2', 'g4'), isTrue);
    expect(game.moveHuman('d8', 'h4'), isTrue);
    expect(game.gameOver, isTrue);
    expect(game.moveComputer(level: ChessComputerLevel.skilled), isFalse);
  });

  test('records the last move and its captured piece for the board UI', () {
    final game = ChessGameController();

    expect(game.moveHuman('e2', 'e4'), isTrue);
    expect(game.moveHuman('d7', 'd5'), isTrue);
    expect(game.moveHuman('e4', 'd5'), isTrue);

    expect(game.lastMove?.from, 'e4');
    expect(game.lastMove?.to, 'd5');
    expect(game.lastMove?.movedByWhite, isTrue);
    expect(game.lastMove?.capturedSymbol, '♟');
  });

  test('maps starting pieces to visible Unicode chess symbols', () {
    final game = ChessGameController();

    expect(ChessGameController.pieceSymbol(game.pieceAt('e2')), '♙');
    expect(ChessGameController.pieceSymbol(game.pieceAt('e7')), '♟');
    expect(ChessGameController.pieceSymbol(game.pieceAt('d1')), '♕');
    expect(ChessGameController.pieceSymbol(game.pieceAt('d8')), '♛');
    expect(ChessGameController.pieceSymbol(game.pieceAt('e4')), isEmpty);
  });

  test('maps board pieces to stable local SVG assets', () {
    final game = ChessGameController();

    expect(
      ChessGameController.pieceAssetPath(game.pieceAt('e2')),
      'assets/images/chess/meridian_shaded/wp.svg',
    );
    expect(
      ChessGameController.pieceAssetPath(game.pieceAt('d8')),
      'assets/images/chess/meridian_shaded/bq.svg',
    );
  });

  test('undo restores the previous board position', () {
    final game = ChessGameController();
    expect(game.moveHuman('e2', 'e4'), isTrue);

    final undone = game.undoLastMove();

    expect(undone?.from, 'e2');
    expect(game.pieceAt('e2'), isNotNull);
    expect(game.pieceAt('e4'), isNull);
    expect(game.isWhiteTurn, isTrue);
  });
}
