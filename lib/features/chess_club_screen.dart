import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess;
import 'package:flutter_svg/flutter_svg.dart';

import '../core/games/chess_game_controller.dart';

/// رموز بصرية أصلية للوحة حديثة سهلة القراءة على الهاتف. تستلهم وضوح
/// ألعاب الشطرنج الحديثة فقط؛ القطع المستخدمة من مجموعة Meridian العامة.
abstract final class ChessClubVisualTokens {
  static const background = Color(0xFF0B1420);
  static const panel = Color(0xFF172638);
  static const lightSquareTop = Color(0xFFEEF2BD);
  static const lightSquareBottom = Color(0xFFEEF2BD);
  static const darkSquareTop = Color(0xFF769656);
  static const darkSquareBottom = Color(0xFF769656);
  static const selected = Color(0xFFE5B53A);
  static const legalTarget = Color(0xFF6AA84F);
}

class ChessClubScreen extends StatefulWidget {
  const ChessClubScreen({super.key});

  @override
  State<ChessClubScreen> createState() => _ChessClubScreenState();
}

class _ChessClubScreenState extends State<ChessClubScreen> {
  final ChessGameController _chess = ChessGameController();

  bool _playAgainstComputer = true;
  ChessComputerLevel _computerLevel = ChessComputerLevel.medium;
  String? _selectedSquare;
  List<String> _legalTargets = const [];
  bool _computerThinking = false;
  String _gameNotice = 'دور الأبيض';
  String? _suggestedHint;

  bool get _computerTurn => _playAgainstComputer && !_chess.isWhiteTurn;

  void _setPlayMode(bool againstComputer) {
    setState(() {
      _playAgainstComputer = againstComputer;
      _chess.reset();
      _selectedSquare = null;
      _legalTargets = const [];
      _suggestedHint = null;
      _gameNotice = 'مباراة جديدة — دور الأبيض';
    });
  }

  void _resetGame() {
    setState(() {
      _chess.reset();
      _selectedSquare = null;
      _legalTargets = const [];
      _computerThinking = false;
      _suggestedHint = null;
      _gameNotice = 'مباراة جديدة — دور الأبيض';
    });
    if (_computerTurn) _scheduleComputer();
  }

  void _scheduleComputer() {
    if (_computerThinking || !mounted) return;
    if (!_computerTurn || _chess.gameOver) return;
    _computerThinking = true;

    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (!_computerTurn || _chess.gameOver) {
        setState(() => _computerThinking = false);
        return;
      }
      if (_chess.moveComputer(level: _computerLevel)) {
        setState(() {
          _computerThinking = false;
          _selectedSquare = null;
          _legalTargets = const [];
          _suggestedHint = null;
          _gameNotice = _buildNotice();
        });
      } else {
        setState(() => _computerThinking = false);
      }
    });
  }

  void _getBestHint() {
    if (_chess.gameOver) return;
    final hintMove = _chess.getBestMove(level: _computerLevel);
    setState(() {
      _suggestedHint = hintMove != null ? 'التلميح الموصى به: $hintMove' : 'لا يوجد تلميح مباشر';
    });
  }

  void _undoMove() {
    if (_computerThinking || !_chess.canUndo) return;
    final undoCount = _playAgainstComputer && _chess.isWhiteTurn ? 2 : 1;
    for (var index = 0; index < undoCount; index++) {
      if (_chess.undoLastMove() == null) break;
    }
    setState(() {
      _selectedSquare = null;
      _legalTargets = const [];
      _suggestedHint = null;
      _gameNotice = _buildNotice();
    });
  }

  void _onSquareTap(String square) {
    if (_chess.gameOver || _computerTurn || _computerThinking) return;

    final piece = _chess.pieceAt(square);
    final isOwn = piece != null &&
        piece.color == (_chess.isWhiteTurn ? chess.Color.WHITE : chess.Color.BLACK);

    if (isOwn) {
      setState(() {
        _selectedSquare = square;
        _legalTargets = _chess.legalMovesFrom(square);
      });
      return;
    }

    if (_selectedSquare != null && _legalTargets.contains(square)) {
      _tryMove(_selectedSquare!, square);
    }
  }

  void _tryMove(String from, String to) {
    final success = _chess.makeMove(from, to);
    if (success) {
      setState(() {
        _selectedSquare = null;
        _legalTargets = const [];
        _suggestedHint = null;
        _gameNotice = _buildNotice();
      });
      if (_computerTurn) _scheduleComputer();
    }
  }

  String _buildNotice() {
    if (_chess.inCheckmate) return 'كش مات! انتهت اللعبة';
    if (_chess.inDraw) return 'تعادل!';
    if (_chess.inCheck) return 'كش ملك! ${_chess.isWhiteTurn ? "دور الأبيض" : "دور الأسود"}';
    return _chess.isWhiteTurn ? 'دور الأبيض' : 'دور الأسود';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChessClubVisualTokens.background,
      appBar: AppBar(
        title: const Text('الشطرنج الملكي'),
        backgroundColor: ChessClubVisualTokens.panel,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline, color: Colors.amber),
            tooltip: 'تلميح ونقلة مقترحة',
            onPressed: _getBestHint,
          ),
          IconButton(
            icon: const Icon(Icons.undo_rounded),
            tooltip: 'تراجع عن آخر نقلة',
            onPressed: _chess.canUndo && !_computerThinking ? _undoMove : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'إعادة المباراة',
            onPressed: _resetGame,
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط التحكم بالخيارات والمستويات
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [ChessClubVisualTokens.panel, Color(0xFF0E1B2B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(bottom: BorderSide(color: Color(0xFF37506B))),
            ),
            child: Row(
              children: [
                const Text('المستوى: ', style: TextStyle(color: Colors.white70)),
                DropdownButton<ChessComputerLevel>(
                  value: _computerLevel,
                  dropdownColor: const Color(0xFF2A2A3D),
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                  items: ChessComputerLevel.values.map((lvl) {
                    return DropdownMenuItem(
                      value: lvl,
                      child: Text(lvl.label),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _computerLevel = val);
                  },
                ),
                const Spacer(),
                FilterChip(
                  label: Text(_playAgainstComputer ? 'ضد الكمبيوتر' : 'لاعبان'),
                  selected: _playAgainstComputer,
                  onSelected: _setPlayMode,
                ),
              ],
            ),
          ),
          if (_suggestedHint != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.amber.withValues(alpha: 0.2),
              child: Text(
                _suggestedHint!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _gameNotice,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          // الرقعة بالتصميم المطور المجسم 3D
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3C3A36), Color(0xFF262421), Color(0xFF3C3A36)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: [0, 0.5, 1],
                      ),
                      border: Border.all(color: const Color(0xFF55524C), width: 1.6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.66),
                          blurRadius: 20,
                          offset: const Offset(0, 11),
                        ),
                        BoxShadow(
                          color: const Color(0xFFFFD66B).withValues(alpha: 0.16),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(9),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                        itemCount: 64,
                        itemBuilder: (context, index) {
                      final rank = 8 - (index ~/ 8);
                      final fileIndex = index % 8;
                      final fileName = String.fromCharCode('a'.codeUnitAt(0) + fileIndex);
                      final square = '$fileName$rank';

                      final isDark = (rank + fileIndex).isOdd;
                      final isSelected = _selectedSquare == square;
                      final isTarget = _legalTargets.contains(square);
                      final piece = _chess.pieceAt(square);

                      return GestureDetector(
                        onTap: () => _onSquareTap(square),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isSelected
                                  ? const [Color(0xFFFFE083), ChessClubVisualTokens.selected]
                                  : isTarget
                                      ? const [Color(0xFFA3CF78), ChessClubVisualTokens.legalTarget]
                                      : isDark
                                          ? const [ChessClubVisualTokens.darkSquareTop, ChessClubVisualTokens.darkSquareBottom]
                                          : const [ChessClubVisualTokens.lightSquareTop, ChessClubVisualTokens.lightSquareBottom],
                            ),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.16),
                              width: 0.35,
                            ),
                          ),
                          child: Center(
                            child: piece == null
                                ? null
                                : Container(
                                    margin: const EdgeInsets.all(1),
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.36),
                                          blurRadius: 2.6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(1),
                                      child: SvgPicture.asset(
                                        ChessGameController.pieceAssetPath(piece)!,
                                        fit: BoxFit.contain,
                                        semanticsLabel: 'قطعة شطرنج',
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      );
                        },
                      ),
                    ),
                  ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
