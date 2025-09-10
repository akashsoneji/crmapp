class ApiConstants {
  static const String baseUrl = 'https://my.pipze.com/api/';
  static const String socketUrl = 'wss://my.pipze.com:8080';

  static const String ajax = 'user/';

  static const String login = '${ajax}login';
  static const String forgotPassword = '${ajax}password/email';
  static const String sendOTP = '${ajax}send-otp';
  static const String verifyOTP = '${ajax}verify-otp';
  static const String resetPassword = '${ajax}reset-password';
  static const String register = '${ajax}register';
  static const String dashboard = '${ajax}dashboard';
  static const String profile = '${ajax}settings/profile';
  static const String getMT5Accounts = '${ajax}mt5accounts/get';
  static const String createMT5Account = '${ajax}mt5accounts/create';
  static const String topupDemoAccount = '${ajax}mt5accounts/setbalance';
  static const String placeOrder = '${ajax}trade/new-order';
  static const String logout = '${ajax}logout';
  static const String depositList = '${ajax}deposit';
  static const String realPlanDetails = '${ajax}mt5accounts/plandetails';
  static const String changePrimaryAccount =
      '${ajax}mt5accounts/changePrimaryAccount';

  // Dropdown APIs
  static const String getCountryDropdown = '${ajax}settings/getCountryDropdown';
  static const String getStateDropdown = '${ajax}settings/getStateDropdown';
  static const String getCityDropdown = '${ajax}settings/getCityDropdown';

  // // Profile APIs
  // static const String profileUpdate = '${ajax}profile_update.php';
  // static const String getProfile = '${ajax}profile';
}

// struct APIConstant {
    
//     // NEW API
//     static let BaseUrl                          = "https://my.pipze.com/"
//     static let API                              =  BaseUrl + "api/"
//     static var SocketURL                        = "wss://my.pipze.com:8080"
            
//     static let AjaxTiles                        = API + "user/"
        
//     static let LoginAPI                         = AjaxTiles + "login"
//     static let RegisterAPI                      = AjaxTiles + "register"
//     static let ForgotPasswordAPI                = AjaxTiles + "password/email"
//     static let ResetPasswordAPI                 = AjaxTiles + "settings/change-password"
//     static let DashBoardAPI                     = AjaxTiles + "dashboard"
//     static let LogoutAPI                        = AjaxTiles + "logout"
//     static let deleteAccountAPI                 = AjaxTiles + "settings/delete-account"
    
//     static let ProfileAPI                       = AjaxTiles + "settings/profile"
//     static let GetCountryAPI                    = AjaxTiles + "settings/getCountryDropdown"
//     static let GetStateAPI                      = AjaxTiles + "settings/getStateDropdown"
//     static let GetCityAPI                       = AjaxTiles + "settings/getCityDropdown"
    
//     static let KYCStatusAPI                     = AjaxTiles + "kyc"
//     static let GetImageFromSlugAPI              = AjaxTiles + "kyc/documents/viewDocument/"
//     static let KYCUploadAPI                     = AjaxTiles + "kyc/documents/upload"
    
//     static let GetMT5Account                    = AjaxTiles + "mt5accounts/get"
//     static let GetMT5LivePackagesAPI            = AjaxTiles + "mt5accounts/plandetails"
//     static let CreatetMT5AccountAPI             = AjaxTiles + "mt5accounts/create"
//     static let UpdateMT5AccountLevarageAPI      = AjaxTiles + "mt5accounts/changeleverage"
//     static let UpdateMT5AccountPasswordAPI      = AjaxTiles + "mt5accounts/changepassword"
//     static let changePrimaryAccountMT5API       = AjaxTiles + "mt5accounts/changePrimaryAccount"
//     static let setDemoAccountBalanceAPI         = AjaxTiles + "mt5accounts/setbalance"

    
//     static let GetInternalTransferAPI           = AjaxTiles + "internaltransfer"
//     static let InternalTransferAPI              = AjaxTiles + "internaltransfer/request"
//     static let TransactionHistoryAPI            = AjaxTiles + "transactions"
    
//     static let DepositTypeAPI                   = AjaxTiles + "deposit"
//     static let DepositAmountAPI                 = AjaxTiles + "deposit/depositrequest"
    
//     static let withdrawalListApi                = AjaxTiles + "withdrawal"
//     static let getWithdrawalByIDAPI             = AjaxTiles + "withdrawal/withdrawal-method/"
//     static let WithdrawalRequestAPI             = AjaxTiles + "withdrawal/withdrawalrequest"
//     static let GetUserWithdrawalMethodsAPI      = AjaxTiles + "withdrawal/getUserWithdrawalMethods"
//     static let getOTPAPI                        = AjaxTiles + "withdrawal/sendOTP"
//     static let CheckBalanceAPI                  = AjaxTiles + "withdrawal/checkbalance"

//     static let GetWalletDetailAPI               = AjaxTiles + "wallet"
    
//     static let BonusAPI                         = AjaxTiles + "bonus"
//     static let BonusClaimListAPI                = AjaxTiles + "bonus/bonusClaimList"
//     static let DepositBonusClaimAPI             = AjaxTiles + "bonus/bonusClaim"
    
//     static let GetCurrencyListAPI               = AjaxTiles + "utility/currency-list"
//     static let CheckIFSCCodeAPI                 = AjaxTiles + "utility/ifsc-code"
//     static let CurrencyRatesAPI                 = AjaxTiles + "utility/currency-rates"
    
    
//     static let ChartAPI                         = BaseUrl + "user/chart/"

//     static let Trade                            = AjaxTiles + "trade/"
    
    
//     static let TradingAPI                      = Trade + "new-order"
//     static let ClosePositionAPI                = Trade + "closePositionByPositionId"

//     static let DeletePendingOrderAPI            = Trade + "closePendingOrder"
//     static let GetScriptDetailsAPI              = Trade + "getSymbolDetails"

//     static let GetTradeHistoryAPI              = Trade + "tradehistory"
//     static let getSymbolAPI                     = Trade + "symbols" // NEW API
    
    
//     // OLD API
    
//     static let RegisterValidationAPI            = AjaxTiles + "register_validation.php"
//     static let LoginWithGoogleAPI               = AjaxTiles + "login_with_google.php"
//     static let AccountListAPI                   = AjaxTiles + "account_list.php"
//     static let CommonAPI                        = AjaxTiles + "common_api.php"
//     static let AddDepositAPI                    = AjaxTiles + "add_deposit.php"
//     static let AppConfigAPI                     = AjaxTiles + "app_config.php"


        
//     static let RemoveKYCAPI                     = AjaxTiles + "kyc_remove_image.php"
    
//     static let GetUserPrefrenceAPI              = AjaxTiles + "get_user_prefrence.php"

//     static let SpinWheelClaimAPI                = AjaxTiles + "spin_wheel_claim.php"
//     static let UpdateProfileAPI                 = AjaxTiles + "profile_update.php"
//     static let GetSocketAPI                     = AjaxTiles + "get_socket_url.php"

//     static let TradeAndWinAPI                   = AjaxTiles + "trade_and_win.php"

//     static let IBApplicationStatusAPI           = AjaxTiles + "ib_application_status.php"
//     static let AddIBApplicationAPI              = AjaxTiles + "add_ibapplication.php"
//     static let GetDashboardAPI                  = AjaxTiles + "get_dashboard.php"
    
    
//     static let PartnershipRequestManageAPI      = AjaxTiles + "partnership_request_manage.php"
//     static let StructuresManageAPI              = AjaxTiles + "structures_manage.php"
//     static let MyTradersAPI                     = AjaxTiles + "my_traders.php"
//     static let SponserMTDataAPI                 = AjaxTiles + "sponser_mt_data_ajax.php"
//     static let FantasticFourOfferAPI            = AjaxTiles + "fantastic_four_offer.php"

    
    
    
//     static let Database                         = BaseUrl + "datatable/"
        
//     static let SpinAndWinListAPI                = Database + "spin_and_win_list.php"
//     static let PartnershipRequestsAPI           = Database + "partnership_requests.php"

//     static let MyStructuresAPI                  = Database + "my_structures.php"

//     static let Trading                          = AjaxTiles + "trading/"

//     static let OpenPendingtradeAPI              = Trading + "get_open_trade.php"
//     static let GetScriptAPI                     = Trading + "get_script.php"
//     static let AddMarketWatchAPI                = Trading + "add_marketwatch.php"
//     static let DeleteMarketWatchAPI             = Trading + "delete_marketwatch.php"
//     static let GetMarketWatchAPI                = Trading + "get_marketwatch.php"

//     static let TradingCloseAPI                  = Trading + "trade_place_close.php"
//     static let UpdateOrderProfitLossAPI         = Trading + "update_order_profit_loss.php"
//     static let ScriptsSortingsAPI               = Trading + "scripts_sortings.php"
//     static let GetSymbolUsdRateAPI              = Trading + "get_symbol_usd_rate.php"
// }