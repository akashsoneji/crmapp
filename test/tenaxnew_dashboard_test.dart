import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/services/theme_service.dart';
import 'package:crm_app/widgets/brand_logo.dart';
import 'package:crm_app/widgets/dashboard/dashboard_new_widgets.dart';
import 'package:crm_app/widgets/trading_bottom_navigation_new.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakeTheme extends ThemeService {
  @override
  bool get isDarkMode => false;

  // Skips the secure-storage restore and binding observer.
  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  // ignore: must_call_super
  void onClose() {}
}

class _FakeLanguage extends LanguageService {
  static const _strings = {'dashboard_title': 'Dashboard'};

  // Skips loading translation assets from storage.
  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  String tr(String key, [Map<String, String>? args]) => _strings[key] ?? key;

  @override
  String trf(String key, String fallback, [Map<String, String>? args]) =>
      _strings[key] ?? fallback;
}

Widget _host(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (_, _) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

DashboardAccountCardNew _card({
  required List<String> taps,
  bool isPrimary = false,
  bool isScratchCard = false,
}) {
  return DashboardAccountCardNew(
    accountNumber: '100234',
    accountTypeLabel: 'Live',
    isLive: true,
    groupName: 'real\\standard',
    isScratchCard: isScratchCard,
    activeLabel: isPrimary ? 'Active' : null,
    metrics: const [
      DashboardAccountMetric(label: 'Equity', value: '\$1,250.00'),
      DashboardAccountMetric(label: 'Balance', value: '\$1,200.00'),
      DashboardAccountMetric(label: 'Total P/L', value: '\$50.00'),
    ],
    actions: [
      DashboardAccountAction(
        label: 'Trade',
        svgAsset: 'assets/svg/bottom_navigation/candle_bold.svg',
        color: Colors.purple,
        onTap: () => taps.add('trade'),
      ),
      DashboardAccountAction(
        label: 'Deposit',
        svgAsset: 'assets/svg/deshboard/money-recive.svg',
        color: Colors.green,
        onTap: () => taps.add('deposit'),
      ),
      DashboardAccountAction(
        label: 'Withdraw',
        svgAsset: 'assets/svg/deshboard/money-send.svg',
        color: Colors.red,
        onTap: () => taps.add('withdraw'),
      ),
    ],
    infoTooltip: 'Account info',
    onInfo: () => taps.add('info'),
    menuTooltip: 'More options',
    onMenu: () => taps.add('menu'),
    switchLabel: isPrimary ? null : 'Switch to trade',
    onSwitch: isPrimary ? null : () => taps.add('switch'),
  );
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<ThemeService>(_FakeTheme());
    Get.put<LanguageService>(_FakeLanguage());
  });

  tearDown(Get.reset);

  void useSmallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('fourth bottom tab is Dashboard, not Square', (tester) async {
    useSmallPhone(tester);
    final tapped = <int>[];

    await tester.pumpWidget(
      _host(TradingBottomNavigationNew(currentIndex: 0, onTap: tapped.add)),
    );

    expect(find.text('Square'), findsNothing);
    await tester.tap(find.text('Dashboard'));
    expect(tapped, [3]);
  });

  testWidgets('account card shows metrics and routes every action', (
    tester,
  ) async {
    useSmallPhone(tester);
    final taps = <String>[];

    await tester.pumpWidget(_host(_card(taps: taps)));

    expect(find.text('100234'), findsOneWidget);
    expect(find.text('\$1,250.00'), findsOneWidget);
    expect(find.text('Active'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Trade'));
    await tester.tap(find.text('Deposit'));
    await tester.tap(find.text('Withdraw'));
    await tester.tap(find.text('Switch to trade'));
    await tester.tap(find.byTooltip('Account info'));
    await tester.tap(find.byTooltip('More options'));

    expect(taps, ['trade', 'deposit', 'withdraw', 'switch', 'info', 'menu']);
  });

  testWidgets('active account shows the chip and no switch button', (
    tester,
  ) async {
    useSmallPhone(tester);

    await tester.pumpWidget(_host(_card(taps: [], isPrimary: true)));

    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Switch to trade'), findsNothing);
  });

  testWidgets('scratch-card account shows the scratch icon', (tester) async {
    useSmallPhone(tester);
    final scratchIcon = find.byWidgetPredicate(
      (widget) =>
          widget is BrandLogo && widget.source == 'assets/svg/more/scratch.svg',
    );

    await tester.pumpWidget(_host(_card(taps: [], isScratchCard: true)));
    expect(scratchIcon, findsOneWidget);

    await tester.pumpWidget(_host(_card(taps: [])));
    expect(scratchIcon, findsNothing);
  });

  testWidgets('empty state offers real and demo accounts', (tester) async {
    useSmallPhone(tester);
    final taps = <String>[];

    await tester.pumpWidget(
      _host(
        DashboardEmptyStateNew(
          illustration: const SizedBox.square(dimension: 64),
          title: 'Open your first account',
          description: 'Start trading with a real or demo account.',
          realLabel: 'Open Real Account',
          onOpenReal: () => taps.add('real'),
          demoLabel: 'Open Demo Account',
          onOpenDemo: () => taps.add('demo'),
        ),
      ),
    );

    await tester.tap(find.text('Open Real Account'));
    await tester.tap(find.text('Open Demo Account'));
    expect(taps, ['real', 'demo']);
    expect(tester.takeException(), isNull);
  });
}
