import 'dart:math' as math;

const int totalLevels = 40;

const List<String> kStages = [
  'ضفاف النيل',
  'معبد الكرنك',
  'أهرامات الجيزة',
  'وادي الملوك',
  'حجرة الكنز',
];

class LevelSpec {
  final int number;
  final int kinds; // عدد أنواع الرموز المستخدمة (4 إلى 6)
  final int moves; // عدد الحركات المتاحة
  final int targetScore; // النقاط المطلوبة
  final int? goalKind; // رمز مطلوب جمعه (اختياري)
  final int goalCount; // عدد الرموز المطلوب جمعها
  final String stage;
  final String difficulty;

  const LevelSpec({
    required this.number,
    required this.kinds,
    required this.moves,
    required this.targetScore,
    required this.goalKind,
    required this.goalCount,
    required this.stage,
    required this.difficulty,
  });

  String get title => '$stage';
}

/// تتدرج الصعوبة بثلاث طرق: زيادة أنواع الرموز، تقليل الحركات، ورفع النقاط
/// المطلوبة، مع هدف جمع رمز معين كل ثلاثة مستويات.
LevelSpec levelFor(int n) {
  final level = math.max(1, math.min(n, totalLevels));
  final kinds = level <= 6 ? 4 : (level <= 20 ? 5 : 6);
  final moves = math.max(16, 30 - level ~/ 3);
  final target = 900 + level * 50;
  final hasGoal = level % 3 == 0;
  final goalKind = hasGoal ? (level ~/ 3) % kinds : null;
  final goalCount = hasGoal ? 5 + level ~/ 5 : 0;
  final stageIndex = math.min((level - 1) ~/ 8, kStages.length - 1);
  final difficulty = level <= 8
      ? 'سهل'
      : level <= 20
          ? 'متوسط'
          : level <= 32
              ? 'صعب'
              : 'خبير';
  return LevelSpec(
    number: level,
    kinds: kinds,
    moves: moves,
    targetScore: target,
    goalKind: goalKind,
    goalCount: goalCount,
    stage: kStages[stageIndex],
    difficulty: difficulty,
  );
}
