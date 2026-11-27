import 'package:crm_app/widgets/pending_order/pending_order_widgets_new.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {double textScale = 1.0}) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    builder:
        (_, _) => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(375, 812),
              textScaler: TextScaler.linear(textScale),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ),
        ),
  );
}

void main() {
  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(375, 812);
    view.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('segmented control shows every option and reports the index', (
    tester,
  ) async {
    int? picked;
    await tester.pumpWidget(
      _host(
        PendingSegmentedNew(
          options: const ['Limit', 'Stop', 'Stop Limit'],
          selectedIndex: 0,
          height: 36,
          thumbColor: Colors.white,
          selectedTextColor: Colors.black,
          onSelected: (index) => picked = index,
        ),
      ),
    );

    expect(find.text('Limit'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
    await tester.tap(find.text('Stop Limit'));
    expect(picked, 2);
    expect(tester.getSize(find.byType(PendingSegmentedNew)).height, 36);
  });

  testWidgets('stepper field calls − and + with compact height', (
    tester,
  ) async {
    var decrements = 0;
    var increments = 0;
    final controller = TextEditingController(text: '0.01');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _host(
        PendingStepperFieldNew(
          caption: 'Price',
          semanticsName: 'price',
          controller: controller,
          onDecrement: () => decrements++,
          onIncrement: () => increments++,
        ),
      ),
    );

    final minus = find.bySemanticsLabel('Decrease price');
    final plus = find.bySemanticsLabel('Increase price');
    await tester.tap(minus);
    await tester.tap(plus);
    await tester.tap(plus);
    expect(decrements, 1);
    expect(increments, 2);
    expect(tester.getSize(minus).height, greaterThanOrEqualTo(40));
    expect(
      tester.getSize(find.byType(PendingStepperFieldNew)).height,
      lessThanOrEqualTo(48),
    );
  });

  testWidgets('chart card toggles and hides its body when collapsed', (
    tester,
  ) async {
    var expanded = true;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return _host(
            PendingChartCardNew(
              expanded: expanded,
              chartHeight: 200,
              onToggle: () => setState(() => expanded = !expanded),
              chart: const Text('chart-body'),
            ),
          );
        },
      ),
    );

    expect(find.text('Hide'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Hide chart'));
    await tester.pumpAndSettle();
    expect(expanded, isFalse);
    expect(find.text('Show'), findsOneWidget);
    expect(
      tester.getSize(find.byType(PendingChartCardNew)).height,
      lessThan(60),
    );
  });

  testWidgets('TP/SL card shows "Not set" when switched off', (tester) async {
    var enabled = true;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return _host(
            PendingTpSlCardNew(
              title: 'Take Profit',
              isTakeProfit: true,
              enabled: enabled,
              onToggle: (value) => setState(() => enabled = value),
              footer: const Text('tp-pnl'),
              child: const Text('tp-field'),
            ),
          );
        },
      ),
    );

    expect(find.text('tp-field'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(enabled, isFalse);
    expect(find.text('tp-field'), findsNothing);
    expect(find.text('Not set'), findsOneWidget);
  });

  testWidgets('place button is disabled while loading', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        PendingPlaceButtonNew(
          label: 'Place Buy Limit',
          isSell: false,
          enabled: true,
          isLoading: true,
          onPressed: () => taps++,
        ),
      ),
    );

    expect(find.text('Processing...'), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton));
    expect(taps, 0);
    expect(tester.getSize(find.byType(ElevatedButton)).height, 44);
  });

  testWidgets('no overflow at large text scale, side-by-side TP/SL', (
    tester,
  ) async {
    final tp = TextEditingController(text: '3425.15');
    final sl = TextEditingController(text: '3401.80');
    addTearDown(tp.dispose);
    addTearDown(sl.dispose);

    await tester.pumpWidget(
      _host(
        Column(
          children: [
            PendingSegmentedNew(
              options: const ['SELL', 'BUY'],
              selectedIndex: 0,
              height: 40,
              thumbColor: Colors.red,
              selectedTextColor: Colors.white,
              onSelected: (_) {},
            ),
            const PendingQuoteBarNew(bid: '3425.15', ask: '3425.56'),
            const PendingValidationNoteNew(
              message: 'Trigger price should be below 1.08512',
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (title, controller, isTp) in [
                  ('Take Profit', tp, true),
                  ('Stop Loss', sl, false),
                ])
                  Expanded(
                    child: PendingTpSlCardNew(
                      title: title,
                      isTakeProfit: isTp,
                      enabled: true,
                      onToggle: (_) {},
                      footer: const PendingPnLLineNew(
                        label: 'Est. profit',
                        value: r'$124.50',
                        color: Colors.green,
                      ),
                      child: PendingStepperFieldNew(
                        semanticsName: title,
                        controller: controller,
                        onDecrement: () {},
                        onIncrement: () {},
                      ),
                    ),
                  ),
              ],
            ),
            const PendingOrderSummaryNew(
              orderType: 'Sell Stop Limit',
              volume: '0.01',
              price: '3425.15',
              isSell: true,
            ),
          ],
        ),
        textScale: 1.6,
      ),
    );

    expect(tester.takeException(), isNull);
  });

  group('adaptive TP/SL pair', () {
    late TextEditingController tp;
    late TextEditingController sl;

    setUp(() {
      tp = TextEditingController();
      sl = TextEditingController();
    });

    tearDown(() {
      tp.dispose();
      sl.dispose();
    });

    Widget card(String title, TextEditingController controller) {
      return PendingTpSlCardNew(
        key: ValueKey(title),
        title: title,
        isTakeProfit: title == 'Take Profit',
        enabled: true,
        onToggle: (_) {},
        footer: const PendingPnLLineNew(
          label: 'Est. profit',
          value: r'$1,234.56',
          color: Colors.green,
        ),
        child: PendingStepperFieldNew(
          semanticsName: title,
          controller: controller,
          onDecrement: () {},
          onIncrement: () {},
        ),
      );
    }

    Future<void> pumpPair(
      WidgetTester tester, {
      required String price,
      double textScale = 1.0,
    }) async {
      tp.text = price;
      sl.text = price;
      await tester.pumpWidget(
        _host(
          PendingAdaptivePairNew(
            sampleValue: price,
            itemChrome: 26,
            first: card('Take Profit', tp),
            second: card('Stop Loss', sl),
          ),
          textScale: textScale,
        ),
      );
      await tester.pumpAndSettle();
    }

    double top(WidgetTester tester, String title) =>
        tester.getTopLeft(find.byKey(ValueKey(title))).dy;

    testWidgets('short price stays side by side', (tester) async {
      await pumpPair(tester, price: '1.1');

      expect(top(tester, 'Stop Loss'), top(tester, 'Take Profit'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('long price stacks full width instead of clipping', (
      tester,
    ) async {
      await pumpPair(tester, price: '102345.670');

      expect(top(tester, 'Stop Loss'), greaterThan(top(tester, 'Take Profit')));
      expect(
        tester.getSize(find.byKey(const ValueKey('Take Profit'))).width,
        closeTo(343, 1),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('large text size stacks even a short price', (tester) async {
      await pumpPair(tester, price: '1.1', textScale: 2.0);

      expect(top(tester, 'Stop Loss'), greaterThan(top(tester, 'Take Profit')));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('long P&L amount wraps under its label without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 140,
          child: PendingPnLLineNew(
            label: 'Est. profit',
            value: r'$1,234.56',
            color: Colors.green,
          ),
        ),
      ),
    );

    expect(find.text(r'$1,234.56'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(r'$1,234.56')).dy,
      greaterThan(tester.getTopLeft(find.text('Est. profit')).dy),
    );
    expect(tester.takeException(), isNull);
  });
}
