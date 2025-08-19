import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/utils/trl_helper.dart';

class CurrencyTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String currencySymbol;
  final InputDecoration? decoration;
  final String? labelText;
  final String? hintText;

  const CurrencyTextField({
    Key? key,
    this.controller,
    this.currencySymbol = "\$",
    this.decoration,
    this.labelText,
    this.hintText,
  }) : super(key: key);

  @override
  _CurrencyTextFieldState createState() => _CurrencyTextFieldState();
}

class _CurrencyTextFieldState extends State<CurrencyTextField> {
  late TextEditingController _controller;
  final NumberFormat _formatter = NumberFormat.currency(
    locale: "en_US",
    symbol: "",
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_formatCurrency);
  }

  void _formatCurrency() {
    String text = _controller.text.replaceAll(RegExp(r'[^0-9]'), "");

    if (text.isEmpty) {
      _controller.value = TextEditingValue(
        text: "${widget.currencySymbol}0.00",
        selection: TextSelection.collapsed(offset: 1),
      );
      return;
    }

    double value = double.parse(text) / 100;
    String newText = "${widget.currencySymbol}${_formatter.format(value)}";

    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_formatCurrency);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RTLHelper.rtlTextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      decoration: widget.decoration ??
          InputDecoration(
            labelText: widget.labelText ?? 'Amount',
            hintText: widget.hintText,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
          ),
    );
  }
}
