import 'package:adaptive_platform_ui/adaptive_platform_ui.dart' as adaptive;
import 'package:crm_app/flavor_config.dart';
import 'package:flutter/material.dart';

class AdaptiveAppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? thumbColor;

  const AdaptiveAppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.thumbColor,
  });

  @override
  Widget build(BuildContext context) {
    return adaptive.AdaptiveSwitch(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor ?? FlavorConfig.instance.primaryColor,
      thumbColor: thumbColor,
    );
  }
}
