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

    // Cold start: `resumed` does NOT fire on a fresh launch (only after a
    // paused → resumed cycle), so lock once the first frame is up. Without
    // this, biometric unlock never prompts on first open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!Get.isRegistered<AppLockService>()) return;
      Get.find<AppLockService>().lockIfNeeded(
        reason: 'Authenticate to continue.',
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!Get.isRegistered<AppLockService>()) return;
    final lockService = Get.find<AppLockService>();

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      lockService.markPaused();
    } else if (state == AppLifecycleState.resumed) {
      if (lockService.isUnlocking.value) return;
      lockService.lockIfNeeded(reason: 'Authenticate to continue.');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

