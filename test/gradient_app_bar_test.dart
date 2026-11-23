import 'package:crm_app/widgets/home/gradient_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpBar(WidgetTester tester, {required double textScale}) async {
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
              home: Scaffold(
                appBar: GradientAppBar(
                  title: 'Account settings and preferences',
                  actions: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_none_rounded),
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
  testWidgets('renders its title without overflow at 375px', (tester) async {
    await _pumpBar(tester, textScale: 1.0);

    expect(find.text('Account settings and preferences'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no overflow at 2.0 text scale', (tester) async {
    await _pumpBar(tester, textScale: 2.0);

    expect(find.byType(GradientAppBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
