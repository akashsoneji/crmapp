import 'dart:io';

import 'package:crm_app/constants/color.dart';
import 'package:crm_app/controllers/kyc/compliance_controller.dart';
import 'package:crm_app/models/kyc_document_config.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/widgets/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Regulated-broker onboarding: questionnaire (step 0) then unified KYC
/// documents (step 1). Shown when `User.mustSubmitRegulation` is true.
class UnifiedComplianceWizardScreen extends StatefulWidget {
  const UnifiedComplianceWizardScreen({super.key});

  @override
  State<UnifiedComplianceWizardScreen> createState() =>
      _UnifiedComplianceWizardScreenState();
}

class _UnifiedComplianceWizardScreenState
    extends State<UnifiedComplianceWizardScreen> {
  late final ComplianceController controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    controller =
        Get.isRegistered<ComplianceController>()
            ? Get.find<ComplianceController>()
            : Get.put(ComplianceController());
  }

  String _t(String key, String fallback) => TranslationUtils.trf(key, fallback);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (controller.currentStep.value > 0) {
          controller.currentStep.value = 0;
        } else {
          _showExitConfirmation();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.card,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text(
            _t('kyc_verification', 'KYC Verification'),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.close, color: AppColors.textPrimary),
              onPressed: _showExitConfirmation,
            ),
          ],
        ),
        body: SafeArea(
          child: Obx(() {
            if (controller.isSchemaLoading.value) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            final step = controller.currentStep.value;
            return Column(
              children: [
                _StepHeader(currentStep: step),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child:
                        step == 0 ? _buildQuestionnaire() : _buildDocuments(),
                  ),
                ),
                _buildBottomBar(step),
              ],
            );
          }),
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _t('unified_compliance_wizard_verify_later', 'Verify later?'),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          _t(
            'unified_compliance_wizard_you_can_continue_later_but_you',
            'You can continue later, but some features stay locked until verification is complete.',
          ),
          style: TextStyle(color: AppColors.textGrey, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              Get.back();
            },
            child: Text(
              _t('unified_compliance_wizard_verify_later_button', 'Verify Later'),
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.whiteColor,
              elevation: 0,
            ),
            child: Text(_t('account_created_continue', 'Continue')),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionnaire() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCard(
            title: _t(
              'unified_compliance_wizard_basic_profile_information',
              'Basic Profile Information',
            ),
            children: [
              _textField('email', _t('tw_email', 'Email'), readOnly: true),
              _textField(
                'mobile',
                _t('edit_profile_mobile_number', 'Mobile Number'),
                keyboardType: TextInputType.phone,
              ),
              _mobileStatus(),
              _textField(
                'first_name',
                _t('create_account_screen_first_name', 'First Name'),
              ),
              _textField(
                'last_name',
                _t('create_account_screen_last_name', 'Last Name'),
              ),
              _optionsField(
                'title',
                _t('unified_compliance_wizard_title_selector', 'Title'),
                const [
                  {'value': 'Mr', 'label': 'Mr'},
                  {'value': 'Mrs', 'label': 'Mrs'},
                  {'value': 'Ms', 'label': 'Ms'},
                  {'value': 'Dr', 'label': 'Dr'},
                  {'value': 'Other', 'label': 'Other'},
                ],
              ),
              _optionsField(
                'gender',
                _t('unified_compliance_wizard_gender_selector', 'Gender'),
                [
                  {
                    'value': 'male',
                    'label': _t('unified_compliance_wizard_male', 'Male'),
                  },
                  {
                    'value': 'female',
                    'label': _t('unified_compliance_wizard_female', 'Female'),
                  },
                  {
                    'value': 'other',
                    'label': _t('unified_compliance_wizard_other', 'Other'),
                  },
                ],
              ),
              _dateField(
                'dob',
                _t('unified_compliance_wizard_date_of_birth_dd_mm_yyyy', 'Date of Birth'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: _t(
              'unified_compliance_wizard_residential_address',
              'Residential Address',
            ),
            children: [
              _locationField('country', _t('register_country', 'Country')),
              _locationField(
                'nationality',
                _t('unified_compliance_wizard_nationality', 'Nationality'),
              ),
              _locationField('state', _t('edit_profile_state', 'State')),
              _locationField('city', _t('edit_profile_city', 'City')),
              _textField(
                'address_1',
                _t('unified_compliance_wizard_address_line_1', 'Address Line 1'),
              ),
              _textField(
                'address_2',
                _t(
                  'unified_compliance_wizard_address_line_2_optional',
                  'Address Line 2 (Optional)',
                ),
                isRequired: false,
              ),
              _textField(
                'postcode',
                _t('unified_compliance_wizard_pincode_zip', 'Pincode / ZIP'),
              ),
            ],
          ),
          if (controller.schemaFields.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: _t(
                'unified_compliance_wizard_compliance_information',
                'Compliance Information',
              ),
              children: [_schemaFields()],
            ),
          ],
        ],
      ),
    );
  }

  Widget _schemaFields() {
    return Obx(() {
      // Touch formAnswers so visible_when conditions re-evaluate on change.
      controller.formAnswers.length;
      final fields =
          controller.schemaFields
              .whereType<Map<String, dynamic>>()
              .where(controller.isFieldVisible)
              .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: fields.map(_schemaField).toList(),
      );
    });
  }

  Widget _schemaField(Map<String, dynamic> field) {
    final type = field['field_type']?.toString() ?? '';
    final key = field['field_key']?.toString() ?? '';
    final label = field['label']?.toString() ?? key;
    final isRequired = field['is_required'] == true;

    if (type == 'info') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    if (type == 'radio' || type == 'select') {
      final options =
          (field['options'] is List ? field['options'] as List : const [])
              .whereType<Map>()
              .map(
                (o) => {
                  'value': o['value']?.toString() ?? '',
                  'label': o['label']?.toString() ?? '',
                },
              )
              .toList();
      return _optionsField(key, label, options, isRequired: isRequired);
    }

    return _textField(key, label, isRequired: isRequired);
  }

  Widget _buildDocuments() {
    return Obx(() {
      final config = controller.effectiveDocumentConfig;
      final hasConfig = controller.documentConfig.value != null;

      if (controller.isDocumentConfigLoading.value && !hasConfig) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (!hasConfig && controller.documentConfigError.value.isNotEmpty) {
        return _DocumentConfigError(
          message: controller.documentConfigError.value,
          retryLabel: _t('kyc_doc_retry', 'Retry'),
          onRetry: controller.fetchDocumentConfig,
        );
      }
      if (config.isProviderMode) {
        return _InfoBanner(
          message: _t(
            'kyc_doc_provider_mode',
            "Your verification is handled by our verification partner, so documents can't be uploaded here.",
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t(
              'unified_compliance_wizard_upload_verification_documents',
              'Upload Verification Documents',
            ),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _t(
              'unified_compliance_wizard_supported_formats_jpg_png_pdf_max',
              'Supported formats: JPG, PNG, PDF (max 15MB)',
            ),
            style: TextStyle(color: AppColors.textGrey, fontSize: 12),
          ),
          if (config.isReupload) ...[
            const SizedBox(height: 12),
            _InfoBanner(
              message: _t(
                'kyc_doc_reupload_hint',
                'Some documents were rejected. Upload only the rejected sides again.',
              ),
            ),
          ],
          const SizedBox(height: 16),
          _SectionCard(
            title: _t(
              'unified_compliance_wizard_identity_document',
              'Identity Document',
            ),
            children: [_documentCategory(config, kycIdProof)],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: _t('kyc_address_proof', 'Address Proof'),
            children: [_documentCategory(config, kycAddressProof)],
          ),
        ],
      );
    });
  }

  /// Option dropdown (first submit only), then the sides to upload. Sides
  /// already on the server and not rejected show their status instead.
  Widget _documentCategory(KycDocumentConfig config, String category) {
    final options = config.optionsFor(category);
    final showDropdown = options.isNotEmpty && !config.isReupload;
    final error = controller.documentErrors[category];
    final sides = [
      for (final side in const [kycSideFront, kycSideBack])
        if (controller.sideAcceptsUpload(category, side) ||
            config.documentFor(category, side) != null)
          side,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDropdown) ...[
          _optionDropdown(category, options),
          const SizedBox(height: 12),
        ],
        if (sides.isEmpty)
          Text(
            _t(
              'kyc_doc_pick_document_first',
              'Select a document type to see which sides to upload.',
            ),
            style: TextStyle(color: AppColors.textGrey, fontSize: 12),
          )
        else
          Row(
            children: [
              for (var i = 0; i < sides.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: _sideTile(config, category, sides[i])),
              ],
              // Keep a single side at half width, like the two-side layout.
              if (sides.length == 1) ...[
                const SizedBox(width: 12),
                const Expanded(child: SizedBox.shrink()),
              ],
            ],
          ),
        if (error != null && error.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(error, style: TextStyle(color: AppColors.errorText, fontSize: 12)),
        ],
      ],
    );
  }

  Widget _sideTile(KycDocumentConfig config, String category, String side) {
    final label = side == kycSideFront
        ? _t('id_upload_front_side', 'Front Side')
        : _t('id_upload_back_side', 'Back Side');
    if (!controller.sideAcceptsUpload(category, side)) {
      final submitted = config.documentFor(category, side)!;
      return _SubmittedSideTile(
        label: label,
        optionName: submitted.documentOptionName,
        status: submitted.status,
        statusLabel: submitted.status == 'approved'
            ? _t('kyc_doc_status_approved', 'Approved')
            : _t('kyc_doc_status_pending', 'Under review'),
      );
    }
    final target = controller.fileFor(category, side);
    return _UploadBox(
      label: label,
      file: target.value,
      isRequired: controller.isSideRequired(category, side),
      onPick: () => controller.pickDocument(target),
      onClear: () => controller.clearDocument(target),
    );
  }

  Widget _optionDropdown(String category, List<KycDocumentOption> options) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          dropdownColor: AppColors.card,
          value: controller.pickedOptionFor(category)?.id,
          hint: Text(
            _t('kyc_doc_select_document_type', 'Select document type'),
            style: TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
          items: [
            for (final option in options)
              DropdownMenuItem<String>(
                value: option.id,
                child: Text(
                  option.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                ),
              ),
          ],
          onChanged: (id) => controller.selectDocumentOption(
            category,
            options.firstWhereOrNull((option) => option.id == id),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(int step) {
    final isLoading = controller.isLoading.value;
    // Required-side rules are checked on submit (with an inline message), so
    // the button only needs at least one file and a manual-mode config.
    final canSubmitDocs = controller.selectedDocumentCount > 0 &&
        !controller.effectiveDocumentConfig.isProviderMode;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          if (step == 1) ...[
            OutlinedButton(
              onPressed: isLoading ? null : () => controller.currentStep.value = 0,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.border),
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _t('legal_docs_back', 'Back'),
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed:
                  isLoading || (step == 1 && !canSubmitDocs)
                      ? null
                      : () => step == 0 ? _submitStep1() : _submitStep2(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.whiteColor,
                disabledBackgroundColor: AppColors.border,
                minimumSize: const Size(0, 48),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  isLoading
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.whiteColor,
                        ),
                      )
                      : Text(
                        step == 0
                            ? _t(
                              'unified_compliance_wizard_update_profile_continue',
                              'Update Profile & Continue',
                            )
                            : _t(
                              'unified_compliance_wizard_confirm_submit',
                              'Confirm & Submit',
                            ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitStep1() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await controller.submitQuestionnaire();
  }

  Future<void> _submitStep2() async {
    final success = await controller.submitDocuments();
    if (success) Get.back(result: true);
  }

  Widget _textField(
    String key,
    String label, {
    bool isRequired = true,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        initialValue: controller.formAnswers[key]?.toString() ?? '',
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: TextStyle(
          color: readOnly ? AppColors.textGrey : AppColors.textPrimary,
          fontSize: 14,
        ),
        decoration: _decoration(label, isRequired),
        onChanged: (value) {
          controller.formAnswers[key] = value;
          if (key == 'mobile') {
            controller.checkMobileAvailability(value, '');
          }
        },
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return _t('unified_compliance_wizard_required', 'Required');
          }
          return null;
        },
      ),
    );
  }

  Widget _mobileStatus() {
    return Obx(() {
      if (controller.isCheckingMobile.value) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            _t(
              'unified_compliance_wizard_checking_availability',
              'Checking availability...',
            ),
            style: TextStyle(color: AppColors.textGrey, fontSize: 12),
          ),
        );
      }
      if (!controller.isMobileAvailable.value &&
          controller.mobileError.value.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            controller.mobileError.value,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }

  InputDecoration _decoration(String label, bool isRequired) {
    return InputDecoration(
      labelText: isRequired ? '$label *' : label,
      labelStyle: TextStyle(color: AppColors.textGrey, fontSize: 13),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Widget _selectorTile({
    required String label,
    required String value,
    required VoidCallback? onTap,
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: _decoration(label, isRequired).copyWith(
            suffixIcon: Icon(Icons.arrow_drop_down, color: AppColors.textGrey),
          ),
          isEmpty: value.isEmpty,
          child: Text(
            value,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _optionsField(
    String key,
    String label,
    List<Map<String, String>> options, {
    bool isRequired = true,
  }) {
    return Obx(() {
      final current = controller.formAnswers[key]?.toString() ?? '';
      final selected =
          options.firstWhereOrNull((o) => o['value'] == current)?['label'] ??
          '';
      return _selectorTile(
        label: label,
        value: selected,
        isRequired: isRequired,
        onTap:
            () => _showPicker<Map<String, String>>(
              title: label,
              items: options,
              labelOf: (o) => o['label'] ?? '',
              onSelected: (o) => controller.formAnswers[key] = o['value'] ?? '',
            ),
      );
    });
  }

  Widget _dateField(String key, String label) {
    return Obx(() {
      final value = controller.formAnswers[key]?.toString() ?? '';
      return _selectorTile(
        label: label,
        value: value,
        onTap: () async {
          final now = DateTime.now();
          final lastDate = DateTime(now.year - 18, now.month, now.day);
          final firstDate = DateTime(1930);
          // Clamp: a stored DOB outside the range makes showDatePicker throw.
          final parsed = DateTime.tryParse(value);
          DateTime initial = lastDate;
          if (parsed != null) {
            if (parsed.isBefore(firstDate)) {
              initial = firstDate;
            } else if (!parsed.isAfter(lastDate)) {
              initial = parsed;
            }
          }
          final picked = await showDatePicker(
            context: context,
            initialDate: initial,
            firstDate: firstDate,
            lastDate: lastDate,
          );
          if (picked != null) {
            controller.formAnswers[key] = picked.toIso8601String().split('T')[0];
          }
        },
      );
    });
  }

  Widget _locationField(String type, String label) {
    final dropdown = controller.dropdownService;
    return Obx(() {
      switch (type) {
        case 'country':
          // Country comes from the registered profile and is not editable here.
          return _selectorTile(
            label: label,
            value: dropdown.selectedCountry.value?.name ?? '',
            onTap: null,
          );
        case 'nationality':
          return _selectorTile(
            label: label,
            value: controller.formAnswers['nationality']?.toString() ?? '',
            onTap:
                () => _showPicker(
                  title: label,
                  items:
                      dropdown.countries
                          .where((c) => (c.nationality ?? '').isNotEmpty)
                          .toList(),
                  labelOf: (c) => c.nationality ?? '',
                  onSelected:
                      (c) =>
                          controller.formAnswers['nationality'] =
                              c.nationality ?? '',
                ),
          );
        case 'state':
          return _selectorTile(
            label: label,
            value: dropdown.selectedState.value?.name ?? '',
            onTap: () {
              if (dropdown.selectedCountry.value == null) {
                CustomToastService.showWarning(
                  message: _t(
                    'unified_compliance_wizard_please_select_country_first',
                    'Please select country first',
                  ),
                );
                return;
              }
              _showPicker(
                title: label,
                items: dropdown.states.toList(),
                labelOf: (s) => s.name,
                onSelected: dropdown.selectState,
              );
            },
          );
        default:
          return _selectorTile(
            label: label,
            value: dropdown.selectedCity.value?.name ?? '',
            onTap: () {
              if (dropdown.selectedState.value == null) {
                CustomToastService.showWarning(
                  message: _t(
                    'unified_compliance_wizard_please_select_state_first',
                    'Please select state first',
                  ),
                );
                return;
              }
              _showPicker(
                title: label,
                items: dropdown.cities.toList(),
                labelOf: (c) => c.name,
                onSelected: dropdown.selectCity,
              );
            },
          );
      }
    });
  }

  void _showPicker<T>({
    required String title,
    required List<T> items,
    required String Function(T) labelOf,
    required void Function(T) onSelected,
  }) {
    final query = ''.obs;
    Get.bottomSheet(
      ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (items.length > 8) ...[
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => query.value = v.toLowerCase(),
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: AppColors.textGrey),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Flexible(
                child: Obx(() {
                  final filtered =
                      items
                          .where(
                            (i) => labelOf(i).toLowerCase().contains(query.value),
                          )
                          .toList();
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (_, index) {
                      final item = filtered[index];
                      return ListTile(
                        title: Text(
                          labelOf(item),
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                        onTap: () {
                          onSelected(item);
                          Get.back();
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final labels = [
      TranslationUtils.trf('global_drawer_profile', 'Profile'),
      TranslationUtils.trf('unified_compliance_wizard_documents', 'Documents'),
    ];
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color:
                      currentStep >= i ? AppColors.primary : AppColors.border,
                ),
              ),
            CircleAvatar(
              radius: 14,
              backgroundColor:
                  currentStep >= i ? AppColors.primary : AppColors.border,
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  color: AppColors.whiteColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              labels[i],
              style: TextStyle(
                color:
                    currentStep == i ? AppColors.primary : AppColors.textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          Divider(color: AppColors.border, height: 24),
          ...children,
        ],
      ),
    );
  }
}

class _UploadBox extends StatelessWidget {
  const _UploadBox({
    required this.label,
    required this.file,
    required this.isRequired,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final File? file;
  final bool isRequired;
  final VoidCallback onPick;
  final VoidCallback onClear;

  bool get _isImage {
    final path = file?.path.toLowerCase() ?? '';
    return path.endsWith('.png') ||
        path.endsWith('.jpg') ||
        path.endsWith('.jpeg');
  }

  @override
  Widget build(BuildContext context) {
    final selected = file;
    return AspectRatio(
      aspectRatio: 1.25,
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected != null ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (selected == null)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      isRequired
                          ? TranslationUtils.trf(
                            'unified_compliance_wizard_required',
                            'Required',
                          )
                          : TranslationUtils.trf(
                            'kyc_docs_screen_optional',
                            'Optional',
                          ),
                      style: TextStyle(
                        color: isRequired ? Colors.red : AppColors.textGrey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                )
              else if (_isImage)
                Image.file(selected, fit: BoxFit.cover)
              else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      selected.path.split('/').last,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              if (selected != null)
                PositionedDirectional(
                  top: 6,
                  end: 6,
                  child: GestureDetector(
                    onTap: onClear,
                    child: const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.delete, size: 14, color: Colors.white),
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

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.warningText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: AppColors.warningText, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentConfigError extends StatelessWidget {
  const _DocumentConfigError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: AppColors.errorText),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}

/// A side already on the server (pending or approved); it can't be replaced.
class _SubmittedSideTile extends StatelessWidget {
  const _SubmittedSideTile({
    required this.label,
    required this.optionName,
    required this.status,
    required this.statusLabel,
  });

  final String label;
  final String optionName;
  final String status;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final isApproved = status == 'approved';
    final statusColor =
        isApproved ? AppColors.successText : AppColors.warningText;
    return AspectRatio(
      aspectRatio: 1.25,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isApproved ? AppColors.successBg : AppColors.warningBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isApproved ? Icons.verified_outlined : Icons.hourglass_top,
              color: statusColor,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (optionName.isNotEmpty)
              Text(
                optionName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textGrey, fontSize: 10),
              ),
            Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
