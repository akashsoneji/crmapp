import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/screens/home/more/ib_dashboard/commission_history_screen.dart';
import 'package:pipze/screens/home/more/ib_dashboard/ib_dashboard_new_screen.dart';
import 'package:pipze/screens/home/more/ib_dashboard/my_clients_screen.dart';
import 'package:pipze/widgets/ib_bottom_navigation.dart';

class IbMainScreen extends StatefulWidget {
  const IbMainScreen({super.key});

  @override
  State<IbMainScreen> createState() => _IbMainScreenState();
}

class _IbMainScreenState extends State<IbMainScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const IbDashboardNewScreen(),
      const MyClientsScreen(),
      const CommissionHistoryScreen(),
      const MarketingScreen(),
      const IbMoreScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: _screens),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      floatingActionButton: IbBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

// Placeholder screens for now - will be implemented later

class MarketingScreen extends StatelessWidget {
  const MarketingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      appBar: AppBar(
        backgroundColor: AppColors.tradeBackgroundCenterColor,
        elevation: 0,
        title: Text(
          'Marketing',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Text(
          'Marketing Screen',
          style: TextStyle(fontSize: 16.sp, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class IbMoreScreen extends StatelessWidget {
  const IbMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      appBar: AppBar(
        backgroundColor: AppColors.tradeBackgroundCenterColor,
        elevation: 0,
        title: Text(
          'More',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Text(
          'IB More Screen',
          style: TextStyle(fontSize: 16.sp, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
