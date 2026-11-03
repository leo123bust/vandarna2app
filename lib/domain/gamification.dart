import 'package:flutter/material.dart';

class UserStats {
  const UserStats({
    this.submitted = 0,
    this.verifiedSubmissions = 0,
    this.confirmations = 0,
    this.reports = 0,
    this.historyEntries = 0,
    this.favorites = 0,
  });
  final int submitted, verifiedSubmissions, confirmations, reports, historyEntries, favorites;

  /// Points only come from useful contributions. Pending submissions give 0 XP,
  /// and verified status needs confirmations from other users, so spam and
  /// duplicates (blocked at submission) cannot farm experience.
  int get xp => verifiedSubmissions * 50 + confirmations * 5 + historyEntries * 10;
}

class AppLevel {
  const AppLevel(this.name, this.minXp);
  final String name;
  final int minXp;
}

const kLevels = <AppLevel>[
  AppLevel('Новобранец', 0),
  AppLevel('Изследовател', 100),
  AppLevel('Откривател', 300),
  AppLevel('Експерт', 700),
];

AppLevel levelFor(int xp) => kLevels.lastWhere((l) => xp >= l.minXp);

AppLevel? nextLevel(int xp) {
  for (final l in kLevels) {
    if (xp < l.minXp) return l;
  }
  return null;
}

double levelProgress(int xp) {
  final next = nextLevel(xp);
  if (next == null) return 1;
  final cur = levelFor(xp);
  return (xp - cur.minXp) / (next.minXp - cur.minXp);
}

class Achievement {
  Achievement(this.title, this.description, this.icon, this.unlocked);
  final String title, description;
  final IconData icon;
  final bool Function(UserStats) unlocked;
}

final kAchievements = <Achievement>[
  Achievement('Първа стъпка', 'Подай първата си сграда', Icons.flag_rounded, (s) => s.submitted >= 1),
  Achievement('Проверен принос', 'Сграда, потвърдена от общността', Icons.verified_rounded, (s) => s.verifiedSubmissions >= 1),
  Achievement('Вярно око', 'Потвърди 5 сгради', Icons.visibility_rounded, (s) => s.confirmations >= 5),
  Achievement('Летописец', 'Добави 3 исторически записа', Icons.menu_book_rounded, (s) => s.historyEntries >= 3),
  Achievement('Колекционер', '5 любими сгради', Icons.bookmark_rounded, (s) => s.favorites >= 5),
  Achievement('Бдителен', 'Докладвай проблемна информация', Icons.flag_circle_rounded, (s) => s.reports >= 1),
];
