import 'package:flutter_test/flutter_test.dart';
import 'package:yucafe_note_mobile/utils/roast_freshness.dart';

/// 把「N 天前」换算成 yyyy-MM-dd，避免测试依赖固定日期。
String _daysAgo(int days) {
  final now = DateTime.now();
  final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

void main() {
  group('赏味期推算', () {
    test('浅烘 3 天：仍在排气，还差 5 天进入赏味期', () {
      final f = Freshness.from(roastDate: _daysAgo(3), roastLevel: '浅烘');
      expect(f.stage, FreshnessStage.resting);
      expect(f.daysSinceRoast, 3);
      expect(f.daysToPeak, 5);
    });

    test('浅烘 10 天：处于最佳赏味期', () {
      final f = Freshness.from(roastDate: _daysAgo(10), roastLevel: '浅烘');
      expect(f.stage, FreshnessStage.peak);
      expect(f.daysLeftInPeak, 25);
    });

    test('浅烘 35 天：赏味期最后一天仍是 peak', () {
      final f = Freshness.from(roastDate: _daysAgo(35), roastLevel: '浅烘');
      expect(f.stage, FreshnessStage.peak);
      expect(f.daysLeftInPeak, 0);
    });

    test('浅烘 40 天：进入赏味后期', () {
      final f = Freshness.from(roastDate: _daysAgo(40), roastLevel: '浅烘');
      expect(f.stage, FreshnessStage.declining);
    });

    test('浅烘 60 天：已过赏味期', () {
      final f = Freshness.from(roastDate: _daysAgo(60), roastLevel: '浅烘');
      expect(f.stage, FreshnessStage.stale);
    });

    test('中深烘 5 天：排气已结束，直接进入赏味期', () {
      final f = Freshness.from(roastDate: _daysAgo(5), roastLevel: '中深烘');
      expect(f.stage, FreshnessStage.peak);
      expect(f.profileName, '中深烘');
    });

    test('中深烘 4 天：仍在排气（中深不能被「中」抢先匹配）', () {
      final f = Freshness.from(roastDate: _daysAgo(4), roastLevel: '中深烘');
      expect(f.stage, FreshnessStage.resting);
      expect(f.daysToPeak, 1);
    });

    test('深烘 5 天：排气期 4 天，已进入赏味期', () {
      final f = Freshness.from(roastDate: _daysAgo(5), roastLevel: '深烘');
      expect(f.stage, FreshnessStage.peak);
    });

    test('未标注烘焙度：按中烘口径（6 天排气）', () {
      final f = Freshness.from(roastDate: _daysAgo(5), roastLevel: '');
      expect(f.stage, FreshnessStage.resting);
      expect(Freshness.from(roastDate: _daysAgo(6), roastLevel: '').stage,
          FreshnessStage.peak);
    });

    test('烘焙日期为空或非法：unknown', () {
      expect(Freshness.from(roastDate: '', roastLevel: '浅烘').stage,
          FreshnessStage.unknown);
      expect(Freshness.from(roastDate: 'not-a-date', roastLevel: '浅烘').stage,
          FreshnessStage.unknown);
    });

    test('烘焙日期在未来：unknown，不出现负天数', () {
      final now = DateTime.now();
      final future = DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 3));
      final m = future.month.toString().padLeft(2, '0');
      final d = future.day.toString().padLeft(2, '0');
      final f = Freshness.from(
        roastDate: '${future.year}-$m-$d',
        roastLevel: '浅烘',
      );
      expect(f.stage, FreshnessStage.unknown);
      expect(f.daysSinceRoast, 0);
    });

    test('带时间的日期串也能解析', () {
      final f = Freshness.from(
        roastDate: '${_daysAgo(10)} 08:30:00',
        roastLevel: '浅烘',
      );
      expect(f.stage, FreshnessStage.peak);
    });
  });
}
