import 'package:flutter/material.dart';

import '../game/levels.dart';
import '../progress.dart';
import '../theme.dart';
import 'background.dart';
import 'game_screen.dart';
import 'symbols.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Future<void> _play(int level) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => GameScreen(level: level)),
    );
    if (mounted) setState(() {}); // تحديث النجوم والمستويات المفتوحة
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = Progress.unlocked.clamp(1, totalLevels).toInt();
    return Scaffold(
      backgroundColor: Pal.night,
      body: EgyptBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
            children: [
              Center(
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: const CustomPaint(painter: SymbolPainter(2)),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'ألغاز الفراعنة',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Pal.goldLight),
              ),
              const Text(
                'طابق الرموز المقدسة وانجُ من لعنة المومياء',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Pal.sand),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, color: Pal.gold),
                  const SizedBox(width: 4),
                  Text(
                    '${Progress.totalStars} / ${totalLevels * 3}',
                    style: const TextStyle(color: Pal.goldLight, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: FilledButton.icon(
                  onPressed: () => _play(unlocked),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(unlocked == 1 ? 'ابدأ اللعب' : 'تابع اللعب (المستوى $unlocked)'),
                ),
              ),
              const SizedBox(height: 22),
              for (var s = 0; s < kStages.length; s++) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, top: 6),
                  child: Text(
                    kStages[s],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Pal.gold),
                  ),
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var n = s * 8 + 1; n <= s * 8 + 8 && n <= totalLevels; n++) _levelButton(n, unlocked),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 8),
              Text(
                'الرموز: ${kSymbolNames.join(' • ')}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Pal.sand),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _levelButton(int n, int unlocked) {
    final open = n <= unlocked;
    final stars = Progress.starsOf(n);
    return GestureDetector(
      onTap: open ? () => _play(n) : null,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: open ? Pal.night2 : const Color(0x66000000),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: open ? Pal.gold : Pal.sand.withOpacity(0.25), width: 1.5),
        ),
        child: open
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$n', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Pal.goldLight)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 1; i <= 3; i++)
                        Icon(
                          i <= stars ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 15,
                          color: i <= stars ? Pal.gold : Pal.sand.withOpacity(0.35),
                        ),
                    ],
                  ),
                ],
              )
            : Icon(Icons.lock_outline, color: Pal.sand.withOpacity(0.4)),
      ),
    );
  }
}
