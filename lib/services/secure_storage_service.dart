import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_app/models/user_model.dart';

class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // SharedPreferences marker used to detect an app install on iOS.
  // iOS Keychain can survive uninstall, but SharedPreferences is removed.
  static const String _installMarkerKey = 'secure_storage_install_marker_v1';

  // Clear stale iOS Keychain session only after a fresh install/reinstall.
  // This prevents auto-login after app delete + reinstall without logging users
  // out on ordinary app restarts or TestFlight updates.
  static Future<void> clearStaleSessionOnFreshInstall() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasInstallMarker = prefs.getBool(_installMarkerKey) == true;
      final tokenBeforeCleanup = await _storage.read(key: _authTokenKey);

      print(
        'SecureStorage: Fresh-install check → platform=${Platform.isIOS ? 'ios' : 'non-ios'}, marker=${hasInstallMarker ? 'exists' : 'missing'}, token=${tokenBeforeCleanup?.isNotEmpty == true ? 'exists' : 'missing'}',
      );

      if (!Platform.isIOS) {
        await prefs.setBool(_installMarkerKey, true);
        print(
          'SecureStorage: Fresh-install cleanup skipped on non-iOS platform',
        );
        return;
      }

      if (!hasInstallMarker) {
        // ✅ FIX: If a valid Keychain token exists, this is most likely an app
        // UPDATE (not a fresh install). iOS Keychain survives updates but
        // SharedPreferences may have been reset by the OS. In this case, restore
        // the marker and preserve the user's session.
        if (tokenBeforeCleanup != null && tokenBeforeCleanup.isNotEmpty) {
          print(
            'SecureStorage: Marker missing but token found – treating as update, restoring marker and preserving session.',
          );
        } else {
          print(
            'SecureStorage: Fresh iOS install/reinstall detected. Clearing stale auth session keys only.',
          );
          await _clearSessionKeysForFreshInstall();
          print('SecureStorage: Fresh-install auth keys cleared');
        }
      } else {
        print(
          'SecureStorage: Existing iOS install detected. Preserving secure session.',
        );
      }

      await prefs.setBool(_installMarkerKey, true);
    } catch (e) {
      print('SecureStorage: Error checking fresh install state: $e');
    }
  }

  // Backward-compatible wrapper for older call sites.
  static Future<void> clearSecureStorageOnFirstRun() async {
    await clearStaleSessionOnFreshInstall();
  }

  static Future<void> _clearSessionKeysForFreshInstall() async {
    await Future.wait([
      _storage.delete(key: _authTokenKey),
      _storage.delete(key: _websocketTokenKey),
      _storage.delete(key: _userDataKey),
      _storage.delete(key: _isLoggedInKey),
      _storage.delete(key: _selectedSymbolKey),
      _storage.delete(key: _biometricEnabledKey),
      _storage.delete(key: _biometricUserKey),
    ]);
  }

  // Storage keys
  static const String _authTokenKey = 'auth_token';
  // NOTE: This is a hardcoded token used to bypass the login flow when needed.
  //       Use ONLY in development / QA builds. For production, remove or disable.
  // static const String _defaultBypassAuthToken =
  //     '3802|vSbWIFD2sHBI3hpCM8wcKpZCSrGvlm78enjnfXhPada4b335';
  static const String _websocketTokenKey = 'websocket_token';
  static const String _userDataKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _selectedSymbolKey = 'selected_symbol';
  static const String _fcmTokenKey = 'fcm_token';
  static const String _tenaxBrokerSelectionKey = 'tenax_broker_selection';
  static const String _tenaxBrokerSelectionFlagKey =
      'tenax_broker_selection_flag';
  static const String _tenaxBrokerConfiguredKey = 'tenax_broker_configured';
  static const String _tenaxUserBrokerProfilesKey =
      'tenax_user_broker_profiles';
  static const String _tenaxCurrentProfileKey = 'tenax_current_profile_key';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricUserKey = 'biometric_user';
  static const bool _defaultTenaxBrokerSelectionFlag = bool.fromEnvironment(
    'TENAX_BROKER_SELECTION_ENABLED',
    defaultValue: true,
  );

  // Save authentication token
  static Future<void> saveAuthToken(String token) async {
    try {
      await _storage.write(key: _authTokenKey, value: token);
      print('SecureStorage: Auth token saved successfully');
    } catch (e) {
      print('SecureStorage: Error saving auth token: $e');
      rethrow;
    }
  }

  // Get authentication token
  static Future<String?> getAuthToken() async {
    try {
      final token = await _storage.read(key: _authTokenKey);
      print(
        'SecureStorage: Auth token retrieved: ${token != null ? 'exists' : 'null'}',
      );
      return token;
    } catch (e) {
      print('SecureStorage: Error getting auth token: $e');
      return null;
    }
  }

  // Save websocket token
  static Future<void> saveWebsocketToken(String token) async {
    try {
      await _storage.write(key: _websocketTokenKey, value: token);
      print('SecureStorage: Websocket token saved successfully');
    } catch (e) {
      print('SecureStorage: Error saving websocket token: $e');
      rethrow;
    }
  }

  // Get websocket token
  static Future<String?> getWebsocketToken() async {
    try {
      final token = await _storage.read(key: _websocketTokenKey);
      print(
        'SecureStorage: Websocket token retrieved: ${token != null ? 'exists' : 'null'}',
      );
      return token;
    } catch (e) {
      print('SecureStorage: Error getting websocket token: $e');
      return null;
    }
  }

  // Save FCM token
  static Future<void> saveFcmToken(String token) async {
    try {
      await _storage.write(key: _fcmTokenKey, value: token);
      print('SecureStorage: FCM token saved successfully');
    } catch (e) {
      print('SecureStorage: Error saving FCM token: $e');
    }
  }

  // Get FCM token
  static Future<String?> getFcmToken() async {
    try {
      final token = await _storage.read(key: _fcmTokenKey);
      print(
        'SecureStorage: FCM token retrieved: ${token != null ? 'exists' : 'null'}',
      );
      return token;
    } catch (e) {
      print('SecureStorage: Error getting FCM token: $e');
      return null;
    }
  }

  // Save user data
  static Future<void> saveUserData(String userData) async {
    try {
      await _storage.write(key: _userDataKey, value: userData);
      print('SecureStorage: User data saved successfully');
    } catch (e) {
      print('SecureStorage: Error saving user data: $e');
      rethrow;
    }
  }

  // Get user data
  static Future<UserModel?> getUserData() async {
    try {
      final userData = await _storage.read(key: _userDataKey);
      if (userData == null) {
        print('SecureStorage: No user data found');
        return null;
      }

      final Map<String, dynamic> loginData = jsonDecode(userData);
      final userModel = UserModel.fromJson(loginData['user']);
      print("userData getUserData : $userData");
      print('SecureStorage: User data retrieved: exists');
      return userModel;
    } catch (e) {
      print('SecureStorage: Error getting user data: $e');
      return null;
    }
  }

  // Get complete login data (including token, websocket token, etc.)
  static Future<Map<String, dynamic>?> getCompleteLoginData() async {
    try {
      final userData = await _storage.read(key: _userDataKey);
      if (userData == null) {
        print('SecureStorage: No login data found');
        return null;
      }

      final Map<String, dynamic> loginData = jsonDecode(userData);
      print('SecureStorage: Complete login data retrieved');
      return loginData;
    } catch (e) {
      print('SecureStorage: Error getting complete login data: $e');
      return null;
    }
  }

  // Save login status
  static Future<void> saveLoginStatus(bool isLoggedIn) async {
    try {
      await _storage.write(key: _isLoggedInKey, value: isLoggedIn.toString());
      print('SecureStorage: Login status saved: $isLoggedIn');
    } catch (e) {
      print('SecureStorage: Error saving login status: $e');
      rethrow;
    }
  }

  // Get login status
  static Future<bool> getLoginStatus() async {
    try {
      final status = await _storage.read(key: _isLoggedInKey);
      final isLoggedIn = status == 'true';
      print('SecureStorage: Login status retrieved: $isLoggedIn');
      return isLoggedIn;
    } catch (e) {
      print('SecureStorage: Error getting login status: $e');
      return false;
    }
  }

  // Save all login data
  static Future<void> saveLoginData({
    required String authToken,
    required String websocketToken,
    required String userData,
  }) async {
    try {
      await Future.wait([
        saveAuthToken(authToken),
        saveWebsocketToken(websocketToken),
        saveUserData(userData),
        saveLoginStatus(true),
      ]);
      print('SecureStorage: All login data saved successfully');
    } catch (e) {
      print('SecureStorage: Error saving login data: $e');
      rethrow;
    }
  }

  // Clear all authentication data
  static Future<void> clearAuthData() async {
    try {
      await Future.wait([
        _storage.delete(key: _authTokenKey),
        _storage.delete(key: _websocketTokenKey),
        _storage.delete(key: _userDataKey),
        _storage.delete(key: _isLoggedInKey),
        _storage.delete(key: _selectedSymbolKey),
        _storage.delete(key: _biometricEnabledKey),
        _storage.delete(key: _biometricUserKey),
      ]);
      print('SecureStorage: All authentication data cleared');
    } catch (e) {
      print('SecureStorage: Error clearing authentication data: $e');
      rethrow;
    }
  }

  static Future<void> setBiometricEnabled(
    bool enabled, {
    String? userIdentifier,
  }) async {
    try {
      await _storage.write(
        key: _biometricEnabledKey,
        value: enabled.toString(),
      );
      if (userIdentifier != null) {
        await _storage.write(key: _biometricUserKey, value: userIdentifier);
      }
    } catch (e) {
      print('SecureStorage: Error saving biometric enabled flag: $e');
      rethrow;
    }
  }

  static Future<bool> getBiometricEnabled() async {
    try {
      final value = await _storage.read(key: _biometricEnabledKey);
      return value == 'true';
    } catch (e) {
      print('SecureStorage: Error reading biometric enabled flag: $e');
      return false;
    }
  }

  static Future<String?> getBiometricUserIdentifier() async {
    try {
      return await _storage.read(key: _biometricUserKey);
    } catch (e) {
      print('SecureStorage: Error reading biometric user identifier: $e');
      return null;
    }
  }

  static Future<void> clearBiometricState() async {
    try {
      await Future.wait([
        _storage.delete(key: _biometricEnabledKey),
        _storage.delete(key: _biometricUserKey),
      ]);
    } catch (e) {
      print('SecureStorage: Error clearing biometric state: $e');
    }
  }

  // Check if user is logged in
  static Future<bool> isUserLoggedIn() async {
    try {
      final token = await getAuthToken();
      final isLoggedIn = await getLoginStatus();
      final hasToken = token != null && token.isNotEmpty;
      final hasValidSession = hasToken && isLoggedIn;

      print(
        'SecureStorage: User logged-in check → token=${hasToken ? 'exists' : 'missing'}, loginStatus=$isLoggedIn, result=$hasValidSession',
      );

      return hasValidSession;
    } catch (e) {
      print('SecureStorage: Error checking login status: $e');
      return false;
    }
  }

  // Save last selected trading symbol
  static Future<void> saveSelectedSymbol(String symbol) async {
    try {
      await _storage.write(key: _selectedSymbolKey, value: symbol);
      print('SecureStorage: Selected symbol saved: $symbol');
    } catch (e) {
      print('SecureStorage: Error saving selected symbol: $e');
      rethrow;
    }
  }

  // Get last selected trading symbol
  static Future<String?> getSelectedSymbol() async {
    try {
      final symbol = await _storage.read(key: _selectedSymbolKey);
      print('SecureStorage: Selected symbol retrieved: ${symbol ?? 'null'}');
      return symbol;
    } catch (e) {
      print('SecureStorage: Error getting selected symbol: $e');
      return null;
    }
  }

  static Future<void> saveTenaxBrokerSelection(
    Map<String, dynamic> brokerData,
  ) async {
    try {
      await _storage.write(
        key: _tenaxBrokerSelectionKey,
        value: jsonEncode(brokerData),
      );
      await _storage.write(key: _tenaxBrokerConfiguredKey, value: 'true');
      print('SecureStorage: Tenax broker selection saved');
    } catch (e) {
      print('SecureStorage: Error saving Tenax broker selection: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getTenaxBrokerSelection() async {
    try {
      final value = await _storage.read(key: _tenaxBrokerSelectionKey);
      if (value == null || value.isEmpty) {
        return null;
      }
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (e) {
      print('SecureStorage: Error reading Tenax broker selection: $e');
      return null;
    }
  }

  static Future<bool> hasTenaxBrokerSelection() async {
    try {
      final isConfigured = await _storage.read(key: _tenaxBrokerConfiguredKey);
      if (isConfigured == 'true') {
        return true;
      }
      final value = await getTenaxBrokerSelection();
      return value != null && value.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<void> clearTenaxBrokerSelection() async {
    try {
      await _storage.delete(key: _tenaxBrokerSelectionKey);
      await _storage.delete(key: _tenaxBrokerConfiguredKey);
      print('SecureStorage: Tenax broker selection cleared');
    } catch (e) {
      print('SecureStorage: Error clearing Tenax broker selection: $e');
    }
  }

  static Future<void> saveTenaxBrokerSelectionFlag(bool isEnabled) async {
    try {
      await _storage.write(
        key: _tenaxBrokerSelectionFlagKey,
        value: isEnabled.toString(),
      );
      print('SecureStorage: Tenax broker selection flag saved: $isEnabled');
    } catch (e) {
      print('SecureStorage: Error saving Tenax broker selection flag: $e');
    }
  }

  static Future<bool> getTenaxBrokerSelectionFlag() async {
    try {
      final value = await _storage.read(key: _tenaxBrokerSelectionFlagKey);
      if (value == null || value.isEmpty) {
        return _defaultTenaxBrokerSelectionFlag;
      }
      return value == 'true';
    } catch (e) {
      print('SecureStorage: Error reading Tenax broker selection flag: $e');
      return _defaultTenaxBrokerSelectionFlag;
    }
  }

  static Future<List<Map<String, dynamic>>> getTenaxUserBrokerProfiles() async {
    try {
      final raw = await _storage.read(key: _tenaxUserBrokerProfilesKey);
      if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Map<String, dynamic>>[];
      final profiles =
          decoded
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
      final sanitized = _sanitizeTenaxProfiles(profiles);
      if (sanitized.length != profiles.length) {
        await _storage.write(
          key: _tenaxUserBrokerProfilesKey,
          value: jsonEncode(sanitized),
        );
      }
      return sanitized;
    } catch (e) {
      print('SecureStorage: Error reading Tenax profiles: $e');
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> saveTenaxUserBrokerProfiles(
    List<Map<String, dynamic>> profiles,
  ) async {
    try {
      final sanitizedProfiles = _sanitizeTenaxProfiles(profiles);
      await _storage.write(
        key: _tenaxUserBrokerProfilesKey,
        value: jsonEncode(sanitizedProfiles),
      );
    } catch (e) {
      print('SecureStorage: Error saving Tenax profiles: $e');
      rethrow;
    }
  }

  static Future<void> upsertTenaxUserBrokerProfile(
    Map<String, dynamic> profile,
  ) async {
    final normalizedProfile = _normalizeTenaxProfile(profile);
    final key = (normalizedProfile['profile_key'] ?? '').toString();
    if (key.isEmpty) return;
    final profiles = await getTenaxUserBrokerProfiles();
    profiles.removeWhere(
      (item) => (item['profile_key'] ?? '').toString() == key,
    );
    profiles.insert(0, normalizedProfile);
    await saveTenaxUserBrokerProfiles(profiles);
    await setTenaxCurrentProfileKey(key);
  }

  static Future<void> setTenaxCurrentProfileKey(String key) async {
    try {
      await _storage.write(key: _tenaxCurrentProfileKey, value: key);
    } catch (e) {
      print('SecureStorage: Error saving current Tenax profile key: $e');
    }
  }

  static Future<String?> getTenaxCurrentProfileKey() async {
    try {
      return await _storage.read(key: _tenaxCurrentProfileKey);
    } catch (e) {
      print('SecureStorage: Error reading current Tenax profile key: $e');
      return null;
    }
  }

  static List<Map<String, dynamic>> _sanitizeTenaxProfiles(
    List<Map<String, dynamic>> profiles,
  ) {
    final uniqueProfiles = <String, Map<String, dynamic>>{};

    for (final rawProfile in profiles) {
      final normalized = _normalizeTenaxProfile(rawProfile);
      final key = (normalized['profile_key'] ?? '').toString();
      if (key.isEmpty) continue;
      uniqueProfiles[key] = normalized;
    }

    final result = uniqueProfiles.values.toList();
    result.sort((a, b) {
      final aSaved = (a['saved_at'] ?? '').toString();
      final bSaved = (b['saved_at'] ?? '').toString();
      return bSaved.compareTo(aSaved);
    });
    return result;
  }

  static Map<String, dynamic> _normalizeTenaxProfile(
    Map<String, dynamic> profile,
  ) {
    final normalized = Map<String, dynamic>.from(profile);
    final brokerData =
        normalized['broker_data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(
              normalized['broker_data'] as Map<String, dynamic>,
            )
            : <String, dynamic>{};
    final loginData =
        normalized['login_data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(
              normalized['login_data'] as Map<String, dynamic>,
            )
            : <String, dynamic>{};
    final loginUser =
        loginData['user'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(
              loginData['user'] as Map<String, dynamic>,
            )
            : <String, dynamic>{};

    final userEmail =
        (normalized['user_email'] ??
                loginUser['email'] ??
                loginUser['user_email'] ??
                '')
            .toString()
            .trim()
            .toLowerCase();
    final userName =
        (normalized['user_name'] ??
                loginUser['full_name'] ??
                loginUser['fullName'] ??
                loginUser['name'] ??
                '')
            .toString()
            .trim();
    final brokerSlug =
        (normalized['broker_slug'] ??
                brokerData['selected_slug'] ??
                brokerData['slug'] ??
                brokerData['broker_list_item']?['slug'] ??
                '')
            .toString()
            .trim();
    final brokerName =
        (normalized['broker_name'] ??
                brokerData['selected_name'] ??
                brokerData['name'] ??
                '')
            .toString()
            .trim();
    final profileKey =
        userEmail.isNotEmpty && brokerSlug.isNotEmpty
            ? '$userEmail|$brokerSlug'
            : '';

    normalized['user_email'] = userEmail;
    normalized['user_name'] = userName;
    normalized['broker_slug'] = brokerSlug;
    normalized['broker_name'] = brokerName;
    normalized['broker_data'] = brokerData;
    normalized['login_data'] = loginData;
    normalized['profile_key'] = profileKey;
    normalized['saved_at'] =
        (normalized['saved_at'] ?? DateTime.now().toIso8601String()).toString();

    return normalized;
  }
}
