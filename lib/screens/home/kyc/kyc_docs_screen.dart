import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/widgets/kyc_scaffold.dart';
import 'package:pipze/routes/app_pages.dart';

class KycDocsScreen extends StatelessWidget {
  const KycDocsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return KycScaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24.h),

              // ID Proof Section
              Text(
                'ID Proof',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 20.h),

              // ID Proof Upload Tiles (Row 1)
              Row(
                children: [
                  Expanded(
                    child: _buildUploadTile(
                      isActive: true,
                      onTap: () => _handleUpload('ID Proof 1'),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildUploadTile(
                      isActive: false,
                      onTap: () => _handleUpload('ID Proof 2'),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 40.h),

              // Address Proof Section
              Text(
                'Address Proof',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 20.h),

              // Address Proof Upload Tiles (Row 2)
              Row(
                children: [
                  Expanded(
                    child: _buildUploadTile(
                      isActive: true,
                      onTap: () => _handleUpload('Address Proof 1'),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildUploadTile(
                      isActive: false,
                      onTap: () => _handleUpload('Address Proof 2'),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A2DD8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadTile({
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120.h,
        decoration: BoxDecoration(
          color: isActive 
              ? const Color(0xFFF8F3FF) // Light purple for active
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive 
                ? const Color(0xFF5A2DD8) // Primary purple for active
                : const Color(0xFFE3E7EF), // Divider grey for inactive
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Stack(
          children: [
            // Dashed border overlay
            CustomPaint(
              size: Size.infinite,
              painter: DashedBorderPainter(
                color: isActive 
                    ? const Color(0xFF5A2DD8)
                    : const Color(0xFFE3E7EF),
                strokeWidth: 2,
                dashPattern: [8, 4],
              ),
            ),
            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A2DD8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 24.w,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Upload',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isActive 
                          ? const Color(0xFF5A2DD8)
                          : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleUpload(String documentType) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Upload $documentType',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      _showUploadSuccess(documentType);
                    },
                    icon: Icon(Icons.camera_alt),
                    label: Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A2DD8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      _showUploadSuccess(documentType);
                    },
                    icon: Icon(Icons.photo_library),
                    label: Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A2DD8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  void _showUploadSuccess(String documentType) {
    Get.snackbar(
      'Success',
      '$documentType uploaded successfully!',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void _handleSave() {
    // TODO: Implement save logic
    Get.snackbar(
      'Success',
      'Documents saved successfully!',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
    
    // Navigate to next screen
    Future.delayed(Duration(seconds: 1), () {
      Get.toNamed(AppPages.KYC_SUCCESS);
    });
  }
}

// Custom painter for dashed borders
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashPattern,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(10),
      ));

    // Create dashed effect
    final dashWidth = dashPattern[0];
    final dashSpace = dashPattern[1];
    
    final pathMetrics = path.computeMetrics().first;
    final pathLength = pathMetrics.length;
    
    double distance = 0;
    bool draw = true;
    
    while (distance < pathLength) {
      if (draw) {
        final start = pathMetrics.getTangentForOffset(distance);
        final end = pathMetrics.getTangentForOffset(
          distance + dashWidth > pathLength ? pathLength : distance + dashWidth,
        );
        
        if (start != null && end != null) {
          canvas.drawLine(start.position, end.position, paint);
        }
      }
      
      distance += dashWidth + dashSpace;
      draw = !draw;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
