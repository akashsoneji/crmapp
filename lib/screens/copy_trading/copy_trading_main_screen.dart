import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/widgets/copy_trading_bottom_navigation.dart';
import 'package:crm_app/controllers/copy_trading/copy_trading_hub_controller.dart';

import 'tabs/become_master_tab.dart';
import 'tabs/my_plans_tab.dart';
import '../home/more/copytrading/master_dashboard_screen.dart';
import '../home/more/copytrading/my_copies_screen.dart';
import '../home/more/copytrading/explore_masters_screen.dart';
import '../home/more/copytrading/my_investments_screen.dart';

class CopyTradingMainScreen extends StatefulWidget {
  final int? initialIndex;
  const CopyTradingMainScreen({super.key, this.initialIndex});

  @override
  State<CopyTradingMainScreen> createState() => _CopyTradingMainScreenState();
}

class _CopyTradingMainScreenState extends State<CopyTradingMainScreen> {
  late final CopyTradingHubController _hubController;
  late final ValueNotifier<int> _currentIndex;

  @override
  void initState() {
    super.initState();
    _hubController = Get.put(CopyTradingHubController());
    final isMaster = _hubController.masterStatus.value == CopyTradingMasterApplicationStatus.approved;
    _currentIndex = ValueNotifier<int>(
      widget.initialIndex ?? (isMaster ? 0 : 1),
    );
  }

  @override
  void dispose() {
    _currentIndex.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    _currentIndex.value = index;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_hubController.isLoading.value && _hubController.masterStatus.value == CopyTradingMasterApplicationStatus.none) {
        return Scaffold(
          backgroundColor: AppColors.tradeBackgroundCenterColor,
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final isMaster = _hubController.masterStatus.value == CopyTradingMasterApplicationStatus.approved;

      return Scaffold(
        backgroundColor: AppColors.tradeBackgroundCenterColor,
        body: SafeArea(
          // ValueListenableBuilder rebuilds only the IndexedStack when tab changes
          child: ValueListenableBuilder<int>(
            valueListenable: _currentIndex,
            builder: (context, index, _) {
              final maxIndex = isMaster ? 4 : 2;
              final activeIndex = index.clamp(0, maxIndex);

              final List<Widget> tabs = isMaster
                  ? [
                      MasterDashboardScreen(masterCode: _hubController.masterCode.value),
                      const MyPlansTab(),
                      const MyCopiesScreen(),
                      const ExploreMastersScreen(),
                      const MyInvestmentsScreen(),
                    ]
                  : [
                      const BecomeMasterTab(),
                      const ExploreMastersScreen(),
                      const MyInvestmentsScreen(),
                    ];

              return Padding(
                padding: const EdgeInsets.only(
                  bottom: kBottomNavigationBarHeight,
                ),
                child: IndexedStack(index: activeIndex, children: tabs),
              );
            },
          ),
        ),

        // Floating pill navigation — same pattern as TradingMainScreen
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
        floatingActionButton: ValueListenableBuilder<int>(
          valueListenable: _currentIndex,
          builder: (context, index, _) {
            final maxIndex = isMaster ? 4 : 2;
            return CopyTradingBottomNavigation(
              currentIndex: index.clamp(0, maxIndex),
              onTap: _onTabChanged,
              isMaster: isMaster,
            );
          },
        ),
      );
    });
  }
}
