import 'dart:math';

class Pos {
  final int r;
  final int c;
  const Pos(this.r, this.c);

  @override
  bool operator ==(Object other) => other is Pos && other.r == r && other.c == c;

  @override
  int get hashCode => r * 31 + c;
}

class Tile {
  final int id;
  int kind;
  int r;
  int c;
  bool dying = false;

  Tile(this.id, this.kind, this.r, this.c);
}

class Move {
  final Pos a;
  final Pos b;
  final int count; // عدد الرموز التي ستُطابَق
  final int goalCount; // منها كم رمزاً من رمز الهدف

  const Move(this.a, this.b, this.count, this.goalCount);

  int get value => count * 10 + goalCount * 15;
}

/// منطق اللوحة فقط (بدون واجهة): التوليد، المطابقة، السقوط، الخلط، والتلميحات.
class Board {
  final int rows;
  final int cols;
  final int kinds;
  final Random _rng;
  int _nextId = 0;
  late List<List<Tile?>> grid;

  Board(this.rows, this.cols, this.kinds, {int? seed}) : _rng = Random(seed) {
    grid = List.generate(rows, (_) => List<Tile?>.filled(cols, null));
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        grid[r][c] = Tile(_nextId++, 0, r, c);
      }
    }
    _assignNoMatch();
  }

  static bool adjacent(Pos a, Pos b) => (a.r - b.r).abs() + (a.c - b.c).abs() == 1;

  int kindAt(int r, int c) {
    if (r < 0 || c < 0 || r >= rows || c >= cols) return -1;
    return grid[r][c]?.kind ?? -1;
  }

  List<Tile> allTiles() {
    final out = <Tile>[];
    for (final row in grid) {
      for (final t in row) {
        if (t != null) out.add(t);
      }
    }
    return out;
  }

  /// يعطي كل خلية نوعاً بحيث لا توجد مطابقات جاهزة، ويضمن وجود حركة ممكنة.
  void _assignNoMatch() {
    do {
      for (var r = 0; r < rows; r++) {
        for (var c = 0; c < cols; c++) {
          int k;
          do {
            k = _rng.nextInt(kinds);
          } while ((c >= 2 && kindAt(r, c - 1) == k && kindAt(r, c - 2) == k) ||
              (r >= 2 && kindAt(r - 1, c) == k && kindAt(r - 2, c) == k));
          grid[r][c]!.kind = k;
        }
      }
    } while (possibleMoves(null).isEmpty);
  }

  /// كل التسلسلات (3 رموز متتالية أو أكثر) أفقياً ورأسياً.
  List<List<Tile>> findRuns() {
    final runs = <List<Tile>>[];
    for (var r = 0; r < rows; r++) {
      var c = 0;
      while (c < cols) {
        final k = kindAt(r, c);
        if (k < 0) {
          c++;
          continue;
        }
        var e = c + 1;
        while (e < cols && kindAt(r, e) == k) {
          e++;
        }
        if (e - c >= 3) {
          runs.add([for (var i = c; i < e; i++) grid[r][i]!]);
        }
        c = e;
      }
    }
    for (var c = 0; c < cols; c++) {
      var r = 0;
      while (r < rows) {
        final k = kindAt(r, c);
        if (k < 0) {
          r++;
          continue;
        }
        var e = r + 1;
        while (e < rows && kindAt(e, c) == k) {
          e++;
        }
        if (e - r >= 3) {
          runs.add([for (var i = r; i < e; i++) grid[i][c]!]);
        }
        r = e;
      }
    }
    return runs;
  }

  Set<Tile> matchedTiles() {
    final out = <Tile>{};
    for (final run in findRuns()) {
      out.addAll(run);
    }
    return out;
  }

  void swapTiles(Pos a, Pos b) {
    final ta = grid[a.r][a.c]!;
    final tb = grid[b.r][b.c]!;
    grid[a.r][a.c] = tb;
    grid[b.r][b.c] = ta;
    ta.r = b.r;
    ta.c = b.c;
    tb.r = a.r;
    tb.c = a.c;
  }

  void removeTiles(Iterable<Tile> tiles) {
    for (final t in tiles) {
      if (t.r >= 0 && t.r < rows && grid[t.r][t.c] == t) {
        grid[t.r][t.c] = null;
      }
    }
  }

  /// يُسقط الرموز لأسفل ويولّد رموزاً جديدة فوق اللوحة (صفوف سالبة)
  /// لتظهر وهي تسقط. بعد عرضها استدعِ [settle] لتنزل إلى أماكنها.
  List<Tile> collapseAndRefill() {
    final fresh = <Tile>[];
    for (var c = 0; c < cols; c++) {
      var write = rows - 1;
      for (var r = rows - 1; r >= 0; r--) {
        final t = grid[r][c];
        if (t != null) {
          if (r != write) {
            grid[write][c] = t;
            grid[r][c] = null;
            t.r = write;
          }
          write--;
        }
      }
      final empty = write + 1;
      for (var r = write; r >= 0; r--) {
        final t = Tile(_nextId++, _rng.nextInt(kinds), r - empty, c);
        grid[r][c] = t;
        fresh.add(t);
      }
    }
    return fresh;
  }

  void settle() {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final t = grid[r][c];
        if (t != null) {
          t.r = r;
          t.c = c;
        }
      }
    }
  }

  /// كل الحركات الممكنة، مع عدد الرموز التي ستُطابَق في كل حركة.
  List<Move> possibleMoves(int? goalKind) {
    final out = <Move>[];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final a = Pos(r, c);
        for (final b in [Pos(r, c + 1), Pos(r + 1, c)]) {
          if (b.r >= rows || b.c >= cols) continue;
          swapTiles(a, b);
          final tiles = matchedTiles();
          swapTiles(a, b);
          if (tiles.isNotEmpty) {
            final goal = goalKind == null ? 0 : tiles.where((t) => t.kind == goalKind).length;
            out.add(Move(a, b, tiles.length, goal));
          }
        }
      }
    }
    return out;
  }

  /// أفضل حركة: الأكثر مطابقة، مع تفضيل الحركات التي تجمع رمز الهدف.
  Move? bestMove(int? goalKind) {
    final moves = possibleMoves(goalKind);
    if (moves.isEmpty) return null;
    moves.sort((x, y) => y.value.compareTo(x.value));
    return moves.first;
  }

  /// يعيد خلط الرموز الحالية عند انعدام الحركات.
  void reshuffle() {
    final tiles = allTiles();
    for (var attempt = 0; attempt < 100; attempt++) {
      final kindList = [for (final t in tiles) t.kind]..shuffle(_rng);
      for (var i = 0; i < tiles.length; i++) {
        tiles[i].kind = kindList[i];
      }
      if (findRuns().isEmpty && possibleMoves(null).isNotEmpty) return;
    }
    _assignNoMatch();
  }
}
