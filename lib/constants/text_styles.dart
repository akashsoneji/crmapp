import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTextStyles {
  static final heading = TextStyle(
    fontSize: 31.sp,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  static final subheading = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w400,
    color: Colors.grey,
  );

  static final label = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: Colors.black,
  );

  static final input = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w400,
    color: Colors.black,
  );

  static final link = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.underline,
    color: Color(0xFF692EAF),
  );

  static final button = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
