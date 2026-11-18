import 'package:crm_app/widgets/chart/landscape_chart_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _openKey = ValueKey('open');
const _exitKey = ValueKey('exit');
const _plusKey = ValueKey('plus');
const _lotKey = ValueKey('lot');
const _symbolKey = ValueKey('symbol');

class _Harness {
  final isOpen = ValueNotifier<bool>(false);
  final lot = ValueNotifier<double>(0.01);
  final chartKey = GlobalKey();

  Widget chart() => ColoredBox(key: chartKey, color: Colors.blue);

  Widget build() {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: isOpen,
                builder:
                    (_, open, _) => open ? const SizedBox.shrink() : chart(),
              ),
            ),
            Builder(
              builder:
                  (context) => TextButton(
                    key: _openKey,
                    onPressed:
                        () => openLandscapeChartPage(
                          context: context,
                          isOpen: isOpen,
                          backgroundColor: Colors.white,
                          chartBuilder: (_) => chart(),
                          toolbarBuilder: _toolbar,
                          symbolPickerBuilder:
                              (_, close) => ListView(
                                children: [
                                  ListTile(
                                    title: const Text('EURUSD'),
                                    onTap: close,
                                  ),
                                ],
                              ),
                        ),
                    child: const Text('open'),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Same shape as the real top bar: minimize, symbol, SELL, −/lot/+, BUY.
  Widget _toolbar(BuildContext pageContext, VoidCallback openPicker) {
    return SizedBox(
      height: 52,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: InkWell(
              key: _exitKey,
              onTap: () => Navigator.of(pageContext).maybePop(),
              child: const Icon(Icons.fullscreen_exit),
            ),
          ),
          SizedBox(
            width: 116,
            child: InkWell(
              key: _symbolKey,
              onTap: openPicker,
              child: const Text('XAUUSD'),
            ),
          ),
          const Expanded(child: ColoredBox(color: Colors.red)),
          SizedBox(
            width: 36,
            child: InkWell(
              key: _plusKey,
              onTap: () => lot.value = lot.value + 0.01,
              child: const Icon(Icons.add),
            ),
          ),
          ValueListenableBuilder<double>(
            valueListenable: lot,
            builder: (_, value, _) => Text(value.toStringAsFixed(2), key: _lotKey),
          ),
          const Expanded(child: ColoredBox(color: Colors.green)),
        ],
      ),
    );
  }
}

void main() {
  final platformCalls = <MethodCall>[];

  setUp(() {
    platformCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          platformCalls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  void usePortraitView(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Finder chartInPage(_Harness harness) => find.descendant(
    of: find.byType(LandscapeChartPage),
    matching: find.byKey(harness.chartKey),
  );

  double coverOpacity(WidgetTester tester) =>
      tester
          .widget<AnimatedOpacity>(find.byKey(LandscapeChartPage.chartCoverKey))
          .opacity;

  bool requestedLandscape() => platformCalls.any(
    (call) =>
        call.method == 'SystemChrome.setPreferredOrientations' &&
        call.arguments.toString().toLowerCase().contains('landscape'),
  );

  Future<void> openAndSwing(WidgetTester tester) async {
    await tester.tap(find.byKey(_openKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
  }

  testWidgets('opens without rotating the device and moves the chart in only '
      'after the swing', (tester) async {
    usePortraitView(tester, const Size(360, 740));
    final harness = _Harness();
    await tester.pumpWidget(harness.build());

    await tester.tap(find.byKey(_openKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(harness.isOpen.value, isFalse);
    expect(chartInPage(harness), findsNothing);
    expect(find.byKey(harness.chartKey), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();

    expect(harness.isOpen.value, isTrue);
    expect(chartInPage(harness), findsOneWidget);
    expect(coverOpacity(tester), 1);

    await tester.pump(landscapeChartRedrawDelay);
    await tester.pump(landscapeCoverFadeDuration);
    expect(coverOpacity(tester), 0);

    final pageContext = tester.element(find.byType(LandscapeChartPage));
    expect(MediaQuery.sizeOf(pageContext), const Size(740, 360));
    expect(requestedLandscape(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('+ changes the lot shown on the page', (tester) async {
    usePortraitView(tester, const Size(360, 740));
    final harness = _Harness();
    await tester.pumpWidget(harness.build());
    await openAndSwing(tester);

    expect(tester.widget<Text>(find.byKey(_lotKey)).data, '0.01');
    await tester.tap(find.byKey(_plusKey));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(_lotKey)).data, '0.02');
  });

  testWidgets('exit covers the chart, hands it back, then swings out', (
    tester,
  ) async {
    usePortraitView(tester, const Size(360, 740));
    final harness = _Harness();
    await tester.pumpWidget(harness.build());
    await openAndSwing(tester);
    await tester.pump(landscapeChartRedrawDelay);
    await tester.pump(landscapeCoverFadeDuration);
    expect(coverOpacity(tester), 0);

    await tester.tap(find.byKey(_exitKey));
    await tester.pump();
    expect(coverOpacity(tester), 1);
    expect(harness.isOpen.value, isTrue);

    await tester.pump(const Duration(milliseconds: 260));
    expect(harness.isOpen.value, isFalse);
    expect(find.byType(LandscapeChartPage), findsOneWidget);
    expect(chartInPage(harness), findsNothing);
    expect(find.byKey(harness.chartKey), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(LandscapeChartPage), findsNothing);
    expect(find.byKey(harness.chartKey), findsOneWidget);
    expect(requestedLandscape(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('system back closes the symbol picker before the page', (
    tester,
  ) async {
    usePortraitView(tester, const Size(360, 740));
    final harness = _Harness();
    await tester.pumpWidget(harness.build());
    await openAndSwing(tester);

    await tester.tap(find.byKey(_symbolKey));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AnimatedSlide>(find.byKey(LandscapeChartPage.symbolPickerKey))
          .offset,
      Offset.zero,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AnimatedSlide>(find.byKey(LandscapeChartPage.symbolPickerKey))
          .offset,
      const Offset(1, 0),
    );
    expect(find.byType(LandscapeChartPage), findsOneWidget);
    expect(harness.isOpen.value, isTrue);
  });

  testWidgets('a double tap opens only one page', (tester) async {
    usePortraitView(tester, const Size(360, 740));
    final harness = _Harness();
    await tester.pumpWidget(harness.build());

    await tester.tap(find.byKey(_openKey));
    await tester.tap(find.byKey(_openKey), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(LandscapeChartPage), findsOneWidget);
  });

  for (final portrait in const [Size(360, 740), Size(340, 800)]) {
    testWidgets('lays out without overflow at ${portrait.flipped}', (
      tester,
    ) async {
      usePortraitView(tester, portrait);
      final harness = _Harness();
      await tester.pumpWidget(harness.build());
      await openAndSwing(tester);
      await tester.pumpAndSettle();

      final pageContext = tester.element(find.byType(LandscapeChartPage));
      expect(MediaQuery.sizeOf(pageContext), portrait.flipped);
      expect(tester.takeException(), isNull);
    });
  }
}
