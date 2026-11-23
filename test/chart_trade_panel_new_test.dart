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
                    Row(
                      children: [
                        ChartQuantityButtonNew(
                          isIncrement: false,
                          onPressed: () {},
                        ),
                        const Expanded(child: SizedBox()),
                        ChartQuantityButtonNew(
                          isIncrement: true,
                          onPressed: () {},
                        ),
                      ],
                    ),
                    ChartPendingBarNew(
                      label: 'Pending order • SL • TP',
                      onPendingTap: () {},
                      onAlertsTap: () {},
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

  testWidgets('renders SELL/BUY, spread and pending bar at 375px', (
    tester,
  ) async {
    await tester.pumpWidget(_panel());

    expect(find.text('SELL'), findsOneWidget);
    expect(find.text('BUY'), findsOneWidget);
    expect(find.text('41'), findsOneWidget);
    expect(find.text('Pending order • SL • TP'), findsOneWidget);
    expect(find.bySemanticsLabel('Price alerts'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quantity buttons keep a 44px tap target', (tester) async {
    await tester.pumpWidget(_panel());

    final size = tester.getSize(find.byType(ChartQuantityButtonNew).first);
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  testWidgets('no overflow at large text scale', (tester) async {
    await tester.pumpWidget(_panel(textScale: 1.6));

    expect(tester.takeException(), isNull);
  });
}
