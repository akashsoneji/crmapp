import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:crm_app/constants/color.dart';

class OtpInputRow extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onCompleted;

  const OtpInputRow({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
  });

  @override
  State<OtpInputRow> createState() => OtpInputRowState();
}

class OtpInputRowState extends State<OtpInputRow> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    for (var i = 0; i < widget.length; i++) {
      _controllers[i].addListener(_notifyChange);
    }
  }

  void _notifyChange() {
    final code = otpCode;
    widget.onChanged?.call(code);
    if (code.length == widget.length) {
      widget.onCompleted?.call();
    }
  }

  String get otpCode => _controllers.map((c) => c.text).join();

  bool get isComplete => otpCode.length == widget.length;

  void clear() {
    for (final controller in _controllers) {
      controller.clear();
    }
    if (_focusNodes.isNotEmpty) {
      _focusNodes[0].requestFocus();
    }
    _notifyChange();
  }

  void _onCodeChanged(String value, int index) {
    if (value.length > 1 && value.length <= widget.length) {
      final otp = value.padRight(widget.length, '');
      for (var i = 0; i < widget.length; i++) {
        _controllers[i].text = i < otp.length ? otp[i] : '';
      }
      if (otp.length == widget.length) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (_focusNodes[widget.length - 1].canRequestFocus) {
            _focusNodes[widget.length - 1].requestFocus();
          }
        });
      } else if (otp.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 50), () {
          final focusIndex = otp.length - 1;
          if (_focusNodes[focusIndex].canRequestFocus) {
            _focusNodes[focusIndex].requestFocus();
          }
        });
      }
    } else if (value.length == 1) {
      if (index < widget.length - 1) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (_focusNodes[index + 1].canRequestFocus) {
            _focusNodes[index + 1].requestFocus();
          }
        });
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (_focusNodes[index - 1].canRequestFocus) {
          _focusNodes[index - 1].requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.length, (index) {
        return SizedBox(
          width: 50.w,
          height: 46.h,
          child: TextField(
            cursorColor: AppColors.primary,
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: index == 0 ? widget.length : 1,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(index == 0 ? widget.length : 1),
            ],
            onChanged: (value) => _onCodeChanged(value, index),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            decoration: InputDecoration(
              counterText: '',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                vertical: 13.h,
                horizontal: 14.w,
              ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        );
      }),
    );
  }
}