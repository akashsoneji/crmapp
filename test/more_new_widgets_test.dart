import 'package:crm_app/widgets/more/more_new_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

MoreProfileHero _hero({
  required VoidCallback onProfileTap,
  VoidCallback? onSwitchAccount,
  VoidCallback? onDeposit,
  int completion = 60,
}) {
  return MoreProfileHero(
    name: 'Akash Soneji',
    email: 'akash@example.com',
    initials: 'AS',
    brokerName: 'Tenax',
    isFullyVerified: completion == 100,
    completion: completion,
    isProfileVerified: false,
    onProfileTap: onProfileTap,
    onSwitchAccount: onSwitchAccount,
    quickActions: [
      MoreQuickAction(
        svgIcon: 'deposit',
        label: 'Deposit',
        onTap: onDeposit ?? () {},
      ),
      MoreQuickAction(svgIcon: 'withdrawal', label: 'Withdraw', onTap: () {}),
      MoreQuickAction(
        svgIcon: 'internal-transfer',
        label: 'Transfer',
        onTap: () {},
      ),
      MoreQuickAction(svgIcon: 'clock', label: 'History', onTap: () {}),
    ],
  );
}

void main() {
  testWidgets('hero shows identity, completion and fires its callbacks', (
    tester,
  ) async {
    var profileTaps = 0;
    var switchTaps = 0;
    var depositTaps = 0;
    await _pump(
      tester,
      _hero(
        onProfileTap: () => profileTaps++,
        onSwitchAccount: () => switchTaps++,
        onDeposit: () => depositTaps++,
      ),
    );

    expect(find.text('Akash Soneji'), findsOneWidget);
    expect(find.text('akash@example.com'), findsOneWidget);
    expect(find.text('Tenax'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit profile'));
    await tester.tap(find.byTooltip('Switch account'));
    await tester.tap(find.text('Deposit'));
    expect(profileTaps, 1);
    expect(switchTaps, 1);
    expect(depositTaps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hero hides switch account when no callback and shows Verified', (
    tester,
  ) async {
    await _pump(tester, _hero(onProfileTap: () {}, completion: 100));

    expect(find.byTooltip('Switch account'), findsNothing);
    expect(find.text('Verified'), findsOneWidget);
  });

  testWidgets('feature grid lays out three per row and routes taps', (
    tester,
  ) async {
    final tapped = <String>[];
    final labels = ['Finance', 'Dashboard', 'Copy Trading', 'Notifications'];
    await _pump(
      tester,
      MoreFeatureGrid(
        items: [
          for (final label in labels)
            MoreFeatureItem(
              svgIcon: '',
              materialIcon: Icons.circle,
              label: label,
              onTap: () => tapped.add(label),
            ),
        ],
      ),
    );

    Offset tileTop(String label) => tester.getTopLeft(
      find.ancestor(of: find.text(label), matching: find.byType(InkWell)),
    );
    final first = tileTop('Finance');
    final third = tileTop('Copy Trading');
    final fourth = tileTop('Notifications');
    expect(third.dy, closeTo(first.dy, 1));
    expect(fourth.dy, greaterThan(first.dy));

    await tester.tap(find.text('Notifications'));
    expect(tapped, ['Notifications']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings group renders rows and logout button fires', (
    tester,
  ) async {
    var logoutTaps = 0;
    var rowTaps = 0;
    await _pump(
      tester,
      Column(
        children: [
          MoreSettingsGroup(
            children: [
              MoreSettingsRow(
                svgIcon: '',
                materialIcon: Icons.settings,
                label: 'App Settings',
                onTap: () => rowTaps++,
              ),
              MoreSettingsRow(
                svgIcon: '',
                materialIcon: Icons.delete_outline,
                label: 'Delete Account',
                onTap: () {},
                isDestructive: true,
              ),
            ],
          ),
          MoreLogoutButton(label: 'Logout', onTap: () => logoutTaps++),
        ],
      ),
    );

    expect(find.byType(Divider), findsOneWidget);
    await tester.tap(find.text('App Settings'));
    await tester.tap(find.text('Logout'));
    expect(rowTaps, 1);
    expect(logoutTaps, 1);
    expect(tester.takeException(), isNull);
  });
}
