import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/board.dart';
import '../game/levels.dart';
import '../progress.dart';
import '../theme.dart';
import 'background.dart';
import 'mummy.dart';
import 'symbols.dart';

enum _Phase { playing, won, lost }

class GameScreen extends StatefulWidget {
  final int level;
  const GameScreen({super.key, required this.level});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  static const int cols = 7;
  static const int rows = 8;

  late LevelSpec spec;
  late Board board;
  late List<Tile> _all;
  late final AnimationController _pulse;
  late final Animation<double> _pulseScale;

  Timer? _idle;
  int _moves = 0;
  int _score = 0;
  int _goalDone = 0;
  int _combo = 0;
  int _hintsLeft = 3;
  int _stars = 0;
  bool _busy = false;
  _Phase _phase = _Phase.playing;
  Pos? _selected;
  Set<Pos> _hint = {};
  String? _hintText;
  Pos? _dragFrom;
  Offset _dragAcc = Offset.zero;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _pulseScale = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    _start();
  }

  @override
  void dispose() {
    _idle?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _start() {
    spec = levelFor(widget.level);
    board = Board(rows, cols, spec.kinds);
    _all = board.allTiles();
    _moves = spec.moves;
    _score = 0;
    _goalDone = 0;
    _combo = 0;
    _hintsLeft = 3;
    _stars = 0;
    _busy = false;
    _phase = _Phase.playing;
    _selected = null;
    _hint = {};
    _hintText = null;
    _armIdle();
  }

  Future<void> _wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

  // ---------------------------------------------------------------- التلميحات

  void _armIdle() {
    _idle?.cancel();
    if (_phase != _Phase.playing) return;
    _idle = Timer(const Duration(seconds: 8), () {
      if (mounted && !_busy && _phase == _Phase.playing && _hint.isEmpty) {
        _showHint(free: true);
      }
    });
  }

  void _clearHint() {
    if (_hint.isEmpty && _hintText == null) return;
    _hint = {};
    _hintText = null;
    _pulse.stop();
    _pulse.value = 0;
  }

  void _showHint({bool free = false}) {
    if (_busy || _phase != _Phase.playing) return;
    if (!free && _hintsLeft <= 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('انتهت التلميحات في هذا المستوى')));
      return;
    }
    final m = board.bestMove(spec.goalKind);
    if (m == null) return;
    var text = 'بدّل الرمزين المضيئين لتحصل على ${m.count} رموز مطابقة';
    if (m.goalCount > 0) {
      text += ' منها ${m.goalCount} من رمز الهدف';
    }
    setState(() {
      if (!free) _hintsLeft--;
      _selected = null;
      _hint = {m.a, m.b};
      _hintText = text;
    });
    _pulse.repeat(reverse: true);
  }

  // ------------------------------------------------------------------ الإدخال

  Pos? _cellAt(Offset p, double cell) {
    final c = (p.dx / cell).floor();
    final r = (p.dy / cell).floor();
    if (r < 0 || c < 0 || r >= rows || c >= cols) return null;
    return Pos(r, c);
  }

  void _onTap(Pos? p) {
    if (p == null || _busy || _phase != _Phase.playing) return;
    setState(_clearHint);
    final sel = _selected;
    if (sel == null) {
      setState(() => _selected = p);
    } else if (sel == p) {
      setState(() => _selected = null);
    } else if (Board.adjacent(sel, p)) {
      _attemptSwap(sel, p);
    } else {
      setState(() => _selected = p);
    }
    _armIdle();
  }

  void _onPanUpdate(DragUpdateDetails d, double cell) {
    final from = _dragFrom;
    if (from == null || _busy || _phase != _Phase.playing) return;
    _dragAcc += d.delta;
    if (_dragAcc.distance < cell * 0.35) return;
    final Pos to = _dragAcc.dx.abs() > _dragAcc.dy.abs()
        ? Pos(from.r, from.c + (_dragAcc.dx > 0 ? 1 : -1))
        : Pos(from.r + (_dragAcc.dy > 0 ? 1 : -1), from.c);
    _dragFrom = null;
    if (to.r < 0 || to.c < 0 || to.r >= rows || to.c >= cols) return;
    setState(_clearHint);
    _attemptSwap(from, to);
  }

  // ---------------------------------------------------------------- سير الجولة

  Future<void> _attemptSwap(Pos a, Pos b) async {
    if (_busy || _phase != _Phase.playing) return;
    _busy = true;
    _idle?.cancel();
    setState(() {
      _clearHint();
      _selected = null;
      board.swapTiles(a, b);
    });
    HapticFeedback.selectionClick();
    await _wait(240);
    if (!mounted) return;

    if (board.findRuns().isEmpty) {
      setState(() => board.swapTiles(a, b)); // حركة غير صالحة: تعود الرموز
      await _wait(240);
      if (!mounted) return;
      _busy = false;
      _armIdle();
      return;
    }

    setState(() => _moves--);
    await _resolve();
    if (!mounted) return;

    final goalOk = spec.goalKind == null || _goalDone >= spec.goalCount;
    if (_score >= spec.targetScore && goalOk) {
      await _win();
      return;
    }
    if (_moves <= 0) {
      await _lose();
      return;
    }
    if (board.possibleMoves(null).isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('لا توجد حركات ممكنة، تم خلط الرموز')));
      setState(board.reshuffle);
      await _wait(450);
      if (!mounted) return;
    }
    _busy = false;
    _armIdle();
  }

  /// يحسم التطابقات المتتالية (السلاسل) حتى تستقر اللوحة.
  Future<void> _resolve() async {
    var combo = 0;
    while (true) {
      final runs = board.findRuns();
      if (runs.isEmpty) break;
      combo++;

      final dead = <Tile>{};
      var pts = 0;
      for (final run in runs) {
        dead.addAll(run);
        final len = run.length;
        pts += 20 * len + (len >= 4 ? 40 * (len - 3) : 0);
      }
      pts = (pts * (1 + 0.5 * (combo - 1))).round();
      var goalHit = 0;
      for (final t in dead) {
        t.dying = true;
        if (t.kind == spec.goalKind) goalHit++;
      }
      setState(() {
        _score += pts;
        _combo = combo;
        _goalDone += goalHit;
      });
      HapticFeedback.lightImpact();
      await _wait(250);
      if (!mounted) return;

      board.removeTiles(dead);
      _all.removeWhere(dead.contains);
      final fresh = board.collapseAndRefill();
      _all.addAll(fresh);
      setState(() {}); // تظهر الرموز الجديدة فوق اللوحة والقديمة تبدأ السقوط
      await _wait(40);
      if (!mounted) return;
      board.settle();
      setState(() {});
      await _wait(320);
      if (!mounted) return;
    }
    if (mounted) setState(() => _combo = 0);
  }

  Future<void> _win() async {
    final ratio = _moves / spec.moves;
    _stars = ratio >= 0.35 ? 3 : (ratio >= 0.15 ? 2 : 1);
    _idle?.cancel();
    await Progress.saveWin(widget.level, _stars);
    HapticFeedback.mediumImpact();
    await _wait(350);
    if (!mounted) return;
    setState(() => _phase = _Phase.won);
  }

  Future<void> _lose() async {
    _idle?.cancel();
    await _wait(450);
    if (!mounted) return;
    setState(() => _phase = _Phase.lost); // تظهر المومياء
  }

  void _nextLevel() {
    if (widget.level >= totalLevels) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => GameScreen(level: widget.level + 1)),
    );
  }

  // ------------------------------------------------------------------- الواجهة

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pal.night,
      body: EgyptBackground(
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _hud(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                      child: LayoutBuilder(builder: _boardBuilder),
                    ),
                  ),
                  _bottomBar(),
                ],
              ),
            ),
            if (_phase == _Phase.won)
              Positioned.fill(
                child: _WinPanel(
                  stars: _stars,
                  score: _score,
                  isLast: widget.level >= totalLevels,
                  onNext: _nextLevel,
                  onMenu: () => Navigator.of(context).pop(),
                ),
              ),
            if (_phase == _Phase.lost)
              Positioned.fill(
                child: MummyOverlay(
                  onRetry: () => setState(_start),
                  onMenu: () => Navigator.of(context).pop(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _hud() {
    final pct = (_score / spec.targetScore).clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 18, 12, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Pal.gold),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Pal.goldLight),
                    ),
                    Text(
                      'المستوى ${spec.number} • ${spec.difficulty}',
                      style: const TextStyle(fontSize: 13, color: Pal.sand),
                    ),
                  ],
                ),
              ),
              _chip('الحركات', '$_moves', warn: _moves <= 5),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 12,
                    color: Pal.gold,
                    backgroundColor: Pal.night2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$_score / ${spec.targetScore}',
                style: const TextStyle(fontSize: 14, color: Pal.sand, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 34,
            child: Row(
              children: [
                if (spec.goalKind != null) ...[
                  const Text('الهدف:', style: TextStyle(color: Pal.sand, fontSize: 14)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: CustomPaint(painter: SymbolPainter(spec.goalKind!)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${math.min(_goalDone, spec.goalCount)} / ${spec.goalCount}',
                    style: const TextStyle(color: Pal.goldLight, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
                const Spacer(),
                if (_combo >= 2)
                  Text(
                    'سلسلة ×$_combo',
                    style: const TextStyle(color: Pal.goldLight, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, {bool warn = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: warn ? const Color(0xFF5A1D12) : Pal.night2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: warn ? Pal.carnelian : Pal.gold, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Pal.sand)),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Pal.goldLight)),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 38,
            child: Center(
              child: Text(
                _hintText ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Pal.sand, fontSize: 14),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: (_busy || _phase != _Phase.playing) ? null : _showHint,
            icon: const Icon(Icons.lightbulb_outline),
            label: Text('تلميح ($_hintsLeft)'),
          ),
        ],
      ),
    );
  }

  Widget _boardBuilder(BuildContext context, BoxConstraints cons) {
    const pad = 8.0;
    final cell = math.min((cons.maxWidth - pad * 2) / cols, (cons.maxHeight - pad * 2) / rows);
    final bw = cell * cols;
    final bh = cell * rows;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: const Color(0xCC0A1630),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Pal.gold, width: 2.5),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12)],
        ),
        child: SizedBox(
          width: bw,
          height: bh,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _onTap(_cellAt(d.localPosition, cell)),
            onPanStart: (d) {
              _dragFrom = _cellAt(d.localPosition, cell);
              _dragAcc = Offset.zero;
            },
            onPanUpdate: (d) => _onPanUpdate(d, cell),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: RepaintBoundary(child: CustomPaint(painter: _GridPainter(rows, cols))),
                ),
                for (final t in _all) _tileWidget(t, cell),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tileWidget(Tile t, double cell) {
    final pos = Pos(t.r, t.c);
    final selected = _selected == pos;
    Widget w = Padding(
      padding: EdgeInsets.all(cell * 0.05),
      child: RepaintBoundary(
        child: CustomPaint(
          painter: SymbolPainter(t.kind, glow: selected),
          isComplex: true,
          willChange: false,
        ),
      ),
    );
    if (_hint.contains(pos)) {
      w = ScaleTransition(scale: _pulseScale, child: w);
    }
    w = AnimatedScale(
      scale: t.dying ? 0.1 : (selected ? 1.1 : 1.0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeIn,
      child: AnimatedOpacity(
        opacity: t.dying ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 220),
        child: w,
      ),
    );
    return AnimatedPositioned(
      key: ValueKey<int>(t.id),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOutCubic,
      left: t.c * cell,
      top: t.r * cell,
      width: cell,
      height: cell,
      child: w,
    );
  }
}

class _GridPainter extends CustomPainter {
  final int rows;
  final int cols;
  const _GridPainter(this.rows, this.cols);

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / cols;
    final ch = size.height / rows;
    final a = Paint()..color = Colors.white.withOpacity(0.05);
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if ((r + c).isEven) {
          canvas.drawRect(Rect.fromLTWH(c * cw, r * ch, cw, ch), a);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WinPanel extends StatelessWidget {
  final int stars;
  final int score;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onMenu;

  const _WinPanel({
    required this.stars,
    required this.score,
    required this.isLast,
    required this.onNext,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xCC000000),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          decoration: BoxDecoration(
            color: const Color(0xF0102244),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Pal.gold, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isLast ? 'أتممت كل الألغاز!' : 'أحسنت يا ابن النيل!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Pal.goldLight),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 3; i++)
                    Icon(
                      i <= stars ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 52,
                      color: i <= stars ? Pal.gold : Pal.sand.withOpacity(0.4),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text('النقاط: $score', style: const TextStyle(fontSize: 18, color: Pal.sand)),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton(onPressed: onNext, child: Text(isLast ? 'إنهاء' : 'المستوى التالي')),
                  OutlinedButton(onPressed: onMenu, child: const Text('القائمة')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
