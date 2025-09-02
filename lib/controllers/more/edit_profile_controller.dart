import 'package:get/get.dart';
import 'package:pipze/constants/api_const.dart';
import 'package:pipze/services/api_service.dart';
import 'package:pipze/services/secure_storage_service.dart';
import 'package:pipze/widgets/custom_toast.dart';

class EditProfileController extends GetxController {
  // Observable variables
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString errorMessage = ''.obs;

  // Profile data
  final RxString firstName = ''.obs;
  final RxString lastName = ''.obs;
  final RxString email = ''.obs;
  final RxString phone = ''.obs;
  final RxString address = ''.obs;
  final RxString city = ''.obs;
  final RxString state = ''.obs;
  final RxString country = ''.obs;
  final RxString gender = ''.obs;
  final RxString dateOfBirth = ''.obs;

  // Form validation
  final RxBool isFormValid = false.obs;

  // Dropdown data
  final RxList<String> genderList = ['Male', 'Female', 'Other'].obs;
  final RxList<String> stateList =
      <String>['Gujarat,Gujarat,Gujarat,Gujarat'].obs;
  final RxList<String> cityList =
      <String>['Ahmedabad,Ahmedabad,Ahmedabad,Ahmedabad'].obs;
  final RxList<Map<String, dynamic>> countryList = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadProfileData();
    // loadDropdownData();
  }

  // Load profile data from API
  Future<void> loadProfileData() async {
    final token = await SecureStorageService.getAuthToken();
    print('token:loadProfileData $token');
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await ApiService.get(
        endpoint: ApiConstants.profile,
        token: token,
      );
      print('data:loadProfileData ---> ${response}');
      print('data:loadProfileData data --> ${response.data}');
      print('data:loadProfileData status --> ${response.data['status']}');

      if (response.success) {
        final data = response.data;

        // Update profile data from API response
        if (data['status'] == true && data['data'] != null) {
          final responseData = data['data'];
          final userData = responseData['user'] ?? {};
          final userDetails = responseData['user_details'] ?? {};

          // Map the response data to our controller properties
          firstName.value = userData['first_name'] ?? '';
          lastName.value = userData['last_name'] ?? '';
          email.value = userData['email'] ?? '';
          phone.value = userData['mobile'] ?? '';

          // User details mapping
          gender.value = userDetails['gender'] ?? '';
          dateOfBirth.value = userDetails['dob'] ?? '';
          country.value = userDetails['nationality'] ?? '';

          // Note: address, city, state might not be in this response
          // You may need to add these fields to your API response
          address.value = userDetails['address'] ?? '';
          city.value = userDetails['city'] ?? '';
          state.value = userDetails['state'] ?? '';

          print('Profile data loaded successfully');
          print('User: ${userData['first_name']} ${userData['last_name']}');
          print('Email: ${userData['email']}');
          print('Mobile: ${userData['mobile']}');
          print('Gender: ${userDetails['gender']}');
          print('DOB: ${userDetails['dob']}');
        } else {
          errorMessage.value = data['message'] ?? 'Failed to load profile data';
        }
      } else {
        errorMessage.value = response.message ?? 'Failed to load profile data';
        print('API Error: ${response.message} - ${response.data}');
      }
    } catch (e) {
      errorMessage.value = 'Error loading profile: $e';
      print('Exception in loadProfileData: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Load dropdown data (countries, states, cities)
  Future<void> loadDropdownData() async {
    try {
      // Load countries
      await loadCountries();

      // Load states if country is selected
      if (country.value.isNotEmpty) {
        await loadStates();
      }

      // Load cities if state is selected
      if (state.value.isNotEmpty) {
        await loadCities();
      }
    } catch (e) {
      print('Error loading dropdown data: $e');
    }
  }

  // Load countries from API
  Future<void> loadCountries() async {
    final token = await SecureStorageService.getAuthToken();
    try {
      final response = await ApiService.get(
        endpoint: '${ApiConstants.ajax}settings/getCountryDropdown',
        token: token,
      );

      if (response.success) {
        final data = response.data;
        if (data['status'] == true && data['data'] != null) {
          countryList.assignAll(
            (data['data'] as List)
                .map(
                  (item) => {
                    'id': item['id'],
                    'name': item['name'],
                    'code': item['code'],
                  },
                )
                .toList(),
          );
        }
      }
    } catch (e) {
      print('Error loading countries: $e');
    }
  }

  // Load states from API
  Future<void> loadStates() async {
    final token = await SecureStorageService.getAuthToken();
    try {
      final selectedCountry = countryList.firstWhereOrNull(
        (country) => country['name'] == this.country.value,
      );

      if (selectedCountry != null) {
        final response = await ApiService.get(
          endpoint:
              '${ApiConstants.ajax}settings/getStateDropdown?country_id=${selectedCountry['id']}',
          token: token,
        );

        if (response.success) {
          final data = response.data;
          if (data['status'] == true && data['data'] != null) {
            stateList.assignAll(
              (data['data'] as List)
                  .map((item) => item['name'].toString())
                  .toList(),
            );
          }
        }
      }
    } catch (e) {
      print('Error loading states: $e');
    }
  }

  // Load cities from API
  Future<void> loadCities() async {
    final token = await SecureStorageService.getAuthToken();
    try {
      final selectedState = stateList.firstWhereOrNull(
        (state) => state == this.state.value,
      );

      if (selectedState != null) {
        final response = await ApiService.get(
          endpoint:
              '${ApiConstants.ajax}settings/getCityDropdown?state=$selectedState',
          token: token,
        );

        if (response.success) {
          final data = response.data;
          if (data['status'] == true && data['data'] != null) {
            cityList.assignAll(
              (data['data'] as List)
                  .map((item) => item['name'].toString())
                  .toList(),
            );
          }
        }
      }
    } catch (e) {
      print('Error loading cities: $e');
    }
  }

  // Update profile data
  Future<bool> updateProfile() async {
    final token = await SecureStorageService.getAuthToken();
    try {
      isSaving.value = true;
      errorMessage.value = '';

      // final requestBody = {
      //   'first_name': firstName.value,
      //   'last_name': lastName.value,
      //   'email': email.value,
      //   'phone': phone.value,
      //   'address': address.value,
      //   'city': city.value,
      //   'state': state.value,
      //   'country': country.value,
      //   'gender': gender.value,
      //   'date_of_birth': dateOfBirth.value,
      // };

      final requestBody = {
        "first_name": firstName.value,
        "last_name": lastName.value,
        "mobile": phone.value,
        "country_id": 1, // You can make this dynamic based on selected country
        "state_id":
            state.value.isNotEmpty
                ? 1
                : null, // Only include if state is selected
        "city_id":
            city.value.isNotEmpty
                ? 1
                : null, // Only include if city is selected
      };

      final response = await ApiService.post(
        endpoint: ApiConstants.profile,
        data: requestBody,
        token: token,
      );

      if (response.success) {
        final data = response.data;
        if (data['status'] == true) {
          print('Profile updated successfully');
          CustomToastService.showSuccess(
            message: 'Profile updated successfully!',
            title: 'Success',
          );
          return true;
        } else {
          errorMessage.value = data['message'] ?? 'Failed to update profile';
          return false;
        }
      } else {
        errorMessage.value = response.message ?? 'Failed to update profile';
        print('API Error: ${response.message} - ${response.data}');
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error updating profile: $e';
      print('Exception in updateProfile: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // Validate form
  void validateForm() {
    // Required fields: first name, last name, email, phone, date of birth, gender, country
    // Optional fields: state, city, address
    isFormValid.value =
        firstName.value.isNotEmpty &&
        lastName.value.isNotEmpty &&
        email.value.isNotEmpty &&
        phone.value.isNotEmpty &&
        dateOfBirth.value.isNotEmpty &&
        gender.value.isNotEmpty &&
        country.value.isNotEmpty;
  }

  // Update individual fields
  void updateFirstName(String value) {
    firstName.value = value;
    validateForm();
  }

  void updateLastName(String value) {
    lastName.value = value;
    validateForm();
  }

  void updateEmail(String value) {
    email.value = value;
    validateForm();
  }

  void updatePhone(String value) {
    phone.value = value;
    validateForm();
  }

  void updateAddress(String value) {
    address.value = value;
    validateForm();
  }

  void updateCity(String value) {
    city.value = value;
    validateForm();
  }

  void updateState(String value) {
    state.value = value;
    city.value = ''; // Reset city when state changes
    cityList.clear();
    loadCities();
    validateForm();
  }

  void updateCountry(String value) {
    country.value = value;
    state.value = ''; // Reset state when country changes
    city.value = ''; // Reset city when country changes
    stateList.clear();
    cityList.clear();
    loadStates();
    validateForm();
  }

  void updateGender(String value) {
    gender.value = value;
    validateForm();
  }

  void updateDateOfBirth(String value) {
    dateOfBirth.value = value;
    validateForm();
  }
}
