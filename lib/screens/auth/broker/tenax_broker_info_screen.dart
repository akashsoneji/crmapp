import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/models/tenax_broker_model.dart';

class TenaxBrokerInfoScreen extends StatelessWidget {
  const TenaxBrokerInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final broker = args['broker'] as TenaxBrokerModel?;
    final config = args['config'] as Map<String, dynamic>? ?? {};

    final rows = _buildRows(broker, config);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF21242C),
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Broker Information',
          style: TextStyle(
            color: const Color(0xFF21242C),
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Divider(height: 1.h, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: rows.length,
              separatorBuilder:
                  (_, __) => Divider(
                    height: 1.h,
                    color: const Color(0xFFE5E7EB),
                    indent: 20.w,
                    endIndent: 20.w,
                  ),
              itemBuilder: (context, index) {
                return _InfoRow(
                  value: rows[index].value,
                  label: rows[index].label,
                );
              },
            ),
          ),
          _buildReportButton(context),
        ],
      ),
    );
  }

  List<_RowData> _buildRows(
    TenaxBrokerModel? broker,
    Map<String, dynamic> config,
  ) {
    final list = <_RowData>[];

    void add(String? value, String label) {
      final v = (value ?? '').trim();
      if (v.isNotEmpty) {
        list.add(_RowData(value: v, label: label));
      }
    }

    // Registration Number
    add(_str(config['registration_number']), 'Registration Number');

    // Company / Name
    final company =
        _str(config['company_name']) ??
        _str(config['name']) ??
        _str(config['company']) ??
        broker?.companyName;
    add(company, 'Company');

    // Registration / Registered Address
    add(
      _str(config['registered_address']) ??
          _str(config['registration_address']),
      'Registration Address',
    );

    // Status
    add(_str(config['status']) ?? _str(broker?.raw['status']), 'Status');

    // Offices / Office Location
    add(
      _str(config['office_location']) ?? _str(config['offices_location']),
      'Offices Location',
    );

    // Website
    add(_str(config['website_url']) ?? _str(config['website']), 'Website');

    // Generic Email
    add(_str(config['generic_email']), 'Generic Email');

    // Abuse Reporting Email
    add(_str(config['abuse_reporting_email']), 'Abuse Reporting Email');

    // Phone / Mobile
    add(_str(config['mobile_number']) ?? _str(config['phone']), 'Phone');

    return list;
  }

  String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  Widget _buildReportButton(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
        child: SizedBox(
          width: double.infinity,
          height: 52.h,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B3FA0), Color(0xFF4A1A8C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              onPressed: () => _showReportDialog(context),
              child: Text(
                'Report a Problem to the Broker',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'To report a problem to the broker, you need to have a trading account with it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF21242C),
                    fontSize: 14.sp,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF0EBF9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      'OK',
                      style: TextStyle(
                        color: const Color(0xFF6B3FA0),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RowData {
  final String value;
  final String label;
  const _RowData({required this.value, required this.label});
}

class _InfoRow extends StatelessWidget {
  final String value;
  final String label;

  const _InfoRow({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFF21242C),
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF9CA3AF),
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
