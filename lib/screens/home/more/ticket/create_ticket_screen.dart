import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/controllers/ticket_controller.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/widgets/custom_toast.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final TicketController controller = Get.find<TicketController>();
  final LanguageService languageService = Get.find<LanguageService>();
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  int? departmentId;
  String priority = 'medium';
  File? attachment;
  String? attachmentName;

  String tr(String key) => languageService.tr(key);

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
    );
    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final size = await file.length();
    if (size > 5 * 1024 * 1024) {
      CustomToastService.showError(message: tr('ticket_attachment_formats'));
      return;
    }

    setState(() {
      attachment = file;
      attachmentName = result.files.single.name;
    });
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (departmentId == null) {
      CustomToastService.showError(message: tr('ticket_select_department'));
      return;
    }

    final success = await controller.createTicket(
      departmentId: departmentId!,
      priority: priority,
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      attachment: attachment,
    );

    if (success) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20.h),
          onPressed: Get.back,
        ),
        title: Text(tr('ticket_new_ticket'), style: TextStyle(color: AppColors.textPrimary, fontSize: 18.sp, fontWeight: FontWeight.w600)),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            Obx(() => _DropdownBox<int>(
                  label: tr('ticket_department'),
                  value: departmentId,
                  hint: tr('ticket_select_department'),
                  items: controller.departments.map((department) => DropdownMenuItem(value: department.id, child: Text(department.name))).toList(),
                  onChanged: (value) => setState(() => departmentId = value),
                  validator: (value) => value == null ? tr('ticket_select_department') : null,
                )),
            SizedBox(height: 14.h),
            _DropdownBox<String>(
              label: tr('ticket_priority'),
              value: priority,
              items: [
                DropdownMenuItem(value: 'low', child: Text(tr('ticket_priority_low'))),
                DropdownMenuItem(value: 'medium', child: Text(tr('ticket_priority_medium'))),
                DropdownMenuItem(value: 'high', child: Text(tr('ticket_priority_high'))),
              ],
              onChanged: (value) => setState(() => priority = value ?? 'medium'),
            ),
            SizedBox(height: 14.h),
            _TextBox(
              controller: titleController,
              label: tr('ticket_subject'),
              hint: tr('ticket_subject_hint'),
              validator: (value) => (value == null || value.trim().isEmpty) ? tr('ticket_subject') : null,
            ),
            SizedBox(height: 14.h),
            _TextBox(
              controller: descriptionController,
              label: tr('ticket_description'),
              hint: tr('ticket_description_hint'),
              maxLines: 6,
              validator: (value) => (value == null || value.trim().isEmpty) ? tr('ticket_description') : null,
            ),
            SizedBox(height: 16.h),
            Text(tr('ticket_attachment'), style: _labelStyle()),
            SizedBox(height: 8.h),
            InkWell(
              borderRadius: BorderRadius.circular(14.r),
              onTap: pickAttachment,
              child: Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14.r), border: Border.all(color: AppColors.border)),
                child: Row(
                  children: [
                    Icon(Icons.attach_file, color: AppColors.primary, size: 22.h),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        attachmentName ?? tr('ticket_attach_files'),
                        style: TextStyle(color: attachmentName == null ? AppColors.textGrey : AppColors.textPrimary, fontSize: 14.sp),
                      ),
                    ),
                    if (attachmentName != null)
                      IconButton(
                        onPressed: () => setState(() {
                          attachment = null;
                          attachmentName = null;
                        }),
                        icon: Icon(Icons.close, color: AppColors.error, size: 20.h),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Text(tr('ticket_attachment_formats'), style: TextStyle(color: AppColors.textGrey, fontSize: 12.sp)),
            SizedBox(height: 26.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: Get.back,
                    style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14.h), side: BorderSide(color: AppColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r))),
                    child: Text(tr('ticket_cancel'), style: TextStyle(color: AppColors.textPrimary)),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Obx(() => ElevatedButton(
                        onPressed: controller.isSubmitting.value ? null : submit,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onColoredBackground, padding: EdgeInsets.symmetric(vertical: 14.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r))),
                        child: controller.isSubmitting.value
                            ? SizedBox(height: 18.h, width: 18.h, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(tr('ticket_create')),
                      )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _labelStyle() => TextStyle(color: AppColors.textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w600);
}

class _DropdownBox<T> extends StatelessWidget {
  final String label;
  final T? value;
  final String? hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  const _DropdownBox({required this.label, required this.value, this.hint, required this.items, required this.onChanged, this.validator});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 8.h),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          dropdownColor: AppColors.card,
          decoration: _inputDecoration(hint),
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
        ),
      ],
    );
  }
}

class _TextBox extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const _TextBox({required this.controller, required this.label, required this.hint, this.maxLines = 1, this.validator});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
          decoration: _inputDecoration(hint),
        ),
      ],
    );
  }
}

InputDecoration _inputDecoration(String? hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppColors.card,
    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: AppColors.primary)),
  );
}
