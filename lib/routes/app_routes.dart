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
  static const EDIT_PROFILE = _Paths.EDIT_PROFILE;
  static const WITHDRAWAL = _Paths.WITHDRAWAL;
  static const DEPOSIT = _Paths.DEPOSIT;
  static const WALLET = _Paths.WALLET;
  static const TRANSACTION_HISTORY = _Paths.TRANSACTION_HISTORY;
  static const KYC_VERIFICATION = _Paths.KYC_VERIFICATION;
  static const CHAT_WITH_US = _Paths.CHAT_WITH_US;
  static const OPEN_ACCOUNT = _Paths.OPEN_ACCOUNT;
  static const CREATE_OPEN_ACCOUNT = _Paths.CREATE_OPEN_ACCOUNT;
  static const CREATE_TRADING_ACCOUNT = _Paths.CREATE_TRADING_ACCOUNT;
  static const CHOOSE_ACCOUNT = _Paths.CHOOSE_ACCOUNT;
  static const INTERNAL_TRANSFER = _Paths.INTERNAL_TRANSFER;
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
  static const EDIT_PROFILE = '/edit-profile';
  static const WITHDRAWAL = '/withdrawal';
  static const DEPOSIT = '/deposit';
  static const WALLET = '/wallet';
  static const TRANSACTION_HISTORY = '/transaction-history';
  static const KYC_VERIFICATION = '/kyc-verification';
  static const CHAT_WITH_US = '/chat-with-us';
  static const OPEN_ACCOUNT = '/open-account';
  static const CREATE_OPEN_ACCOUNT = '/create-open-account';
  static const CREATE_TRADING_ACCOUNT = '/create-trading-account';
  static const CHOOSE_ACCOUNT = '/choose-account';
  static const CREATE_PIPZE_ACCOUNT = '/create-pipze-account';
  static const INTERNAL_TRANSFER = '/internal-transfer';
}
