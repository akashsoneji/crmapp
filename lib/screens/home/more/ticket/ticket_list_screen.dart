import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/controllers/ticket_controller.dart';
import 'package:crm_app/models/ticket_model.dart';
import 'package:crm_app/routes/app_pages.dart';
import 'package:crm_app/services/language_service.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  final TicketController controller = Get.find<TicketController>();
  final LanguageService languageService = Get.find<LanguageService>();
  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  Worker? searchWorker;

  @override
  void initState() {
    super.initState();
    searchController.text = controller.searchQuery.value;
    scrollController.addListener(_onScroll);
    searchWorker = debounce<String>(
      controller.searchQuery,
      (_) => controller.fetchTickets(refresh: true),
      time: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    searchController.dispose();
    searchWorker?.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 180) {
      controller.fetchTickets();
    }
  }

  String tr(String key) => languageService.tr(key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        title: Text(tr('ticket_title'), style: TextStyle(color: AppColors.textPrimary, fontSize: 18.sp, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20.h),
          onPressed: Get.back,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onColoredBackground,
        onPressed: () => Get.toNamed(AppPages.TICKET_CREATE),
        icon: const Icon(Icons.add),
        label: Text(tr('ticket_new_ticket')),
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.fetchTickets(refresh: true),
        color: AppColors.primary,
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DepartmentChips(controller: controller, tr: tr),
                    SizedBox(height: 14.h),
                    _SearchField(controller: controller, textController: searchController, tr: tr),
                    SizedBox(height: 12.h),
                    _FilterRow(controller: controller, tr: tr),
                  ],
                ),
              ),
            ),
            Obx(() {
              if (controller.isLoading.value) {
                return SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                );
              }
              if (controller.tickets.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(controller: controller, tr: tr),
                );
              }
              return SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 90.h),
                sliver: SliverList.separated(
                  itemCount: controller.tickets.length + (controller.isPageLoading.value ? 1 : 0),
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    if (index >= controller.tickets.length) {
                      return Padding(
                        padding: EdgeInsets.all(16.h),
                        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      );
                    }
                    return _TicketCard(ticket: controller.tickets[index]);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DepartmentChips extends StatelessWidget {
  final TicketController controller;
  final String Function(String) tr;

  const _DepartmentChips({required this.controller, required this.tr});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = [
        const TicketDepartment(id: 0, name: 'All Tickets', icon: ''),
        ...controller.departments,
      ];
      return SizedBox(
        height: 40.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => SizedBox(width: 8.w),
          itemBuilder: (context, index) {
            final department = items[index];
            final value = department.id == 0 ? 'all' : department.id.toString();
            final selected = controller.selectedDepartment.value == value;
            return ChoiceChip(
              label: Text(department.id == 0 ? tr('ticket_all_tickets') : department.name),
              selected: selected,
              onSelected: (_) => controller.updateDepartment(value),
              selectedColor: AppColors.selectedChipBackground,
              backgroundColor: AppColors.chipSurface,
              labelStyle: TextStyle(color: selected ? AppColors.selectedChipForeground : AppColors.textPrimary, fontSize: 13.sp),
              side: BorderSide(color: selected ? AppColors.selectedChipBackground : AppColors.border),
            );
          },
        ),
      );
    });
  }
}

class _SearchField extends StatelessWidget {
  final TicketController controller;
  final TextEditingController textController;
  final String Function(String) tr;

  const _SearchField({required this.controller, required this.textController, required this.tr});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: textController,
      onChanged: (value) => controller.searchQuery.value = value,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
      decoration: InputDecoration(
        hintText: tr('ticket_search_placeholder'),
        prefixIcon: Icon(Icons.search, color: AppColors.icongrey, size: 20.h),
        filled: true,
        fillColor: AppColors.card,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide(color: AppColors.primary)),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final TicketController controller;
  final String Function(String) tr;

  const _FilterRow({required this.controller, required this.tr});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Obx(() => _FilterDropdown(
                value: controller.selectedStatus.value,
                items: {'all': tr('ticket_all_status'), 'open': tr('ticket_status_open'), 'closed': tr('ticket_status_closed')},
                onChanged: controller.updateStatus,
              )),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Obx(() => _FilterDropdown(
                value: controller.selectedPriority.value,
                items: {
                  'all': tr('ticket_all_priority'),
                  'low': tr('ticket_priority_low'),
                  'medium': tr('ticket_priority_medium'),
                  'high': tr('ticket_priority_high'),
                },
                onChanged: controller.updatePriority,
              )),
        ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14.r), border: Border.all(color: AppColors.border)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.card,
          icon: Icon(Icons.keyboard_arrow_down, color: AppColors.icongrey),
          style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp),
          items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Ticket ticket;

  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final isOpen = ticket.status.toLowerCase() == 'open';
    return InkWell(
      borderRadius: BorderRadius.circular(18.r),
      onTap: () => Get.toNamed(AppPages.TICKET_DETAIL, arguments: ticket.id),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18.r), border: Border.all(color: AppColors.border.withValues(alpha: 0.45))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('#${ticket.id}', style: TextStyle(color: AppColors.textGrey, fontSize: 12.sp, fontWeight: FontWeight.w500))),
                _Badge(label: ticket.status.toUpperCase(), background: isOpen ? AppColors.successBg : AppColors.errorBg, foreground: isOpen ? AppColors.successText : AppColors.errorText),
              ],
            ),
            SizedBox(height: 8.h),
            Text(ticket.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textPrimary, fontSize: 16.sp, fontWeight: FontWeight.w700)),
            SizedBox(height: 5.h),
            Text(ticket.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textGrey, fontSize: 13.sp, height: 1.35)),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _MiniInfo(icon: Icons.category_outlined, label: ticket.department),
                _MiniInfo(icon: Icons.priority_high_rounded, label: ticket.priority.toUpperCase()),
                _MiniInfo(icon: Icons.forum_outlined, label: '${ticket.conversationCount}'),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                CircleAvatar(radius: 13.r, backgroundColor: AppColors.primary.withValues(alpha: 0.12), child: Text(ticket.assignee.name.isEmpty ? '?' : ticket.assignee.name[0], style: TextStyle(color: AppColors.primary, fontSize: 12.sp))),
                SizedBox(width: 8.w),
                Expanded(child: Text(ticket.assignee.name, style: TextStyle(color: AppColors.textGrey, fontSize: 12.sp))),
                Text(_formatDate(ticket.createdAt), style: TextStyle(color: AppColors.textGrey, fontSize: 12.sp)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _Badge({required this.label, required this.background, required this.foreground});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20.r)),
      child: Text(label, style: TextStyle(color: foreground, fontSize: 10.sp, fontWeight: FontWeight.w700)),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniInfo({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.h, color: AppColors.icongrey),
        SizedBox(width: 4.w),
        Text(label, style: TextStyle(color: AppColors.textGrey, fontSize: 12.sp)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final TicketController controller;
  final String Function(String) tr;

  const _EmptyState({required this.controller, required this.tr});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.confirmation_number_outlined, size: 62.h, color: AppColors.icongrey),
          SizedBox(height: 14.h),
          Text(tr('ticket_no_tickets'), style: TextStyle(color: AppColors.textPrimary, fontSize: 18.sp, fontWeight: FontWeight.w700)),
          SizedBox(height: 6.h),
          Text(tr('ticket_no_tickets_subtitle'), textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGrey, fontSize: 14.sp)),
          SizedBox(height: 16.h),
          OutlinedButton(onPressed: controller.clearFilters, child: Text(tr('ticket_clear_filters'))),
        ],
      ),
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}
