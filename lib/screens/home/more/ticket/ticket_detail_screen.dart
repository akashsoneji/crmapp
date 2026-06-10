import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/controllers/ticket_controller.dart';
import 'package:crm_app/models/ticket_model.dart';
import 'package:crm_app/services/language_service.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> with SingleTickerProviderStateMixin {
  final TicketController controller = Get.find<TicketController>();
  final LanguageService languageService = Get.find<LanguageService>();
  final TextEditingController replyController = TextEditingController();
  File? replyAttachment;
  String? replyAttachmentName;

  String tr(String key) => languageService.tr(key);

  @override
  void initState() {
    super.initState();
    controller.fetchTicketDetail(widget.ticketId);
  }

  @override
  void dispose() {
    replyController.dispose();
    super.dispose();
  }

  Future<void> pickReplyAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
    );
    if (result?.files.single.path == null) return;
    setState(() {
      replyAttachment = File(result!.files.single.path!);
      replyAttachmentName = result.files.single.name;
    });
  }

  Future<void> sendReply() async {
    final message = replyController.text.trim();
    if (message.isEmpty && replyAttachment == null) return;
    final success = await controller.replyToTicket(widget.ticketId, message, attachment: replyAttachment);
    if (success) {
      replyController.clear();
      setState(() {
        replyAttachment = null;
        replyAttachmentName = null;
      });
    }
  }

  Future<void> closeTicket() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(tr('ticket_close'), style: TextStyle(color: AppColors.textPrimary)),
        content: Text(tr('ticket_close_confirm'), style: TextStyle(color: AppColors.textGrey)),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(tr('ticket_cancel'))),
          ElevatedButton(onPressed: () => Get.back(result: true), child: Text(tr('confirm'))),
        ],
      ),
    );
    if (confirmed == true) controller.closeTicket(widget.ticketId);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Obx(() {
        final detail = controller.ticketDetail.value;
        final attachmentCount = detail?.attachment == null ? 0 : 1;
        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundLight,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20.h), onPressed: Get.back),
            title: Text(detail == null ? tr('ticket_detail') : '#${detail.id}', style: TextStyle(color: AppColors.textPrimary, fontSize: 18.sp, fontWeight: FontWeight.w600)),
          ),
          body: controller.isDetailLoading.value
              ? Center(child: CircularProgressIndicator(color: AppColors.primary))
              : detail == null
                  ? Center(child: Text(tr('ticket_no_tickets'), style: TextStyle(color: AppColors.textGrey)))
                  : Column(
                      children: [
                        Expanded(
                          child: NestedScrollView(
                            headerSliverBuilder: (_, __) => [
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.all(16.w),
                                  child: Column(
                                    children: [
                                      _InfoCard(detail: detail, tr: tr, onClose: closeTicket),
                                      SizedBox(height: 12.h),
                                      TabBar(
                                        indicatorColor: AppColors.primary,
                                        labelColor: AppColors.primary,
                                        unselectedLabelColor: AppColors.textGrey,
                                        tabs: [
                                          Tab(text: tr('ticket_tab_all')),
                                          Tab(text: '${tr('ticket_tab_attachments')} ($attachmentCount)'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            body: TabBarView(
                              children: [
                                _ConversationList(detail: detail),
                                _AttachmentsList(detail: detail, controller: controller, tr: tr),
                              ],
                            ),
                          ),
                        ),
                        if (detail.status.toLowerCase() == 'open') _ReplyBar(),
                      ],
                    ),
        );
      }),
    );
  }

  Widget _ReplyBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 10.h),
        decoration: BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.4)))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyAttachmentName != null)
              Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
                decoration: BoxDecoration(color: AppColors.chipSurface, borderRadius: BorderRadius.circular(10.r)),
                child: Row(
                  children: [
                    Icon(Icons.attach_file, size: 16.h, color: AppColors.primary),
                    SizedBox(width: 6.w),
                    Expanded(child: Text(replyAttachmentName!, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textPrimary, fontSize: 12.sp))),
                    GestureDetector(onTap: () => setState(() { replyAttachment = null; replyAttachmentName = null; }), child: Icon(Icons.close, size: 16.h, color: AppColors.error)),
                  ],
                ),
              ),
            Row(
              children: [
                IconButton(onPressed: pickReplyAttachment, icon: Icon(Icons.attach_file, color: AppColors.primary)),
                Expanded(
                  child: TextField(
                    controller: replyController,
                    minLines: 1,
                    maxLines: 4,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
                    decoration: InputDecoration(
                      hintText: tr('ticket_reply_placeholder'),
                      filled: true,
                      fillColor: AppColors.backgroundLight,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Obx(() => CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: controller.isSubmitting.value
                          ? SizedBox(width: 16.w, height: 16.w, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : IconButton(onPressed: sendReply, icon: const Icon(Icons.send, color: Colors.white, size: 18)),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final TicketDetail detail;
  final String Function(String) tr;
  final VoidCallback onClose;

  const _InfoCard({required this.detail, required this.tr, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final isOpen = detail.status.toLowerCase() == 'open';
    return Container(
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18.r), border: Border.all(color: AppColors.border.withValues(alpha: 0.45))),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: EdgeInsets.symmetric(horizontal: 14.w),
        childrenPadding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.icongrey,
        title: Text(detail.title, style: TextStyle(color: AppColors.textPrimary, fontSize: 16.sp, fontWeight: FontWeight.w700)),
        subtitle: Text(detail.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textGrey, fontSize: 12.sp)),
        children: [
          _InfoRow(label: tr('ticket_reference'), value: '#${detail.id}'),
          _InfoRow(label: tr('ticket_status'), value: detail.status.toUpperCase()),
          _InfoRow(label: tr('ticket_department'), value: detail.department),
          _InfoRow(label: tr('ticket_priority'), value: detail.priority.toUpperCase()),
          _InfoRow(label: tr('ticket_created'), value: _formatDate(detail.createdAt)),
          _InfoRow(label: tr('ticket_assignee'), value: detail.assignee.name),
          if (isOpen) ...[
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onClose,
                icon: Icon(Icons.lock_outline, size: 16.h),
                label: Text(tr('ticket_close')),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: BorderSide(color: AppColors.error.withValues(alpha: 0.5))),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: AppColors.textGrey, fontSize: 12.sp))),
          Text(value, style: TextStyle(color: AppColors.textPrimary, fontSize: 12.sp, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ConversationList extends StatelessWidget {
  final TicketDetail detail;

  const _ConversationList({required this.detail});

  @override
  Widget build(BuildContext context) {
    if (detail.conversation.isEmpty) {
      return Center(child: Text('No conversation yet', style: TextStyle(color: AppColors.textGrey)));
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 18.h),
      itemCount: detail.conversation.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        final item = detail.conversation[index];
        return Align(
          alignment: item.isCustomer ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: item.isCustomer ? AppColors.primary.withValues(alpha: 0.12) : AppColors.card,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.author.name, style: TextStyle(color: AppColors.textPrimary, fontSize: 12.sp, fontWeight: FontWeight.w700)),
                SizedBox(height: 5.h),
                Text(item.content, style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp, height: 1.35)),
                SizedBox(height: 5.h),
                Text(_formatDateTime(item.timestamp), style: TextStyle(color: AppColors.textGrey, fontSize: 10.sp)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AttachmentsList extends StatelessWidget {
  final TicketDetail detail;
  final TicketController controller;
  final String Function(String) tr;

  const _AttachmentsList({required this.detail, required this.controller, required this.tr});

  @override
  Widget build(BuildContext context) {
    final attachment = detail.attachment;
    if (attachment == null) {
      return Center(child: Text(tr('ticket_tab_attachments'), style: TextStyle(color: AppColors.textGrey)));
    }
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 18.h),
      children: [
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: AppColors.border.withValues(alpha: 0.4))),
          child: Row(
            children: [
              Container(width: 42.w, height: 42.w, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12.r)), child: Icon(Icons.insert_drive_file_outlined, color: AppColors.primary)),
              SizedBox(width: 10.w),
              Expanded(child: Text(attachment.filename, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w600))),
              TextButton.icon(onPressed: () => controller.downloadAttachment(attachment.url.isNotEmpty ? attachment.url : attachment.path), icon: Icon(Icons.download, size: 16.h), label: Text(tr('ticket_download'))),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}

String _formatDateTime(DateTime? date) {
  if (date == null) return '-';
  final local = date.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${_formatDate(local)} $hour:$minute';
}
