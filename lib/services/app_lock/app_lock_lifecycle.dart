import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:crm_app/services/app_lock_service.dart';

class AppLockLifecycle extends StatefulWidget {
  final Widget child;
  const AppLockLifecycle({super.key, required this.child});

  @override
  State<AppLockLifecycle> createState() => _AppLockLifecycleState();
}

class _AppLockLifecycleState extends State<AppLockLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Lock-on-resume behavior (only locks if enabled + session exists).
      final lockService = Get.find<AppLockService>();
      if (lockService.isUnlocking.value) return;
      lockService.lockIfNeeded(reason: 'Authenticate to continue.');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

