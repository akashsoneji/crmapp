import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';

/// Shared frame for the tenaxnew bottom sheets: rounded top, drag handle,
/// header row, keyboard insets and the bottom safe area.
///
/// When [expand] is true the frame fills the height the modal gives it (use
/// for list sheets); otherwise it wraps its content.
class SheetScaffoldNew extends StatelessWidget {
  final String? title;
  final Widget? header;
  final Widget? leading;
  final Widget? trailing;
  final Widget child;
  final bool expand;
  final EdgeInsetsGeometry bodyPadding;

  const SheetScaffoldNew({
    super.key,
    this.title,
    this.header,
    this.leading,
    this.trailing,
    required this.child,
    this.expand = false,
    this.bodyPadding = EdgeInsetsDirectional.zero,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final body = Padding(padding: bodyPadding, child: child);

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Material(
        color: AppColors.sheetSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.only(bottom: safeBottom + 8.h),
          child: Column(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SheetHandle(),
              if (header != null)
                header!
              else if (title != null || leading != null || trailing != null)
                _SheetHeaderRow(
                  title: title,
                  leading: leading,
                  trailing: trailing,
                ),
              if (expand) Expanded(child: body) else Flexible(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

/// Owns a tagged sheet controller's lifetime: deletes it when this subtree is
/// disposed. A modal route disposes its widgets only after the exit
/// animation, so the controller's text fields stay valid while the sheet
/// slides away (deleting when `showModalBottomSheet` returns is too early).
class SheetControllerScope<T extends GetxController> extends StatefulWidget {
  final String tag;
  final Widget child;

  const SheetControllerScope({
    super.key,
    required this.tag,
    required this.child,
  });

  @override
  State<SheetControllerScope<T>> createState() =>
      _SheetControllerScopeState<T>();
}

class _SheetControllerScopeState<T extends GetxController>
    extends State<SheetControllerScope<T>> {
  @override
  void dispose() {
    Get.delete<T>(tag: widget.tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.only(top: 8.h, bottom: 4.h),
        width: 36.w,
        height: 4.h,
        decoration: BoxDecoration(
          color: AppColors.sheetGrabber,
          borderRadius: BorderRadius.circular(2.r),
        ),
      ),
    );
  }
}

class _SheetHeaderRow extends StatelessWidget {
  final String? title;
  final Widget? leading;
  final Widget? trailing;

  const _SheetHeaderRow({this.title, this.leading, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: leading == null ? 16.w : 4.w,
        end: 4.w,
        top: 0,
        bottom: 4.h,
      ),
      child: Row(
        children: [
          if (leading != null) leading!,
          if (title != null)
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title!,
                  maxLines: 2,
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.sheetTextPrimary,
                  ),
                ),
              ),
            )
          else
            const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Round icon button sized to a 44px tap target, used in sheet headers.
class SheetIconButtonNew extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const SheetIconButtonNew({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: BoxConstraints.tightFor(width: 44.r, height: 44.r),
      padding: EdgeInsets.zero,
      icon: Icon(icon, size: 20.r, color: AppColors.sheetTextPrimary),
    );
  }
}

/// Full-width brand-gradient call-to-action used at the bottom of sheets.
class SheetGradientButtonNew extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SheetGradientButtonNew({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final radius = BorderRadius.circular(12.r);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled || isLoading ? 1 : 0.5,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              colors: [
                AppColors.homeHeaderGradientStart,
                AppColors.homeHeaderGradientEnd,
              ],
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radius,
              onTap: enabled ? onPressed : null,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: 44.r),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 18.r,
                            height: 18.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: AppColors.onColoredBackground,
                            ),
                          )
                        : Text(
                            label,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.button.copyWith(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onColoredBackground,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
