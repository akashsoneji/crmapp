import 'package:crm_app/widgets/positions/positions_new_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder:
          (_, _) => MediaQuery(
            data: MediaQueryData(
              size: const Size(375, 812),
              textScaler: TextScaler.linear(textScale),
            ),
            child: MaterialApp(
              home: Scaffold(body: SingleChildScrollView(child: child)),
            ),
          ),
    ),
  );
}

void main() {
  testWidgets('tab switcher shows counts and reports the tapped tab', (
    tester,
  ) async {
    int? tapped;
    await _pump(
      tester,
      PositionsTabSwitcher(
        selectedIndex: 0,
        onSelected: (index) => tapped = index,
        tabs: const [
          PositionsTabData(label: 'Market', count: 3),
          PositionsTabData(label: 'Pending', count: 0),
          PositionsTabData(label: 'History'),
        ],
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.text('History'));
    expect(tapped, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('metrics card shows hero and every remaining metric', (
    tester,
  ) async {
    await _pump(
      tester,
      const PositionsMetricsCard(
        hero: PositionsMetric(label: 'Equity', value: '719.59'),
        items: [
          PositionsMetric(label: 'Balance', value: '669.59'),
          PositionsMetric(label: 'Credit', value: '50.00'),
          PositionsMetric(label: 'Margin', value: '0.00'),
          PositionsMetric(label: 'Free Margin', value: '719.59'),
          PositionsMetric(
            label: 'Margin Level (%)',
            value: '0.00',
            valueColor: Colors.red,
          ),
        ],
      ),
      textScale: 1.3,
    );

    for (final label in [
      'Equity',
      'Balance',
      'Credit',
      'Margin',
      'Free Margin',
      'Margin Level (%)',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('719.59'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty state renders its message', (tester) async {
    await _pump(
      tester,
      const PositionsEmptyState(
        illustration: SizedBox(width: 100, height: 100),
        message: 'You have no data',
      ),
    );

    expect(find.text('You have no data'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('trade card shows symbol, side, prices and value', (
    tester,
  ) async {
    await _pump(
      tester,
      const PositionTradeCard(
        symbol: 'EURUSD',
        isBuy: true,
        sideLabel: 'buy 0.01',
        priceRange: '1.08550 -> 1.08612',
        value: '0.62',
        valueColor: Colors.green,
      ),
      textScale: 1.3,
    );

    expect(find.text('EURUSD'), findsOneWidget);
    expect(find.text('buy 0.01'), findsOneWidget);
    expect(find.text('1.08550 -> 1.08612'), findsOneWidget);
    expect(find.text('0.62'), findsOneWidget);
    expect(find.byIcon(Icons.expand_more), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history trade card shows caption, chevron and expanded body', (
    tester,
  ) async {
    await _pump(
      tester,
      const PositionTradeCard(
        symbol: 'XAUUSD',
        isBuy: false,
        sideLabel: 'sell 1.00',
        priceRange: '2350.10 -> 2348.00',
        caption: '27 Nov 10:20',
        value: '\$210.00',
        valueColor: Colors.green,
        isExpanded: true,
        expandedChild: Text('details'),
      ),
    );

    expect(find.text('27 Nov 10:20'), findsOneWidget);
    expect(find.byIcon(Icons.expand_less), findsOneWidget);
    expect(find.text('details'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('select option taps when enabled and ignores taps when not', (
    tester,
  ) async {
    var taps = 0;
    await _pump(
      tester,
      Column(
        children: [
          const PositionsSheetHeader(
            title: 'Close positions',
            subtitle: 'Which positions would you like to close?',
          ),
          PositionsSelectOption(
            label: 'All profitable',
            selected: true,
            onTap: () => taps++,
            trailing: const Text('\$0.05'),
          ),
          const PositionsSelectOption(
            label: 'All losing',
            selected: false,
            onTap: null,
          ),
        ],
      ),
      textScale: 1.3,
    );

    await tester.tap(find.text('All profitable'));
    await tester.tap(find.text('All losing'));
    expect(taps, 1);
    expect(find.text('\$0.05'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('metrics card puts filter buttons in the free grid cell', (
    tester,
  ) async {
    var taps = 0;
    await _pump(
      tester,
      PositionsMetricsCard(
        hero: const PositionsMetric(label: 'Profit', value: '12.00'),
        items: const [
          PositionsMetric(label: 'Deposit', value: '0.00'),
          PositionsMetric(label: 'Withdrawal', value: '0.00'),
          PositionsMetric(label: 'Swap', value: '0.00'),
          PositionsMetric(label: 'Commission', value: '0.00'),
          PositionsMetric(label: 'Balance', value: '100.00'),
        ],
        trailing: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerEnd,
          child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final name in ['Date', 'Instruments', 'Direction', 'Reset'])
              PositionsFilterIconButton(
                tooltip: name,
                active: name == 'Date',
                badgeCount: name == 'Date' ? 3 : null,
                onTap: () => taps++,
                iconBuilder: (color) => Icon(Icons.tune, color: color),
              ),
          ],
          ),
        ),
      ),
      textScale: 1.3,
    );

    // All four stay on one line, so the card does not grow a row.
    expect(
      tester.getCenter(find.byTooltip('Reset')).dy,
      moreOrLessEquals(tester.getCenter(find.byTooltip('Date')).dy),
    );

    final balanceRow = tester.getCenter(find.text('Balance')).dy;
    final dateButton = tester.getCenter(find.byTooltip('Date'));
    expect((dateButton.dy - balanceRow).abs(), lessThan(40));
    expect(
      dateButton.dx,
      greaterThan(tester.getCenter(find.text('Balance')).dx),
    );
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.byTooltip('Direction'));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('action tile and filter chip report taps', (tester) async {
    var actionTaps = 0;
    var chipTaps = 0;
    await _pump(
      tester,
      Column(
        children: [
          PositionsActionTile(
            icon: Icons.close,
            title: 'Close / Modify Position',
            subtitle: 'Close / Modify this position immediately',
            color: Colors.red,
            onTap: () => actionTaps++,
          ),
          Row(
            children: [
              Expanded(
                child: PositionsFilterChip(
                  label: 'Last Month',
                  selected: false,
                  onTap: () => chipTaps++,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    await tester.tap(find.text('Close / Modify Position'));
    await tester.tap(find.text('Last Month'));
    expect(actionTaps, 1);
    expect(chipTaps, 1);
    expect(tester.takeException(), isNull);
  });
}
