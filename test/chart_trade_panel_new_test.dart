import 'package:crm_app/widgets/home/chart_trade_panel_new.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _panel({double textScale = 1.0}) {
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
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Row(
                          children: const [
                            Expanded(
                              child: ChartTradeTileNew(
                                isSell: true,
                                price: '3425.15',
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: ChartTradeTileNew(
                                isSell: false,
                                price: '3425.56',
                              ),
                            ),
                          ],
                        ),
                        const Align(child: ChartSpreadChipNew(spread: '41')),
                      ],
                    ),
                    // Same shape as the chart dock's quantity row.
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              ChartQuantityButtonNew(
                                isIncrement: false,
                                onPressed: () {},
                              ),
                              const Expanded(
                                child: Text(
                                  '0.01',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              ChartQuantityButtonNew(
                                isIncrement: true,
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                        ChartTradeActionsNew(
                          onPendingTap: () {},
                          onAlertsTap: () {},
                          onFullscreenTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
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

  testWidgets('renders SELL/BUY, spread and the three actions at 375px', (
    tester,
  ) async {
    await tester.pumpWidget(_panel());

    expect(find.text('SELL'), findsOneWidget);
    expect(find.text('BUY'), findsOneWidget);
    expect(find.text('41'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Pending order, stop loss and take profit'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Price alerts'), findsOneWidget);
    expect(find.bySemanticsLabel('Full screen chart'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quantity buttons keep a 44px tap target', (tester) async {
    await tester.pumpWidget(_panel());

    final size = tester.getSize(find.byType(ChartQuantityButtonNew).first);
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  testWidgets('trade dock renders its sections without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder:
            (_, _) => const MaterialApp(
              home: Scaffold(
                body: ChartTradeDockNew(
                  children: [
                    ChartTradeTileNew(isSell: true, price: '1.08512'),
                    ChartSpreadChipNew(spread: '12'),
                  ],
                ),
              ),
            ),
      ),
    );

    expect(find.text('SELL'), findsOneWidget);
    expect(find.bySemanticsLabel('Spread 12'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending button is outlined with no fill', (tester) async {
    await tester.pumpWidget(_panel());

    final pending = find.bySemanticsLabel(
      'Pending order, stop loss and take profit',
    );
    final ink = tester.widget<Ink>(
      find.descendant(of: pending, matching: find.byType(Ink)).first,
    );
    final decoration = ink.decoration! as BoxDecoration;
    expect(decoration.gradient, isNull);
    expect(decoration.color, Colors.transparent);
    expect(decoration.border, isNotNull);
  });

  testWidgets('no overflow at large text scale', (tester) async {
    await tester.pumpWidget(_panel(textScale: 1.6));

    expect(tester.takeException(), isNull);
  });
}
