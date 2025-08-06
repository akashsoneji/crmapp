part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const SPLASH = _Paths.SPLASH;
  static const GET_STARTED = _Paths.GET_STARTED;
  static const LOGIN = _Paths.LOGIN;
  static const CREATE_ACCOUNT = _Paths.CREATE_ACCOUNT;
  static const LEGAL_DOCUMENTS = _Paths.LEGAL_DOCUMENTS;
  static const PRIVACY_POLICY = _Paths.PRIVACY_POLICY;
  static const ACCOUNT_CREATED = _Paths.ACCOUNT_CREATED;
  static const FORGOT_PASSWORD = _Paths.FORGOT_PASSWORD;
  static const VERIFY_CODE = _Paths.VERIFY_CODE;
  static const CREATE_NEW_PASSWORD = _Paths.CREATE_NEW_PASSWORD;
  static const TRADING = _Paths.TRADING;
  static const TOAST_DEMO = _Paths.TOAST_DEMO;
  static const LANGUAGE_SELECTOR = _Paths.LANGUAGE_SELECTOR;
  static const ACCOUNT_MANAGEMENT = _Paths.ACCOUNT_MANAGEMENT;
}

abstract class _Paths {
  _Paths._();
  static const SPLASH = '/splash';
  static const GET_STARTED = '/get-started';
  static const LOGIN = '/login';
  static const CREATE_ACCOUNT = '/create-account';
  static const LEGAL_DOCUMENTS = '/legal-documents';
  static const PRIVACY_POLICY = '/privacy-policy';
  static const ACCOUNT_CREATED = '/account-created';
  static const FORGOT_PASSWORD = '/forgot-password';
  static const VERIFY_CODE = '/verify-code';
  static const CREATE_NEW_PASSWORD = '/create-new-password';
  static const TRADING = '/trading';
  static const TOAST_DEMO = '/toast-demo';
  static const LANGUAGE_SELECTOR = '/language-selector';
  static const ACCOUNT_MANAGEMENT = '/account-management';
}