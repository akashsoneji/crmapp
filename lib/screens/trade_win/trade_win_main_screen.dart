import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/controllers/trade_win/trade_win_controller.dart';
import 'package:crm_app/widgets/trade_win_bottom_navigation.dart';
import 'package:crm_app/screens/trade_win/tabs/trade_win_home_tab.dart';
import 'package:crm_app/screens/trade_win/tabs/trade_win_leaderboard_tab.dart';
import 'package:crm_app/screens/trade_win/tabs/trade_win_my_wins_tab.dart';
class TradeWinMainScreen extends StatefulWidget {
  const TradeWinMainScreen({super.key});

  @override
  State<TradeWinMainScreen> createState() => _TradeWinMainScreenState();
}

class _TradeWinMainScreenState extends State<TradeWinMainScreen> {
  final ValueNotifier<int> _currentIndex = ValueNotifier<int>(0);

  final List<Widget> _tabs = const [
    TradeWinHomeTab(),
    TradeWinLeaderboardTab(),
    TradeWinMyWinsTab(),
  ];

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<TradeWinController>()) {
      Get.put(TradeWinController());
    }
  }

  @override
  void dispose() {
    _currentIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      body: SafeArea(
        child: ValueListenableBuilder<int>(
          valueListenable: _currentIndex,
          builder: (context, index, _) {
            return IndexedStack(index: index, children: _tabs);
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: ValueListenableBuilder<int>(
        valueListenable: _currentIndex,
        builder: (context, index, _) {
          return TradeWinBottomNavigation(
            currentIndex: index,
            onTap: (i) => _currentIndex.value = i,
          );
        },
      ),
    );
  }
}
