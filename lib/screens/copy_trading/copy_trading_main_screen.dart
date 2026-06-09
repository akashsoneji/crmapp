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
  late final PageController _pageController;
  late final Worker _worker;

  @override
  void initState() {
    super.initState();
    _hubController = Get.put(CopyTradingHubController());
    final isMaster =
        _hubController.masterStatus.value ==
        CopyTradingMasterApplicationStatus.approved;
    final initialIndex = widget.initialIndex ?? (isMaster ? 0 : 1);
    _hubController.currentTabIndex.value = initialIndex;
    _pageController = PageController(initialPage: initialIndex);
    
    _worker = ever(_hubController.currentTabIndex, (int index) {
      if (_pageController.hasClients && _pageController.page?.round() != index) {
        _pageController.jumpToPage(index.clamp(0, isMaster ? 4 : 2));
      }
    });
  }

  @override
  void dispose() {
    _worker.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_hubController.isLoading.value &&
          _hubController.masterStatus.value ==
              CopyTradingMasterApplicationStatus.none) {
        return Scaffold(
          backgroundColor: AppColors.tradeBackgroundCenterColor,
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      final isMaster =
          _hubController.masterStatus.value ==
          CopyTradingMasterApplicationStatus.approved;

      final maxIndex = isMaster ? 4 : 2;
      final activeIndex = _hubController.currentTabIndex.value.clamp(0, maxIndex);

      final List<Widget> tabs =
          isMaster
              ? [
                  KeepAliveWrapper(
                    key: const ValueKey('master_dashboard'),
                    child: MasterDashboardScreen(
                      masterCode: _hubController.masterCode.value,
                    ),
                  ),
                  const KeepAliveWrapper(
                    key: ValueKey('my_plans'),
                    child: MyPlansTab(),
                  ),
                  const KeepAliveWrapper(
                    key: ValueKey('my_copies'),
                    child: MyCopiesScreen(),
                  ),
                  const KeepAliveWrapper(
                    key: ValueKey('explore_masters_master'),
                    child: ExploreMastersScreen(),
                  ),
                  const KeepAliveWrapper(
                    key: ValueKey('my_investments_master'),
                    child: MyInvestmentsScreen(),
                  ),
                ]
              : [
                  const KeepAliveWrapper(
                    key: ValueKey('become_master'),
                    child: BecomeMasterTab(),
                  ),
                  const KeepAliveWrapper(
                    key: ValueKey('explore_masters_copier'),
                    child: ExploreMastersScreen(),
                  ),
                  const KeepAliveWrapper(
                    key: ValueKey('my_investments_copier'),
                    child: MyInvestmentsScreen(),
                  ),
                ];

      return Scaffold(
        backgroundColor: AppColors.tradeBackgroundCenterColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: kBottomNavigationBarHeight,
            ),
            child: PageView(
              controller: _pageController,
              onPageChanged: (idx) {
                _hubController.currentTabIndex.value = idx;
              },
              physics: const NeverScrollableScrollPhysics(),
              children: tabs,
            ),
          ),
        ),

        // Floating pill navigation — same pattern as TradingMainScreen
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
        floatingActionButton: CopyTradingBottomNavigation(
          currentIndex: activeIndex,
          onTap: (idx) => _hubController.currentTabIndex.value = idx,
          isMaster: isMaster,
        ),
      );
    });
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}

