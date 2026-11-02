import 'dart:io';

import 'package:crm_app/constants/api_const.dart';
import 'package:crm_app/controllers/auth_controller.dart';
import 'package:crm_app/models/dropdown_models.dart';
import 'package:crm_app/models/kyc_document_config.dart';
import 'package:crm_app/services/api_service.dart';
import 'package:crm_app/services/dropdown_service.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/services/secure_storage_service.dart';
import 'package:crm_app/widgets/custom_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

/// Unified compliance (regulated broker) flow:
/// step 0 = dynamic regulation questionnaire, step 1 = unified KYC documents.
class ComplianceController extends GetxController {
  static const int _maxDocumentBytes = 15 * 1024 * 1024;

  final AuthController _authController = Get.find<AuthController>();

  final RxBool isLoading = false.obs;
  final RxBool isSchemaLoading = false.obs;
  final RxBool isCheckingMobile = false.obs;
  final RxBool isMobileAvailable = true.obs;
  final RxString mobileError = ''.obs;

  final RxInt currentStep = 0.obs;

  final RxList<dynamic> schemaFields = <dynamic>[].obs;
  final RxMap<String, dynamic> formAnswers = <String, dynamic>{}.obs;

  final Rx<File?> idProofFront = Rx<File?>(null);
  final Rx<File?> idProofBack = Rx<File?>(null);
  final Rx<File?> addressProofFront = Rx<File?>(null);
  final Rx<File?> addressProofBack = Rx<File?>(null);

  // Document options from `GET user/kyc` (admin toggles).
  static const KycDocumentConfig _emptyDocumentConfig = KycDocumentConfig(
    kycMode: 'manual',
    idProofOptions: [],
    addressProofOptions: [],
    requiredBackSides: [],
    documents: [],
    documentsSubmitted: false,
    hasRejectedDocuments: false,
  );
  final Rxn<KycDocumentConfig> documentConfig = Rxn<KycDocumentConfig>();
  final RxBool isDocumentConfigLoading = false.obs;
  final RxString documentConfigError = ''.obs;
  final Rxn<KycDocumentOption> selectedIdOption = Rxn<KycDocumentOption>();
  final Rxn<KycDocumentOption> selectedAddressOption = Rxn<KycDocumentOption>();

  /// Inline error per category (`id_proof` / `address_proof`).
  final RxMap<String, String> documentErrors = <String, String>{}.obs;

  late final DropdownService dropdownService;

  @override
  void onInit() {
    super.onInit();
    dropdownService =
        Get.isRegistered<DropdownService>()
            ? Get.find<DropdownService>()
            : Get.put(DropdownService());

    ever(dropdownService.selectedCountry, (CountryModel? country) {
      if (country != null) {
        formAnswers['country'] = country.id.toString();
        formAnswers['country_name'] = country.name ?? '';
        formAnswers['state'] = '';
        formAnswers['state_name'] = '';
        formAnswers['city'] = '';
        formAnswers['city_name'] = '';
      } else {
        formAnswers['country'] = '';
        formAnswers['country_name'] = '';
      }
    });

    ever(dropdownService.selectedState, (StateModel? state) {
      if (state != null) {
        formAnswers['state'] = state.id.toString();
        formAnswers['state_name'] = state.name;
        formAnswers['city'] = '';
        formAnswers['city_name'] = '';
      } else {
        formAnswers['state'] = '';
        formAnswers['state_name'] = '';
      }
    });

    ever(dropdownService.selectedCity, (CityModel? city) {
      if (city != null) {
        formAnswers['city'] = city.id.toString();
        formAnswers['city_name'] = city.name;
      } else {
        formAnswers['city'] = '';
        formAnswers['city_name'] = '';
      }
    });

    _prepopulateFromProfile();
    fetchDocumentConfig();
    fetchRegulationSchema();
  }

  Future<void> _prepopulateFromProfile() async {
    final profile = _authController.profileData;
    if (profile == null) return;

    final user = profile.data.user;
    final details = user.userDetails;

    formAnswers['email'] = user.email;
    formAnswers['mobile'] = user.mobile;
    formAnswers['first_name'] = user.firstName;
    formAnswers['last_name'] = user.lastName;
    formAnswers['title'] = details.title.isNotEmpty ? details.title : 'Mr';
    formAnswers['gender'] = details.gender.isNotEmpty ? details.gender : 'male';
    formAnswers['dob'] = details.dob.toIso8601String().split('T')[0];

    formAnswers['country'] = details.country.toString();
    formAnswers['country_name'] = details.countryName;
    formAnswers['nationality'] = details.nationality;
    formAnswers['state'] = details.state.toString();
    formAnswers['state_name'] = details.stateName;
    formAnswers['city'] = details.city.toString();
    formAnswers['city_name'] = details.cityName;
    formAnswers['address_1'] = details.address1;
    formAnswers['address_2'] = details.address2;
    formAnswers['postcode'] = details.postcode;

    // Questionnaire option defaults (same keys the backend schema uses).
    formAnswers['us_resident'] = 'no';
    formAnswers['multiple_citizenship'] = 'no';
    formAnswers['employment_type'] = 'employed';
    formAnswers['industry'] = 'banking_and_financial_services';
    formAnswers['annual_basic_salary'] = '15000_50000';
    formAnswers['additional_income'] = 'none';
    formAnswers['estimated_total_annual_income'] = 'lt_25000';
    formAnswers['expected_deposit_12m'] = 'lt_5000';
    formAnswers['source_of_funds'] = 'salary';
    formAnswers['origin_of_wealth'] = 'employment_income';
    formAnswers['multi_jurisdiction_tax'] = 'no';
    formAnswers['tax_residence_country'] = details.countryName;
    formAnswers['tin'] = details.taxIdentificationNumber;
    formAnswers['tin_missing_reason'] = 'not_required';

    try {
      if (details.country == 0) return;
      if (dropdownService.countries.isEmpty) {
        await dropdownService.loadCountries();
      }
      final country = dropdownService.countries.firstWhereOrNull(
        (c) => c.id == details.country,
      );
      if (country == null) return;

      dropdownService.selectedCountry.value = country;
      await dropdownService.loadStates(country.id!);

      // The `ever` listeners wipe state/city on country change; re-apply.
      formAnswers['state'] = details.state != 0 ? details.state.toString() : '';
      formAnswers['state_name'] = details.stateName;
      formAnswers['city'] = details.city != 0 ? details.city.toString() : '';
      formAnswers['city_name'] = details.cityName;

      if (details.state == 0) return;
      final state = dropdownService.states.firstWhereOrNull(
        (s) => s.id == details.state,
      );
      if (state == null) return;

      dropdownService.selectedState.value = state;
      await dropdownService.loadCities(state.id);

      formAnswers['city'] = details.city != 0 ? details.city.toString() : '';
      formAnswers['city_name'] = details.cityName;

      if (details.city == 0) return;
      final city = dropdownService.cities.firstWhereOrNull(
        (c) => c.id == details.city,
      );
      if (city != null) {
        dropdownService.selectedCity.value = city;
      }
    } catch (e) {
      print('ComplianceController: Error syncing dropdown service items: $e');
    }
  }

  Future<void> fetchRegulationSchema() async {
    try {
      isSchemaLoading.value = true;
      final token = await SecureStorageService.getAuthToken();
      if (token == null || token.isEmpty) return;

      final response = await ApiService.get(
        endpoint: ApiConstants.regulation,
        token: token,
      );
      if (response.success && response.data != null) {
        final schema = response.data['data']?['schema'];
        if (schema is List) {
          schemaFields.assignAll(schema);
        }
      } else {
        print('ComplianceController: Dynamic schema fetch failed');
      }
    } catch (e) {
      print('ComplianceController: Error fetching schema: $e');
    } finally {
      isSchemaLoading.value = false;
    }
  }

  Future<void> checkMobileAvailability(String mobile, String countryCode) async {
    if (mobile.isEmpty) return;
    try {
      isCheckingMobile.value = true;
      mobileError.value = '';
      final token = await SecureStorageService.getAuthToken();

      final response = await ApiService.post(
        endpoint: ApiConstants.checkMobile,
        token: token,
        data: {'mobile': mobile, 'country_code': countryCode},
      );

      if (response.success) {
        isMobileAvailable.value = true;
      } else {
        isMobileAvailable.value = false;
        mobileError.value =
            response.message ??
            TranslationUtils.trf(
              'compliance_controller_mobile_number_is_already_registered_or',
              'Mobile number is already registered or invalid',
            );
      }
    } catch (e) {
      print('ComplianceController: Error checking mobile number: $e');
    } finally {
      isCheckingMobile.value = false;
    }
  }

  bool isFieldVisible(Map<String, dynamic> field) {
    final visibleWhen = field['visible_when'];
    if (visibleWhen is! Map) return true;

    final String? dependsOn = visibleWhen['field_key']?.toString();
    final String? op = visibleWhen['op']?.toString();
    final dynamic expectedValue = visibleWhen['value'];

    if (dependsOn == null || dependsOn.isEmpty) return true;

    final currentValue = formAnswers[dependsOn];
    if (op == 'equals') {
      return currentValue?.toString().toLowerCase() ==
          expectedValue?.toString().toLowerCase();
    }
    return true;
  }

  String? _firstMissingRequiredLabel() {
    for (final f in schemaFields) {
      if (f is! Map<String, dynamic>) continue;
      final key = f['field_key']?.toString() ?? '';
      final isRequired = f['is_required'] == true;
      if (!isRequired || !isFieldVisible(f)) continue;
      final value = formAnswers[key];
      if (value == null || value.toString().trim().isEmpty) {
        return f['label']?.toString() ?? key;
      }
    }
    return null;
  }

  Map<String, dynamic> _buildRegulationPayload() {
    final snapshot = {
      'title': formAnswers['title'] ?? 'Mr',
      'gender': formAnswers['gender'] ?? 'male',
      'full_name':
          '${formAnswers['first_name'] ?? ''} ${formAnswers['last_name'] ?? ''}'
              .trim(),
      'date_of_birth': formAnswers['dob'] ?? '',
      'nationality': formAnswers['nationality'] ?? '',
      'email': formAnswers['email'] ?? '',
      'mobile': formAnswers['mobile'] ?? '',
      'address_line1': formAnswers['address_1'] ?? 'N/A',
      'address_line2': formAnswers['address_2'] ?? '',
      'postcode': formAnswers['postcode'] ?? '',
      'country_id': formAnswers['country'] ?? '',
      'state_id': formAnswers['state'] ?? '',
      'city_id': formAnswers['city'] ?? '',
      'country_name': formAnswers['country_name'] ?? '',
      'state_name': formAnswers['state_name'] ?? '',
      'city_name': formAnswers['city_name'] ?? '',
    };

    final tin = formAnswers['tin']?.toString() ?? '';
    final isUsResident = formAnswers['us_resident'] == 'yes';

    final payload = Map<String, dynamic>.from(formAnswers);
    payload['profile_snapshot'] = snapshot;
    payload['purpose'] = '';
    payload['purpose_other'] = '';
    payload['place_of_birth'] = '';
    payload['previous_citizenship'] = {'has': false, 'country': ''};
    payload['dual_nationality'] = {'has': false, 'country': ''};
    payload['id_number'] = '';
    payload['id_issue_date'] = '';
    payload['id_expiry_date'] = '';
    payload['office_phone'] = '';
    payload['profession'] = '';
    payload['profession_other'] = '';
    payload['employer'] = {'name': '', 'industry': '', 'job_title': ''};
    payload['trading_experience'] = {'has': false, 'years': 'lt_1'};
    payload['expected_amount_traded'] = '';
    payload['pep'] = {'is_pep': false, 'type': 'pep'};
    payload['hnwi'] = {'is_hnwi': false, 'band': 'lt_500k'};
    payload['fatca'] = {
      'us_citizen': isUsResident,
      'tax_in_us': isUsResident,
      'has_tin': tin.isNotEmpty,
      'tin': tin,
      'tax_residence_country': formAnswers['tax_residence_country'] ?? '',
      'tin_not_applicable_reason': formAnswers['tin_missing_reason'] ?? '',
    };
    payload['deposit_method'] = '';
    payload['hear_about_us'] = '';
    payload['declarations'] = {'not_illegal': true};
    payload['acknowledgement'] = {'read_docs': true, 'info_true': true};
    return payload;
  }

  Map<String, dynamic> _buildProfilePayload() {
    dynamic asId(String key) =>
        int.tryParse(formAnswers[key]?.toString() ?? '') ?? formAnswers[key];

    return {
      'first_name': formAnswers['first_name'] ?? '',
      'last_name': formAnswers['last_name'] ?? '',
      'mobile': formAnswers['mobile'] ?? '',
      'title': formAnswers['title'] ?? 'Mr',
      'gender': formAnswers['gender'] ?? 'other',
      'dob': formAnswers['dob'] ?? '',
      'nationality': formAnswers['nationality'] ?? '',
      'country': asId('country'),
      'state': asId('state'),
      'city': asId('city'),
      'address_1': formAnswers['address_1'] ?? '',
      'address_2': formAnswers['address_2'] ?? '',
      'postcode': formAnswers['postcode'] ?? '',
    };
  }

  Future<String?> _requireTokenAndProfile() async {
    final token = await SecureStorageService.getAuthToken();
    if (token == null || token.isEmpty) {
      CustomToastService.showError(
        message: TranslationUtils.trf(
          'compliance_controller_session_expired_please_log_in_again',
          'Session expired. Please log in again.',
        ),
      );
      return null;
    }
    if (_authController.profileData == null) {
      CustomToastService.showError(
        message: TranslationUtils.trf(
          'compliance_controller_profile_data_missing',
          'Profile data missing',
        ),
      );
      return null;
    }
    return token;
  }

  /// Step 1: saves profile (kyc/profile) then the regulation questionnaire.
  Future<bool> submitQuestionnaire() async {
    final missingLabel = _firstMissingRequiredLabel();
    if (missingLabel != null) {
      CustomToastService.showWarning(
        message:
            '${TranslationUtils.trf('compliance_controller_please_complete_all_required_fields', 'Please complete all required fields')}: $missingLabel',
      );
      return false;
    }

    if (!isMobileAvailable.value) {
      CustomToastService.showError(
        message: TranslationUtils.trf(
          'compliance_controller_please_resolve_mobile_number_errors_before',
          'Please resolve mobile number errors before continuing',
        ),
      );
      return false;
    }

    try {
      isLoading.value = true;
      final token = await _requireTokenAndProfile();
      if (token == null) return false;

      final profileResponse = await ApiService.post(
        endpoint: ApiConstants.kycProfileUpdate,
        token: token,
        data: _buildProfilePayload(),
      );
      if (!profileResponse.success) {
        CustomToastService.showError(
          message:
              profileResponse.message ??
              TranslationUtils.trf(
                'compliance_controller_failed_to_update_profile_details',
                'Failed to update profile details',
              ),
        );
        return false;
      }

      final response = await ApiService.post(
        endpoint: ApiConstants.regulation,
        token: token,
        data: _buildRegulationPayload(),
      );
      if (!response.success) {
        CustomToastService.showError(
          message:
              response.message ??
              TranslationUtils.trf(
                'compliance_controller_failed_to_submit_questionnaire',
                'Failed to submit questionnaire',
              ),
        );
        return false;
      }

      CustomToastService.showSuccess(
        message: TranslationUtils.trf(
          'compliance_controller_regulation_questionnaire_saved_successfully',
          'Regulation questionnaire saved successfully',
        ),
      );
      // Refresh so the profile reflects regulation_submitted = 1.
      await _authController.getProfile();
      currentStep.value = 1;
      return true;
    } catch (e) {
      print('ComplianceController: Error submitting regulation questionnaire: $e');
      CustomToastService.showError(message: 'Submission error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Loads `GET user/kyc`: admin document options, the default-flow back-side
  /// rule, kyc_mode and already submitted sides (for re-upload after reject).
  Future<void> fetchDocumentConfig() async {
    try {
      isDocumentConfigLoading.value = true;
      documentConfigError.value = '';
      final token = await SecureStorageService.getAuthToken();
      if (token == null || token.isEmpty) return;

      final response = await ApiService.get(
        endpoint: ApiConstants.kycStatus,
        token: token,
      );
      final body = response.data;
      if (!response.success || body is! Map<String, dynamic>) {
        documentConfigError.value =
            response.message ?? TranslationUtils.tr('kyc_doc_options_load_failed');
        return;
      }

      final config = KycDocumentConfig.fromKycResponse(body);
      documentConfig.value = config;
      selectedIdOption.value =
          config.resolvePick(kycIdProof, selectedIdOption.value);
      selectedAddressOption.value =
          config.resolvePick(kycAddressProof, selectedAddressOption.value);
      _clearHiddenSides();
    } catch (e) {
      print('ComplianceController: Error fetching KYC document options: $e');
      documentConfigError.value = TranslationUtils.tr('kyc_doc_options_load_failed');
    } finally {
      isDocumentConfigLoading.value = false;
    }
  }

  KycDocumentConfig get effectiveDocumentConfig =>
      documentConfig.value ?? _emptyDocumentConfig;

  KycDocumentOption? pickedOptionFor(String category) =>
      category == kycIdProof ? selectedIdOption.value : selectedAddressOption.value;

  void selectDocumentOption(String category, KycDocumentOption? option) {
    if (category == kycIdProof) {
      selectedIdOption.value = option;
    } else {
      selectedAddressOption.value = option;
    }
    documentErrors.remove(category);
    _clearHiddenSides();
  }

  Rx<File?> fileFor(String category, String side) {
    if (category == kycIdProof) {
      return side == kycSideFront ? idProofFront : idProofBack;
    }
    return side == kycSideFront ? addressProofFront : addressProofBack;
  }

  /// Whether the client has to (or may) attach a file for this side now.
  bool sideAcceptsUpload(String category, String side) {
    final config = effectiveDocumentConfig;
    if (config.isReupload) {
      return config.documentFor(category, side)?.isRejected ?? false;
    }
    return config.isSideVisible(category, side, pickedOptionFor(category));
  }

  bool isSideRequired(String category, String side) {
    final config = effectiveDocumentConfig;
    if (config.isReupload) return sideAcceptsUpload(category, side);
    return config.isSideRequired(category, side, pickedOptionFor(category));
  }

  void _clearHiddenSides() {
    for (final category in const [kycIdProof, kycAddressProof]) {
      for (final side in const [kycSideFront, kycSideBack]) {
        if (!sideAcceptsUpload(category, side)) fileFor(category, side).value = null;
      }
    }
  }

  String _categoryTitle(String category) => category == kycIdProof
      ? TranslationUtils.tr('unified_compliance_wizard_identity_document')
      : TranslationUtils.tr('kyc_address_proof');

  String _sideRequiredMessage(String documentName, String side) {
    final sideLabel = TranslationUtils.tr(
      side == kycSideFront ? 'kyc_doc_side_front' : 'kyc_doc_side_back',
    );
    return TranslationUtils.tr('kyc_doc_side_required')
        .replaceAll('{document}', documentName)
        .replaceAll('{side}', sideLabel);
  }

  /// Mirrors the server's 422 rules so most errors are caught before upload.
  /// Sets an inline error per category and returns the first message.
  String? _validateDocuments(KycDocumentConfig config) {
    documentErrors.clear();
    for (final category in const [kycIdProof, kycAddressProof]) {
      final picked = pickedOptionFor(category);
      if (!config.isReupload &&
          config.optionsFor(category).isNotEmpty &&
          picked == null) {
        documentErrors[category] = TranslationUtils.tr(
          category == kycIdProof
              ? 'kyc_doc_select_identity_option'
              : 'kyc_doc_select_address_option',
        );
        continue;
      }
      for (final side in const [kycSideFront, kycSideBack]) {
        if (!isSideRequired(category, side) || fileFor(category, side).value != null) {
          continue;
        }
        final submittedName =
            config.documentFor(category, side)?.documentOptionName ?? '';
        final name = picked?.name ??
            (submittedName.isNotEmpty ? submittedName : _categoryTitle(category));
        documentErrors[category] = _sideRequiredMessage(name, side);
        break;
      }
    }
    return documentErrors.isEmpty ? null : documentErrors.values.first;
  }

  static String _idOrOthers(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? '0' : text;
  }

  /// Step 2: uploads identity + address proofs in one kyc/submit-unified call.
  Future<bool> submitDocuments() async {
    final config = effectiveDocumentConfig;
    if (config.isProviderMode) {
      CustomToastService.showWarning(
        message: TranslationUtils.tr('kyc_doc_provider_mode'),
      );
      return false;
    }
    final validationError = _validateDocuments(config);
    if (validationError != null) {
      CustomToastService.showWarning(message: validationError);
      return false;
    }

    try {
      isLoading.value = true;
      final token = await _requireTokenAndProfile();
      if (token == null) return false;

      final details = _authController.profileData!.data.user.userDetails;
      final idOption = selectedIdOption.value;
      final addressOption = selectedAddressOption.value;

      // Re-upload: the server remembers the earlier pick and profile, so only
      // the flags and the rejected side(s) are sent.
      final Map<String, String> fields = config.isReupload
          ? {'is_reupload': '1', 'profile_complete': '1'}
          : {
              'title': (formAnswers['title'] ?? details.title).toString(),
              'gender': (formAnswers['gender'] ?? details.gender).toString(),
              'date_of_birth': (formAnswers['dob'] ??
                      details.dob.toIso8601String().split('T')[0])
                  .toString(),
              'country': _idOrOthers(formAnswers['country'] ?? details.country),
              'state': _idOrOthers(formAnswers['state'] ?? details.state),
              'city': _idOrOthers(formAnswers['city'] ?? details.city),
              'address_line1':
                  (formAnswers['address_1'] ?? details.address1).toString(),
              'address_line2': (formAnswers['address_2'] ?? '').toString(),
              'postcode': (formAnswers['postcode'] ?? '').toString(),
              'nationality':
                  (formAnswers['nationality'] ?? details.nationality).toString(),
              if (config.idProofOptions.isNotEmpty && idOption != null)
                'id_proof_option': idOption.id,
              if (config.addressProofOptions.isNotEmpty && addressOption != null)
                'address_proof_option': addressOption.id,
            };

      final files = <String, File>{};
      for (final category in const [kycIdProof, kycAddressProof]) {
        for (final side in const [kycSideFront, kycSideBack]) {
          final file = fileFor(category, side).value;
          if (file == null || !sideAcceptsUpload(category, side)) continue;
          final prefix = category == kycIdProof ? 'identity' : 'address';
          files['${prefix}_$side'] = file;
        }
      }

      final response = await ApiService.uploadMultipleNamedFiles(
        endpoint: ApiConstants.submitUnifiedKyc,
        files: files,
        formData: fields,
        token: token,
      );

      if (!response.success) {
        _handleSubmitError(response);
        return false;
      }

      CustomToastService.showSuccess(
        message: TranslationUtils.trf(
          'compliance_controller_documents_submitted_successfully',
          'Documents submitted successfully',
        ),
      );
      await _authController.getProfile();
      await fetchDocumentConfig();
      return true;
    } catch (e) {
      print('ComplianceController: Error submitting unified KYC: $e');
      CustomToastService.showError(message: 'Submission error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  static const Set<String> _profileFieldKeys = {
    'title',
    'gender',
    'date_of_birth',
    'country',
    'state',
    'city',
    'address_line1',
    'address_line2',
    'postcode',
    'nationality',
  };

  void _handleSubmitError(ApiResponse response) {
    final body = response.data;
    final fieldErrors =
        body is Map && body['errors'] is Map ? body['errors'] as Map : null;

    // Laravel validation shape: a profile field is missing or invalid, so send
    // the client back to the profile step with every message listed.
    if (fieldErrors != null && fieldErrors.isNotEmpty) {
      final messages = fieldErrors.values
          .expand((v) => v is List ? v : [v])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
      CustomToastService.showError(
        message: messages.isNotEmpty
            ? messages.join('\n')
            : (response.message ?? ''),
      );
      if (fieldErrors.keys.any((k) => _profileFieldKeys.contains(k.toString()))) {
        currentStep.value = 0;
      }
      return;
    }

    CustomToastService.showError(
      message: response.message ??
          TranslationUtils.trf(
            'compliance_controller_failed_to_submit_documents',
            'Failed to submit documents',
          ),
    );
    // Document-rule 422s (no option picked, option removed by the admin, a
    // required side missing): re-read GET kyc so a removed option drops out of
    // the dropdown and the required sides are recalculated.
    if (body is Map) fetchDocumentConfig();
  }

  Future<void> pickDocument(Rx<File?> target) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      final path = result?.files.single.path;
      if (path == null) return;

      final file = File(path);
      if (await file.length() > _maxDocumentBytes) {
        CustomToastService.showWarning(
          message: TranslationUtils.trf(
            'compliance_controller_file_too_large',
            'File size must be less than 15MB',
          ),
        );
        return;
      }
      target.value = file;
    } catch (e) {
      print('ComplianceController: Error picking document: $e');
    }
  }

  void clearDocument(Rx<File?> target) => target.value = null;

  int get selectedDocumentCount =>
      [
        idProofFront.value,
        idProofBack.value,
        addressProofFront.value,
        addressProofBack.value,
      ].whereType<File>().length;
}
