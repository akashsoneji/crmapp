import 'package:crm_app/widgets/home/instrument_trade_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('homeSplitPrice', () {
    test('highlights the last two digits of a 5-digit price', () {
      expect(homeSplitPrice('1.17845'), ('1.178', '45'));
    });

    test('highlights the last two digits of a 2-digit price', () {
      expect(homeSplitPrice('1249.48'), ('1249.', '48'));
    });

    test('returns short strings whole as the highlight', () {
      expect(homeSplitPrice('0'), ('', '0'));
      expect(homeSplitPrice('12'), ('', '12'));
      expect(homeSplitPrice(''), ('', ''));
    });
  });
}
