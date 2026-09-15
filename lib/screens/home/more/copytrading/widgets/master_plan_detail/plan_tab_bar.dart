import 'package:crm_app/constants/color.dart';
import 'package:flutter/material.dart';
import 'plan_detail_tokens.dart';

/// Modern "pill-style" tab bar used at the top of the Plan Detail screen.
/// Single horizontal scroll if there are too many tabs.
class PlanTabBar extends StatelessWidget {
  final List<String> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final PlanTokens tokens;

  const PlanTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (int i = 0; i < tabs.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              _TabPill(
                label: tabs[i],
                active: i == currentIndex,
                onTap: () => onTap(i),
                tokens: tokens,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final PlanTokens tokens;
  const _TabPill({
    required this.label,
    required this.active,
    required this.onTap,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? tokens.brand : tokens.surface,
          border: Border.all(color: active ? tokens.brand : tokens.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.whiteColor : tokens.subText,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
