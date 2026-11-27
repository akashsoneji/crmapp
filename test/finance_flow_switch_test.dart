import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crm_app/flavor_config.dart';
import 'package:crm_app/screens/finance_v2/finance_flow_switch.dart';
import 'package:crm_app/screens/finance_v2/presentation/deposit/deposit_type_screen.dart';
import 'package:crm_app/screens/finance_v2/presentation/withdrawal/withdrawal_type_screen.dart';

void _useFlavor({bool? newFlow}) {
  FlavorConfig.reset();
  const color = Color(0xFF000000);
  if (newFlow == null) {
    FlavorConfig(
      flavor: Flavor.tenax,
      appName: 'tenax',
      appTitle: 'tenax',
      primaryColor: color,
      secondaryColor: color,
      accentColor: color,
      apiBaseUrl: '',
      websocketUrl: '',
      chartBaseUrl: '',
      appIconPath: '',
      svgLogoPath: '',
      splashLogoPath: '',
    );
    return;
  }
  FlavorConfig(
    flavor: Flavor.tenax,
    appName: 'tenax',
    appTitle: 'tenax',
    primaryColor: color,
    secondaryColor: color,
    accentColor: color,
    apiBaseUrl: '',
    websocketUrl: '',
    chartBaseUrl: '',
    appIconPath: '',
    svgLogoPath: '',
    splashLogoPath: '',
    useNewDepositWithdrawFlow: newFlow,
  );
}

void main() {
  tearDown(FlavorConfig.reset);

  group('FinanceFlowSwitch with the flag off', () {
    setUp(() => _useFlavor(newFlow: false));

    test('deposit returns the legacy widget itself', () {
      const legacy = Text('old deposit');
      final result = FinanceFlowSwitch.deposit(
        accountNumber: '1001',
        legacy: () => legacy,
      );
      expect(identical(result, legacy), isTrue);
    });

    test('withdrawal returns the legacy widget itself', () {
      const legacy = Text('old withdrawal');
      final result = FinanceFlowSwitch.withdrawal(
        accountNumber: '1001',
        legacy: () => legacy,
      );
      expect(identical(result, legacy), isTrue);
    });
  });

  group('FinanceFlowSwitch with the flag on', () {
    setUp(() => _useFlavor(newFlow: true));

    test('deposit opens the new type screen and never builds the old one', () {
      var legacyBuilt = false;
      final result = FinanceFlowSwitch.deposit(
        accountNumber: '1001',
        legacy: () {
          legacyBuilt = true;
          return const Text('old deposit');
        },
      );
      expect(result, isA<DepositTypeScreen>());
      expect((result as DepositTypeScreen).accountNumber, '1001');
      expect(legacyBuilt, isFalse);
    });

    test('withdrawal opens the new type screen with the account', () {
      var legacyBuilt = false;
      final result = FinanceFlowSwitch.withdrawal(
        accountNumber: '1001',
        legacy: () {
          legacyBuilt = true;
          return const Text('old withdrawal');
        },
      );
      expect(result, isA<WithdrawalTypeScreen>());
      expect((result as WithdrawalTypeScreen).accountNumber, '1001');
      expect(legacyBuilt, isFalse);
    });
  });

  test('a flavor that does not set the flag stays on the legacy flow', () {
    _useFlavor();
    expect(FinanceFlowSwitch.useNewFlow, isFalse);
  });

  group('flag comes from the client config', () {
    test('tenax clients turn the new flow on', () {
      expect(FlavorConfig.tenax.useNewDepositWithdrawFlow, isTrue);
      FlavorConfig.reset();
      expect(FlavorConfig.tenax3.useNewDepositWithdrawFlow, isTrue);
      FlavorConfig.reset();
      expect(FlavorConfig.tenaxnew.useNewDepositWithdrawFlow, isTrue);
    });

    test('other clients keep the legacy flow', () {
      expect(FlavorConfig.pipze.useNewDepositWithdrawFlow, isFalse);
      FlavorConfig.reset();
      expect(FlavorConfig.gtxprime.useNewDepositWithdrawFlow, isFalse);
      FlavorConfig.reset();
      expect(FlavorConfig.goldenwolffx.useNewDepositWithdrawFlow, isFalse);
    });

    test('a broker runtime config can override the client value', () {
      FlavorConfig.pipze;
      FlavorConfig.applyTenaxBrokerRuntimeConfig(
        config: {'useNewDepositWithdrawFlow': true},
      );
      expect(FinanceFlowSwitch.useNewFlow, isTrue);
    });
  });
}
