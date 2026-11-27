import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';

/// `AppBar` painted with the home header gradient, white title and icons.
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const GradientAppBar({super.key, required this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final onHeader = AppColors.onColoredBackground;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: onHeader,
      iconTheme: IconThemeData(color: onHeader),
      actionsIconTheme: IconThemeData(color: onHeader),
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [
              AppColors.homeHeaderGradientStart,
              AppColors.homeHeaderGradientEnd,
            ],
          ),
        ),
        // A childless DecoratedBox sizes to the smallest allowed height, which
        // is 0 under the AppBar's loose constraints, so the gradient never
        // painted. SizedBox.expand makes it fill the whole bar.
        child: const SizedBox.expand(),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.screenTitle.copyWith(color: onHeader),
      ),
      actions: actions,
    );
  }
}
