import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/controllers/ib_controller.dart';
// import 'package:crm_app/screens/home/more/ib_dashboard/commission_history_screen.dart';
import 'package:crm_app/screens/home/more/ib_dashboard/ib_dashboard_new_screen.dart';
import 'package:crm_app/screens/home/more/ib_dashboard/ib_structure_screen.dart';
import 'package:crm_app/screens/home/more/ib_dashboard/ib_requests_screen.dart';
import 'package:crm_app/screens/home/more/ib_dashboard/ib_more_screen.dart';
import 'package:crm_app/screens/home/more/ib_dashboard/my_clients_screen.dart';
import 'package:crm_app/widgets/ib_bottom_navigation.dart';

class IbMainScreen extends StatefulWidget {
  const IbMainScreen({super.key});

  @override
  State<IbMainScreen> createState() => _IbMainScreenState();
}

class _IbMainScreenState extends State<IbMainScreen> {
  int _currentIndex = 0;
  late IBController ibController;
  int _screenKey = 0; // Key to force rebuild screens
  bool _hasInitialized = false;
  DateTime? _lastResetTime;

  @override
  void initState() {
    super.initState();
    // Initialize IBController if not registered
    if (Get.isRegistered<IBController>()) {
      ibController = Get.find<IBController>();
    } else {
      ibController = Get.put(IBController());
    }

    // Reset state when navigating to IB dashboard
    _resetIBState();
    _hasInitialized = true;
    _lastResetTime = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitialized &&
        (_lastResetTime == null ||
            DateTime.now().difference(_lastResetTime!).inMilliseconds > 500)) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _resetIBState();
        }
      });
    }
  }

  void _resetIBState() {
    ibController.selectedSubIBId = null;
    if (_currentIndex != 0) {
      _currentIndex = 0;
    }
    _screenKey++;
    _lastResetTime = DateTime.now();
    // Defer update() to fire after the current build phase completes
    // to avoid "setState() called during build" error
    SchedulerBinding.instance.addPostFrameCallback((_) {
      ibController.update(['ib_clients', 'ib_structure']);
    });
  }

  List<Widget> _getScreens() {
    // Use key to force rebuild when navigating back
    return [
      IbDashboardNewScreen(
        key: ValueKey('dashboard_$_screenKey'),
        onNavigateToTab: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      IBStructureScreen(key: ValueKey('structure_$_screenKey')),
      MyClientsScreen(key: ValueKey('clients_$_screenKey')),
      IBRequestsScreen(key: ValueKey('requests_$_screenKey')),
      IBMoreScreen(key: ValueKey('more_$_screenKey')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: _getScreens()),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      floatingActionButton: IbBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            // If switching to Dashboard, reset state
            if (index == 0 && _currentIndex != 0) {
              _resetIBState();
            }
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
