import 'package:crm_app/flavor_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(FlavorConfig.reset);

  group('tenaxnew flavor', () {
    test('uses the new home design and the TenaxNew config values', () {
      final config = FlavorConfig.tenaxnew;

      expect(config.flavor, Flavor.tenaxnew);
      expect(FlavorConfig.usesNewHomeDesign, isTrue);
      expect(config.appName, 'Tenax');
      expect(config.appTitle, 'Tenax Code');
      expect(config.apiBaseUrl, 'https://dev.tenaxcodecrm.com/api/');
      expect(config.websocketUrl, 'wss://dev.tenaxcodecrm.com/trade-engine');
      expect(config.chartBaseUrl, 'https://dev.tenaxcodecrm.com');
      expect(config.svgLogoPath, contains('tenaxnew'));
    });

    test('keeps Tenax-family behaviour', () {
      FlavorConfig.tenaxnew;

      expect(FlavorConfig.isTenax(), isTrue);
      expect(FlavorConfig.isTenaxNew(), isTrue);
      expect(FlavorConfig.usesSingleStreamSocket, isTrue);
      expect(FlavorConfig.isMultiBrokerEnabled, isFalse);
    });
  });

  group('old flavors keep the old home design', () {
    test('tenax', () {
      FlavorConfig.tenax;
      expect(FlavorConfig.usesNewHomeDesign, isFalse);
      expect(FlavorConfig.isTenaxNew(), isFalse);
    });

    test('tenax3', () {
      FlavorConfig.tenax3;
      expect(FlavorConfig.usesNewHomeDesign, isFalse);
    });

    test('pipze', () {
      FlavorConfig.pipze;
      expect(FlavorConfig.usesNewHomeDesign, isFalse);
    });
  });
}
