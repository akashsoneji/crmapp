import 'package:crm_app/models/candle_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CandleStyle JSON round-trip', () {
    test('default linear style round-trips', () {
      final src = CandleStyle(scaleMode: ScaleMode.linear, itemCount: 60);
      final dst = CandleStyle.decode(src.encode());
      expect(dst.scaleMode, ScaleMode.linear);
      expect(dst.itemCount, 60);
    });

    test('log mode round-trips', () {
      final src = CandleStyle(scaleMode: ScaleMode.log, itemCount: 30);
      final dst = CandleStyle.decode(src.encode());
      expect(dst.scaleMode, ScaleMode.log);
      expect(dst.itemCount, 30);
    });

    test('malformed JSON falls back to default', () {
      final dst = CandleStyle.decode('not json');
      expect(dst.scaleMode, ScaleMode.linear);
      expect(dst.itemCount, 50);
      expect(dst.showTimeAxis, isTrue);
    });
  });

  test('equality compares visible fields', () {
    final a = CandleStyle(scaleMode: ScaleMode.linear, itemCount: 50);
    final b = CandleStyle(scaleMode: ScaleMode.linear, itemCount: 50);
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });
}