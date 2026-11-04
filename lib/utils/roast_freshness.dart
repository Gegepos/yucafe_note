import 'package:flutter/material.dart';

/// 赏味期阶段。
enum FreshnessStage {
  /// 烘焙日期缺失或无法解析。
  unknown,

  /// 刚烘完，还在排气，风味不稳定。
  resting,

  /// 最佳赏味期。
  peak,

  /// 过了最佳赏味期，风味开始衰减。
  declining,

  /// 已经明显不新鲜。
  stale,
}

/// 咖啡豆的「养豆期 / 最佳赏味期」推算结果。
///
/// 只用烘焙日期 + 烘焙度两个字段，纯本地计算，不依赖后端。
/// 天数口径参考业内常见做法：
///
/// | 烘焙度 | 排气期（需养豆） | 最佳赏味期 |
/// |--------|------------------|------------|
/// | 浅烘   | 8 天             | 8–35 天    |
/// | 中烘   | 6 天             | 6–28 天    |
/// | 中深烘 | 5 天             | 5–24 天    |
/// | 深烘   | 4 天             | 4–20 天    |
///
/// 超过最佳赏味期再往后 14 天算「赏味后期」，之后算「已过赏味期」。
class Freshness {
  final FreshnessStage stage;

  /// 已烘焙天数（今天 - 烘焙日期）。
  final int daysSinceRoast;

  /// 距进入最佳赏味期还剩几天（排气中时有值）。
  final int daysToPeak;

  /// 最佳赏味期还剩几天（处于赏味期时有值）。
  final int daysLeftInPeak;

  /// 烘焙度归类后的名字，如「浅烘」。
  final String profileName;

  const Freshness({
    required this.stage,
    required this.daysSinceRoast,
    required this.profileName,
    this.daysToPeak = 0,
    this.daysLeftInPeak = 0,
  });

  /// 短标签，用在列表卡片上。
  String get label {
    switch (stage) {
      case FreshnessStage.resting:
        return '排气中 $daysToPeak 天';
      case FreshnessStage.peak:
        return '最佳赏味期';
      case FreshnessStage.declining:
        return '赏味后期';
      case FreshnessStage.stale:
        return '赏味期已过';
      case FreshnessStage.unknown:
        return '';
    }
  }

  /// 完整说明，用在详情页横幅上。
  String get hint {
    switch (stage) {
      case FreshnessStage.resting:
        return '已烘焙 $daysSinceRoast 天，还在排气阶段，建议再养 $daysToPeak 天再冲。';
      case FreshnessStage.peak:
        return '已烘焙 $daysSinceRoast 天，正值最佳赏味期，还能保持约 $daysLeftInPeak 天。';
      case FreshnessStage.declining:
        return '已烘焙 $daysSinceRoast 天，已过风味峰值，建议尽快冲煮。';
      case FreshnessStage.stale:
        return '已烘焙 $daysSinceRoast 天，风味明显衰减，可以加大粉量或改做冷萃。';
      case FreshnessStage.unknown:
        return '还没有烘焙日期，无法推算赏味期。';
    }
  }

  Color get color {
    switch (stage) {
      case FreshnessStage.resting:
        return const Color(0xFF3F72AF);
      case FreshnessStage.peak:
        return const Color(0xFF2E7D32);
      case FreshnessStage.declining:
        return const Color(0xFFE08A00);
      case FreshnessStage.stale:
        return const Color(0xFF8D8D8D);
      case FreshnessStage.unknown:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData get icon {
    switch (stage) {
      case FreshnessStage.resting:
        return Icons.hourglass_bottom;
      case FreshnessStage.peak:
        return Icons.verified_outlined;
      case FreshnessStage.declining:
        return Icons.trending_down;
      case FreshnessStage.stale:
        return Icons.warning_amber_outlined;
      case FreshnessStage.unknown:
        return Icons.help_outline;
    }
  }

  /// 是否值得在界面上提示（未知阶段不提示）。
  bool get isKnown => stage != FreshnessStage.unknown;

  /// 烘焙日期 + 烘焙度 → 赏味期推算。
  ///
  /// [roastDate] 形如 `2026-10-20`；解析失败时返回 [FreshnessStage.unknown]。
  static Freshness from({required String roastDate, required String roastLevel}) {
    final roasted = _parseDate(roastDate);
    if (roasted == null) {
      return Freshness(stage: FreshnessStage.unknown, daysSinceRoast: 0, profileName: '');
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(roasted).inDays;
    if (days < 0) {
      // 烘焙日期写成了未来，按刚烘焙处理，避免出现负数天数。
      return Freshness(stage: FreshnessStage.unknown, daysSinceRoast: 0, profileName: '');
    }

    final profile = _profileFor(roastLevel);
    if (days < profile.degasDays) {
      return Freshness(
        stage: FreshnessStage.resting,
        daysSinceRoast: days,
        profileName: profile.name,
        daysToPeak: profile.degasDays - days,
      );
    }
    if (days <= profile.peakEndDay) {
      return Freshness(
        stage: FreshnessStage.peak,
        daysSinceRoast: days,
        profileName: profile.name,
        daysLeftInPeak: profile.peakEndDay - days,
      );
    }
    if (days <= profile.peakEndDay + 14) {
      return Freshness(
        stage: FreshnessStage.declining,
        daysSinceRoast: days,
        profileName: profile.name,
      );
    }
    return Freshness(
      stage: FreshnessStage.stale,
      daysSinceRoast: days,
      profileName: profile.name,
    );
  }

  static DateTime? _parseDate(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static _RoastProfile _profileFor(String roastLevel) {
    final l = roastLevel.trim().toLowerCase();
    // 注意顺序：先匹配「中深」，否则会被「中」抢先命中。
    if (l.contains('浅') || l.contains('light')) return const _RoastProfile(8, 35, '浅烘');
    if (l.contains('中深')) return const _RoastProfile(5, 24, '中深烘');
    if (l.contains('深') || l.contains('dark')) return const _RoastProfile(4, 20, '深烘');
    if (l.contains('中') || l.contains('medium')) return const _RoastProfile(6, 28, '中烘');
    return const _RoastProfile(6, 28, '未标注烘焙度');
  }
}

class _RoastProfile {
  /// 排气期天数，到这个天数才算进入最佳赏味期。
  final int degasDays;

  /// 最佳赏味期结束于烘焙后第几天。
  final int peakEndDay;

  final String name;

  const _RoastProfile(this.degasDays, this.peakEndDay, this.name);
}
