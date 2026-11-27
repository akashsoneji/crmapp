import 'package:crm_app/constants/color.dart';
import 'package:crm_app/controllers/sheets/account_select_sheet_controller.dart';
import 'package:crm_app/controllers/sheets/instrument_search_sheet_controller.dart';
import 'package:crm_app/controllers/sheets/price_alert_sheet_controller.dart';
import 'package:crm_app/models/mt5_account.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/services/theme_service.dart';
import 'package:crm_app/widgets/home/sheets/account_select_sheet_new.dart';
import 'package:crm_app/widgets/home/sheets/instrument_search_sheet_new.dart';
import 'package:crm_app/widgets/home/sheets/price_alert_sheet_new.dart';
import 'package:crm_app/widgets/home/sheets/sheet_scaffold_new.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakeTheme extends ThemeService {
  _FakeTheme(this.dark);

  final bool dark;

  @override
  bool get isDarkMode => dark;

  // Skips the secure-storage restore and binding observer the real service
  // sets up on init.
  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  // ignore: must_call_super
  void onClose() {}
}

class _FakeLanguage extends LanguageService {
  static const _strings = {
    'price_alerts_above': 'Above',
    'price_alerts_below': 'Below',
    'price_alerts_my_alerts': 'My alerts',
    'instruments_search': 'Search instruments...',
    'common_no_data': 'No data found.',
  };

  // Skips loading translation assets from storage.
  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  String tr(String key, [Map<String, String>? args]) => _strings[key] ?? key;
}

class _AlertCall {
  final String symbol;
  final double targetPrice;
  final String condition;
  final double currentPrice;
  final String? message;

  _AlertCall(
    this.symbol,
    this.targetPrice,
    this.condition,
    this.currentPrice,
    this.message,
  );
}

const _tag = 'test_sheet';

PriceAlertSheetController _putAlertController({
  List<_AlertCall>? calls,
  bool hasPermission = true,
  bool grantPermission = true,
}) {
  return Get.put(
    PriceAlertSheetController(
      symbol: 'EURUSD',
      openingBid: 1.09402,
      digits: 5,
      initializeNotifications: () async {},
      hasNotificationPermission: () => hasPermission,
      requestNotificationPermission: () async => grantPermission,
      addPriceAlert: ({
        required String symbol,
        required double targetPrice,
        required String condition,
        required double currentPrice,
        String? message,
      }) async {
        calls?.add(
          _AlertCall(symbol, targetPrice, condition, currentPrice, message),
        );
      },
    ),
    tag: _tag,
  );
}

MT5Account _account(String id, {String type = 'live', String balance = '0'}) {
  return MT5Account.fromJson({
    'meta_account_number': id,
    'account_type': type,
    'balance': balance,
    'currency': 'USD',
  });
}

Widget _host(Widget child, {double textScale = 1.0}) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (_, _) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(375, 812),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: Align(alignment: Alignment.bottomCenter, child: child),
        ),
      ),
    ),
  );
}

void _useDarkMode(bool dark) {
  if (Get.isRegistered<ThemeService>()) Get.delete<ThemeService>(force: true);
  Get.put<ThemeService>(_FakeTheme(dark));
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<LanguageService>(_FakeLanguage());
  });

  tearDown(Get.reset);

  testWidgets(
      'closing a sheet keeps its text controllers alive until the exit '
      'animation ends', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    _useDarkMode(false);
    final controller = _putAlertController();

    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const SheetControllerScope<
                  PriceAlertSheetController>(
                tag: _tag,
                child: PriceAlertSheetNew(controllerTag: _tag),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('New Price Alert'), findsOneWidget);

    Navigator.of(tester.element(find.text('New Price Alert'))).pop();
    // Mid exit animation: the sheet is still on screen and rebuilding.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    controller.stepUp();
    await tester.pump(const Duration(milliseconds: 50));
    expect(Get.isRegistered<PriceAlertSheetController>(tag: _tag), isTrue);

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('New Price Alert'), findsNothing);
    expect(Get.isRegistered<PriceAlertSheetController>(tag: _tag), isFalse);
  });

  group('PriceAlertSheetController', () {
    test('steps by one tick of the last digit', () {
      final c = _putAlertController();
      expect(c.priceText, '1.09402');
      c.stepUp();
      expect(c.priceText, '1.09403');
      c.stepDown();
      c.stepDown();
      expect(c.priceText, '1.09401');
      expect(c.priceField.text, '1.09401');
    });

    test('distance from bid follows the target price', () {
      final c = _putAlertController();
      for (var i = 0; i < 10; i++) {
        c.stepUp();
      }
      expect(c.distance, closeTo(0.0001, 1e-9));
      expect(c.distancePercent, greaterThan(0));
      c.useLiveBid();
      expect(c.distance, 0);
    });

    test('typing updates the price without rewriting the field', () {
      final c = _putAlertController();
      c.priceField.text = '1.1';
      c.onPriceTyped('1.1');
      expect(c.price.value, 1.1);
      expect(c.priceField.text, '1.1');
      c.onPriceTyped('abc');
      expect(c.price.value, 1.1);
    });

    test('condition toggles and ignores unknown values', () {
      final c = _putAlertController();
      expect(c.isAbove, isTrue);
      c.setCondition(PriceAlertSheetController.conditionBelow);
      expect(c.condition.value, 'below');
      c.setCondition('sideways');
      expect(c.condition.value, 'below');
    });

    test('submit calls the monitor service with the old dialog arguments',
        () async {
      final calls = <_AlertCall>[];
      final c = _putAlertController(calls: calls);
      c.stepUp();
      c.setCondition(PriceAlertSheetController.conditionBelow);
      c.noteField.text = '  take profit  ';

      final created = await c.submit();

      expect(created, isTrue);
      expect(calls, hasLength(1));
      expect(calls.single.symbol, 'EURUSD');
      expect(calls.single.targetPrice, 1.09403);
      expect(calls.single.condition, 'below');
      expect(calls.single.currentPrice, 1.09402);
      expect(calls.single.message, 'take profit');
      expect(c.isLoading.value, isFalse);
    });

    test('submit sends no note when the note is empty', () async {
      final calls = <_AlertCall>[];
      final c = _putAlertController(calls: calls);
      await c.submit();
      expect(calls.single.message, isNull);
    });

    test('submit stops when notification permission is denied', () async {
      final calls = <_AlertCall>[];
      final c = _putAlertController(
        calls: calls,
        hasPermission: false,
        grantPermission: false,
      );
      expect(await c.submit(), isFalse);
      expect(calls, isEmpty);
      expect(c.isLoading.value, isFalse);
    });

    test('submit stops on an empty price field', () async {
      final calls = <_AlertCall>[];
      final c = _putAlertController(calls: calls);
      c.priceField.clear();
      expect(await c.submit(), isFalse);
      expect(calls, isEmpty);
    });
  });

  group('InstrumentSearchSheetController helpers', () {
    test('strips the broker suffix', () {
      expect(InstrumentSearchSheetController.stripSuffix('EURUSD.r'), 'EURUSD');
      expect(InstrumentSearchSheetController.stripSuffix('XAUUSD'), 'XAUUSD');
    });

    test('filters by symbol and removes suffix duplicates', () {
      final source = ['EURUSD', 'EURUSD.r', 'GBPUSD', 'XAUUSD.m', 'BTCUSD'];
      String id(String s) => s;

      expect(
        InstrumentSearchSheetController.filterBySymbol(source, '', id),
        ['EURUSD', 'GBPUSD', 'XAUUSD.m', 'BTCUSD'],
      );
      expect(
        InstrumentSearchSheetController.filterBySymbol(source, 'usd', id),
        ['EURUSD', 'GBPUSD', 'XAUUSD.m', 'BTCUSD'],
      );
      expect(
        InstrumentSearchSheetController.filterBySymbol(source, 'Xau', id),
        ['XAUUSD.m'],
      );
      expect(
        InstrumentSearchSheetController.filterBySymbol(source, '.r', id),
        isEmpty,
      );
    });
  });

  test('account type check matches the old sheet', () {
    expect(AccountSelectSheetController.isDemo(_account('1', type: 'Demo')),
        isTrue);
    expect(AccountSelectSheetController.isDemo(_account('1')), isFalse);
  });

  test('sheet tokens differ between light and dark', () {
    _useDarkMode(false);
    final light = [AppColors.sheetSurface, AppColors.sheetTextPrimary];
    _useDarkMode(true);
    final dark = [AppColors.sheetSurface, AppColors.sheetTextPrimary];
    expect(light, isNot(equals(dark)));
  });

  for (final dark in [false, true]) {
    for (final scale in [1.0, 1.6]) {
      final label = '${dark ? 'dark' : 'light'} @ ${scale}x';

      testWidgets('price alert sheet renders without overflow ($label)',
          (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        _useDarkMode(dark);
        _putAlertController();

        await tester.pumpWidget(
          _host(
            const PriceAlertSheetNew(controllerTag: _tag),
            textScale: scale,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('New Price Alert'), findsOneWidget);
        expect(find.text('Alert me when EURUSD ≥ 1.09402'), findsOneWidget);

        // "My alerts" must stay readable on the sheet in both themes.
        final myAlerts =
            tester.widget<Text>(find.text('My alerts')).style!.color!;
        final a = myAlerts.computeLuminance();
        final b = AppColors.sheetSurface.computeLuminance();
        final ratio = ((a > b ? a : b) + 0.05) / ((a > b ? b : a) + 0.05);
        expect(ratio, greaterThanOrEqualTo(4.5));

        // Same stepper as the pending order sheet: 40px tap target.
        final plus = find.bySemanticsLabel('Increase price');
        expect(tester.getSize(plus).width, greaterThanOrEqualTo(40));
        expect(tester.getSize(plus).height, greaterThanOrEqualTo(40));
        expect(find.text('CONDITION'), findsOneWidget);
        expect(find.text('TARGET PRICE'), findsOneWidget);

        await tester.tap(plus);
        await tester.tap(find.text('Below'));
        await tester.pumpAndSettle();
        expect(find.text('Alert me when EURUSD ≤ 1.09403'), findsOneWidget);
        expect(find.text('+0.00001 (+0.00%)'), findsOneWidget);

        await tester.tap(find.text('Add a note (optional)'));
        await tester.pumpAndSettle();
        expect(find.text('NOTE'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('instrument rows render without overflow ($label)',
          (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        _useDarkMode(dark);

        await tester.pumpWidget(
          _host(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InstrumentRowNew(
                  symbol: 'EURUSD.r',
                  isActive: true,
                  onTap: () {},
                ),
                InstrumentRowNew(
                  symbol: 'AUDCAD',
                  subtitle: 'Currency',
                  onTap: () {},
                  trailing: IconButton(
                    tooltip: 'Add AUDCAD to favourites',
                    onPressed: () {},
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ),
              ],
            ),
            textScale: scale,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('EURUSD'), findsOneWidget);
        expect(find.text('Currency'), findsOneWidget);
        expect(
          find.bySemanticsLabel(RegExp('Current symbol')),
          findsOneWidget,
        );
      });

      testWidgets('account cards render without overflow ($label)',
          (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        _useDarkMode(dark);
        var tapped = 0;

        await tester.pumpWidget(
          _host(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AccountCardNew(
                  account: _account('2000024', balance: '669.59'),
                  isActive: true,
                  onTap: () => tapped++,
                ),
                AccountCardNew(
                  account: _account('2000062', type: 'demo'),
                  isActive: false,
                  onTap: () => tapped++,
                ),
              ],
            ),
            textScale: scale,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('ACTIVE'), findsOneWidget);
        expect(find.text('ID: 2000024'), findsOneWidget);
        expect(
          tester.getSize(find.byType(AccountCardNew).first).height,
          greaterThanOrEqualTo(44),
        );

        // The gradient outline sits behind the whole card: an active fill
        // that is not opaque lets it bleed through and hides the text.
        final activeFill = tester
            .widget<Material>(
              find
                  .descendant(
                    of: find.byType(AccountCardNew).first,
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .color!;
        expect(activeFill.a, 1.0);
        final textColor = tester
            .widget<Text>(find.text('ID: 2000024'))
            .style!
            .color!;
        final lighter = [
          activeFill.computeLuminance(),
          textColor.computeLuminance(),
        ].reduce((a, b) => a > b ? a : b);
        final darker = [
          activeFill.computeLuminance(),
          textColor.computeLuminance(),
        ].reduce((a, b) => a < b ? a : b);
        expect((lighter + 0.05) / (darker + 0.05), greaterThanOrEqualTo(4.5));

        await tester.tap(find.text('ID: 2000062'));
        expect(tapped, 1);
      });
    }
  }
}
