import 'package:crm_app/controllers/instruments_controller.dart';
import 'package:crm_app/flavor_config.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/widgets/home/instrument_trade_card.dart';
import 'package:crm_app/widgets/home/quick_actions_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Returns the key itself so tests do not depend on asset loading.
class _FakeLanguageService extends LanguageService {
  @override
  String tr(String key, [Map<String, String>? args]) => key;
}

const _symbol = 'EURUSD';

void main() {
  late InstrumentsController controller;

  setUp(() {
    FlavorConfig.tenax;
    Get.put<LanguageService>(_FakeLanguageService());
    // Constructed directly (not Get.put) so onInit never opens sockets.
    controller = InstrumentsController();
    controller.priceRx(_symbol).value = const InstrumentPrice(
      bid: 1.08512,
      ask: 1.08530,
      digits: 5,
      spreadDiff: 0.00018,
      dayLow: 1.08001,
      dayHigh: 1.09002,
    );
  });

  tearDown(Get.reset);

  Future<void> pumpHome(
    WidgetTester tester, {
    double textScale = 1,
    bool Function(HomeShortcut)? isVisible,
  }) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: ListView(
              children: [
                QuickActionsGrid(
                  onShortcutTap: (_) {},
                  isVisible: isVisible ?? (_) => true,
                ),
                InstrumentTradeCard(
                  symbol: _symbol,
                  controller: controller,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('quick actions only lays out the shortcuts that are available', (
    tester,
  ) async {
    const available = {HomeShortcut.deposit, HomeShortcut.transfer};
    await pumpHome(tester, isVisible: available.contains);

    final tiles = find.descendant(
      of: find.byType(QuickActionsGrid),
      matching: find.byType(InkWell),
    );
    expect(tiles, findsNWidgets(available.length));
    expect(tester.takeException(), isNull);
  });

  testWidgets('quick actions stays at 8 tiles when every shortcut is on', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(
      find.descendant(
        of: find.byType(QuickActionsGrid),
        matching: find.byType(InkWell),
      ),
      findsNWidgets(QuickActionsGrid.maxTiles),
    );
    expect(find.text('Copy Trading'), findsNothing);
  });

  testWidgets('a reserve shortcut fills the slot of a module that is off', (
    tester,
  ) async {
    await pumpHome(
      tester,
      isVisible: (s) => s != HomeShortcut.pamm && s != HomeShortcut.ibDashboard,
    );

    expect(
      find.descendant(
        of: find.byType(QuickActionsGrid),
        matching: find.byType(InkWell),
      ),
      findsNWidgets(QuickActionsGrid.maxTiles),
    );
    expect(find.text('PAMM'), findsNothing);
    expect(find.text('Copy Trading'), findsOneWidget);
    expect(find.text('Support Tickets'), findsOneWidget);
  });

  testWidgets('quick actions disappears when no shortcut is available', (
    tester,
  ) async {
    await pumpHome(tester, isVisible: (_) => false);

    expect(
      find.descendant(
        of: find.byType(QuickActionsGrid),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
  });

  testWidgets('renders SELL/BUY from priceRx without overflow at 375px', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('1.08512', findRichText: true), findsOneWidget);
    expect(find.text('1.08530', findRichText: true), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('home_sell'), findsOneWidget);
    expect(find.text('home_buy'), findsOneWidget);
  });

  testWidgets('updates prices when priceRx ticks', (tester) async {
    await pumpHome(tester);

    controller.priceRx(_symbol).value = controller
        .priceRx(_symbol)
        .value
        .copyWith(bid: 1.08600, ask: 1.08620);
    await tester.pump();

    expect(find.text('1.08600', findRichText: true), findsOneWidget);
    expect(find.text('1.08620', findRichText: true), findsOneWidget);
  });

  testWidgets('no overflow at large text scale', (tester) async {
    await pumpHome(tester, textScale: 1.6);

    expect(tester.takeException(), isNull);
    expect(find.text('Demo Contest'), findsOneWidget);
  });

  group('helpers', () {
    test('homeDisplaySymbol strips the broker suffix', () {
      expect(homeDisplaySymbol('EURUSD.c'), 'EURUSD');
      expect(homeDisplaySymbol('XAUUSD'), 'XAUUSD');
    });

    test('homeFormatSpread shows whole points', () {
      expect(homeFormatSpread(0.00018), '18');
      expect(homeFormatSpread(0.0), '0');
      expect(homeFormatSpread(12.5), '12');
    });
  });
}
