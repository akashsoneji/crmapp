import 'package:crm_app/models/enabled_modules_model.dart';
import 'package:crm_app/models/trading_central_model.dart';
import 'package:crm_app/services/trading_central_service.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _sampleBody() => {
  'status': true,
  'success': true,
  'message': 'Trading Central settings retrieved successfully',
  'data': {
    'enabled': true,
    'deposit_required': true,
    'has_first_deposit': true,
    'can_access': true,
    'full_access': false,
    'access_source': '',
    'default_page': 'economic_calendar',
    'menu_label': 'Trading Central',
    'deposit_total': 700,
    'pages': [
      {
        'key': 'economic_calendar',
        'label': 'Economic Calendar',
        'min_deposit': 0,
        'unlocked': true,
        'url': 'https://site.tradingcentral.com/f6aa0a/serve.shtml?tkn=abc',
      },
      {
        'key': 'marketbuzz_ranking',
        'label': 'Market Buzz',
        'min_deposit': 100000,
        'unlocked': false,
        'url': '',
      },
    ],
  },
};

void main() {
  group('TradingCentralService.extractPayload', () {
    test('accepts the full body and the inner data object', () {
      final body = _sampleBody();
      final inner = body['data'] as Map<String, dynamic>;

      expect(TradingCentralService.extractPayload(body), inner);
      expect(TradingCentralService.extractPayload(inner), inner);
    });

    test('returns null for null', () {
      expect(TradingCentralService.extractPayload(null), isNull);
    });
  });

  group('TradingCentralSettings.fromJson', () {
    test('parses the sample response', () {
      final payload = TradingCentralService.extractPayload(_sampleBody())!;
      final settings = TradingCentralSettings.fromJson(payload);

      expect(settings.canAccess, isTrue);
      expect(settings.depositTotal, 700);
      expect(settings.pages, hasLength(2));
      expect(settings.pages.first.canOpen, isTrue);

      final locked = settings.pages.last;
      expect(locked.canOpen, isFalse);
      expect(locked.minDeposit, 100000);
    });

    test('an unlocked page without a url cannot be opened', () {
      final page = TradingCentralPage.fromJson({
        'key': 'news',
        'label': 'News',
        'unlocked': true,
        'url': '',
      });

      expect(page.canOpen, isFalse);
    });
  });

  group('EnabledModulesModel.tradingCentral', () {
    test('true when the flag is on, false when the key is missing', () {
      expect(
        EnabledModulesModel.fromJson({'trading_central': true}).tradingCentral,
        isTrue,
      );
      expect(EnabledModulesModel.fromJson({}).tradingCentral, isFalse);
    });
  });
}
