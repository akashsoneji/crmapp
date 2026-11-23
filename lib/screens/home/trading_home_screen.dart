import 'package:flutter/material.dart';
import 'package:crm_app/flavor_config.dart';

import 'trading_main_screen.dart';
import 'trading_main_screen_new.dart';

/// Entry point for the trading tabs shell. Flavors on the new home design
/// ([FlavorConfig.usesNewHomeDesign]) get [TradingMainScreenNew]; every other
/// flavor keeps the original [TradingMainScreen].
class TradingHomeScreen extends StatelessWidget {
  const TradingHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (FlavorConfig.usesNewHomeDesign) {
      return const TradingMainScreenNew();
    }
    return const TradingMainScreen();
  }
}
