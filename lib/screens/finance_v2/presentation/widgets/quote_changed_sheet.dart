import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/services/language_service.dart';

import '../../data/models/finance_channel.dart';
import 'finance_v2_primary_button.dart';

/// Asks the client to accept the quote the server sent with a 409
/// QUOTE_CHANGED answer.
///
/// Returns true when the client confirms [newQuote]; false when the sheet is
/// cancelled or dismissed. [oldYouGet] is the figure of the quote that was
/// rejected, shown struck through. [message] is the server's text of the
/// answer, shown as a notice above the figures.
Future<bool> showQuoteChangedSheet(
  BuildContext context, {
  required ChannelQuote newQuote,
  String? oldYouGet,
  String? message,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
    ),
    builder: (_) => _QuoteChangedSheet(
      newQuote: newQuote,
      oldYouGet: oldYouGet,
      message: message,
    ),
  );
  return confirmed ?? false;
}

class _QuoteChangedSheet extends StatelessWidget {
  final ChannelQuote newQuote;
  final String? oldYouGet;
  final String? message;

  const _QuoteChangedSheet({
    required this.newQuote,
    this.oldYouGet,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final oldYouGet = this.oldYouGet ?? '';
    final message = this.message?.trim() ?? '';
    final showOld = oldYouGet.isNotEmpty && oldYouGet != newQuote.youGet;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsetsDirectional.fromSTEB(16.w, 16.h, 16.w, 8.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                TranslationUtils.tr('fv2_quote_changed_title'),
                style: AppTextStyles.bodyText.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 12.h),
              if (message.isNotEmpty) ...[
                _QuoteNotice(text: message),
                SizedBox(height: 12.h),
              ],
              _QuoteLine(
                label: TranslationUtils.tr('fv2_you_pay'),
                value: newQuote.youPay,
              ),
              SizedBox(height: 8.h),
              _QuoteLine(
                label: TranslationUtils.tr('fv2_you_get'),
                value: newQuote.youGet,
                struckValue: showOld ? oldYouGet : null,
                emphasised: true,
              ),
              if (newQuote.rateLine.isNotEmpty) ...[
                SizedBox(height: 8.h),
                _QuoteNote(text: newQuote.rateLine),
              ],
              if (newQuote.feeLine.isNotEmpty) ...[
                SizedBox(height: 4.h),
                _QuoteNote(text: newQuote.feeLine),
              ],
              SizedBox(height: 16.h),
              FinanceV2PrimaryButton(
                label: TranslationUtils.tr('fv2_confirm_new_rate'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  TranslationUtils.tr('general_cancel'),
                  style: AppTextStyles.bodyText.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuoteLine extends StatelessWidget {
  final String label;
  final String value;
  final String? struckValue;
  final bool emphasised;

  const _QuoteLine({
    required this.label,
    required this.value,
    this.struckValue,
    this.emphasised = false,
  });

  @override
  Widget build(BuildContext context) {
    final struckValue = this.struckValue;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyText.copyWith(
            color: AppColors.textGrey,
            fontSize: 12.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyText.copyWith(
                  color: emphasised ? AppColors.primary : AppColors.textPrimary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (struckValue != null) ...[
                SizedBox(height: 4.h),
                Text(
                  struckValue,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyText.copyWith(
                    color: AppColors.textGrey,
                    fontSize: 12.sp,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The server's explanation of the new price, in the warning colours.
class _QuoteNotice extends StatelessWidget {
  final String text;

  const _QuoteNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(8.r),
        // A rounded box needs a uniform border; a start-only stripe asserts.
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: 12.w,
          vertical: 10.h,
        ),
        child: Text(
          text,
          style: AppTextStyles.bodyText.copyWith(
            color: AppColors.warningText,
            fontSize: 13.sp,
          ),
        ),
      ),
    );
  }
}

class _QuoteNote extends StatelessWidget {
  final String text;

  const _QuoteNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.start,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.bodyText.copyWith(
        color: AppColors.textSecondary,
        fontSize: 12.sp,
      ),
    );
  }
}
