import 'dart:math';
import 'package:isar/isar.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/models/xp_event.dart';
import '../../shared/models/enums.dart';

class XpService {
  final Isar _isar;
  XpService(this._isar);

  // XP por ação
  static int xpForAction(TaskColor color, {bool isSubtask = false, bool isMiniTask = false}) {
    if (isMiniTask) return 5;
    if (isSubtask) return 3;
    return switch (color) {
      TaskColor.standard => 10,
      TaskColor.blue     => 15,
      TaskColor.yellow   => 20,
      TaskColor.red      => 30,
    };
  }

  // Fórmula exponencial: XP(n) = 100 × n^1.8
  static int xpRequiredForLevel(int level) => (100 * pow(level, 1.8)).round();

  static int levelFromTotalXp(int totalXp) {
    int level = 1;
    int accumulated = 0;
    while (true) {
      final needed = xpRequiredForLevel(level);
      if (accumulated + needed > totalXp) return level;
      accumulated += needed;
      level++;
    }
  }

  Future<void> addXp(int amount, String description) async {
    final profile = await _isar.userProfiles.get(1);
    if (profile == null) return;
    profile.totalXP = profile.totalXP + amount;
    profile.currentLevel = levelFromTotalXp(profile.totalXP);
    final event = XPEvent()
      ..earnedAt = DateTime.now()
      ..amount = amount
      ..description = description;
    await _isar.writeTxn(() async {
      await _isar.userProfiles.put(profile);
      await _isar.xPEvents.put(event);
    });
  }

  Future<void> deductXp(int amount, String description) async {
    final profile = await _isar.userProfiles.get(1);
    if (profile == null) return;
    profile.totalXP = max(0, profile.totalXP - amount);
    profile.currentLevel = levelFromTotalXp(profile.totalXP);
    final event = XPEvent()
      ..earnedAt = DateTime.now()
      ..amount = -amount
      ..description = description;
    await _isar.writeTxn(() async {
      await _isar.userProfiles.put(profile);
      await _isar.xPEvents.put(event);
    });
  }

  Future<void> checkStreakBonus(UserProfile profile) async {
    if (profile.streakDays == 7)  await addXp(50,  'Streak de 7 dias!');
    if (profile.streakDays == 30) await addXp(200, 'Streak de 30 dias!');
  }
}
