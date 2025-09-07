// import 'package:flutter/material.dart'

// func buySellOrder(){
//   if(selectedTab == 2 || selectedTab == 3) {
//     if priceTextField.text?.trim().count == 0{
//     self.navigationController?.view.makeToast("Please enter price")
//     return
//     }
//     }
//
//     if(Double(self.lotSizeLabel.text!)! > 10.00 ) {
//   self.navigationController?.view.makeToast("Maximum lot size is 10, please trade lower than 10 lot.")
//   return
//   }
//   guard let selectedStock = selectedStock?.symbol else {
//   self.navigationController?.view.makeToast("Maximum lot size is 10, please trade lower than 10 lot.")
//   return
//   }
//
//   let param = NSMutableDictionary(dictionary: ["mt5_account" : tradingAccount!.metaAccountNumber!,
//   "symbol" : selectedStock,
//   "volume" : lotSizeLabel.text!,
//   "price" : priceTextField.text!,
//   "pricetp" : takeProfiteTextField.text!,
//   "pricesl" : stopLossTextField.text!,
//   ])
//   if(selectedTab == 1 ){
//   param.addEntries(from: ["type": isBuy ? "0": "1"])
//   }
//   else if(selectedTab == 2){
//   param.addEntries(from: ["type": isBuy ? "2": "3"])
//   }
//   else {
//   param.addEntries(from: ["type": isBuy ? "4": "5"])
//   }
//
//   let request = RequestModel(url: APIConstant.TradingAPI, httpMethod: .post, parameter: (param as! [String : Any]))
//
//   ServerCommunication.share.APICallingFuncation(request: request, view: self,isShowAlert: true, completion: {result,data  in
//
//   if(result){
//   UserDefaults.standard.set(self.lotSizeLabel.text!, forKey: "lastLotSize")
//
//   DispatchQueue.main.async {
//
//   let mainStoryboard: UIStoryboard = UIStoryboard(name: UIConstants.HomeStoryBoard, bundle: nil)
//   let objVC = mainStoryboard.instantiateViewController(withIdentifier: "OrderStatusVC") as! OrderStatusVC
//   objVC.data = ["isOrderCompleted":true,"data" : (data!.value(forKey: "data") as! NSDictionary),"message":(data!.value(forKey: "message") as! String)]
//   self.navigationController?.pushViewController(objVC, animated: true)
//   }
//   }
//   else {
//   UserDefaults.standard.set(self.lotSizeLabel.text!, forKey: "lastLotSize")
//
//   if data!.value(forKey: "message") as! String == "Not enough money." {
//
//   DispatchQueue.main.async {
//
//   //                                let mainStoryboard: UIStoryboard = UIStoryboard(name: UIConstants.HomeStoryBoard, bundle: nil)
//   //                                let objVC = mainStoryboard.instantiateViewController(withIdentifier: "OrderStatusVC") as! OrderStatusVC
//   //                                objVC.data = ["isOrderCompleted":true,"isBuy":self.isBuy,"lot_size": self.lotSizeLabel.text!,"scriptName" : selectedStock!.InstrumentIdentifier!,"price" : self.priceTextField.text!,"message":(data!.value(forKey: "message") as! String)]
//   //                                self.navigationController?.pushViewController(objVC, animated: true)
//   }
//   }
//   else {
// //                    self.navigationController?.view.makeToast((data!.value(forKey: "message") as! String))
//   }
//   }
//   })
// }

import 'package:get/get.dart';
import 'package:pipze/constants/api_const.dart';
import 'package:pipze/widgets/custom_toast.dart';

import '../services/api_service.dart';
import '../services/secure_storage_service.dart';

class ChartController extends GetxController {
  // ==================== OBSERVABLE STATES ====================
  final _isLoading = false.obs;
  var errorMessage = ''.obs;
  final _lastResponse = Rxn<Map<String, dynamic>>();
  var isLoadingMT5Accounts = false.obs;

  // ==================== GETTERS ====================
  bool get isLoading => _isLoading.value;
  Map<String, dynamic>? get lastResponse => _lastResponse.value;

  // ==================== CONFIG ====================
  final String apiUrl = "API_URL"; // Replace with your endpoint
  final String token = "Bearer YOUR_TOKEN"; // Replace with secure token

  // ==================== TRADE METHOD ====================
  // Place Trade Order (Buy/Sell)
  Future<bool> placeTradeOrder({
    required String mt5Account,
    required String symbol,
    required double volume,
    required String type, // "buy" or "sell"
    double? priceSl,
    double? priceTp,
    double? price,
  }) async {
    try {
      print('DashboardController: Starting placeTradeOrder...');
      isLoadingMT5Accounts.value = true; // reuse loading observable
      errorMessage.value = '';

      final token = await SecureStorageService.getAuthToken();
      if (token == null || token.isEmpty) {
        errorMessage.value = 'Authentication token not found';
        isLoadingMT5Accounts.value = false;
        return false;
      }

      final requestData = {
        "mt5_account": mt5Account,
        "symbol": symbol,
        "volume": volume,
        "type": type,
        "pricesl": priceSl,
        "pricetp": priceTp,
        "price": price,
      };

      print(
        'DashboardController: Making API call to ${ApiConstants.placeOrder}',
      );
      print('DashboardController: Request data: $requestData');

      final response = await ApiService.post(
        endpoint: ApiConstants.placeOrder,
        data: requestData,
        token: token,
      );

      print(
        'DashboardController: Trade API response success: ${response.success}',
      );
      print(
        'DashboardController: Trade API response data: ${response.data}',
      );

      if (response.success) {
        final data = response.data;

        CustomToastService.showSuccess(
          message: data['message'] ?? 'Trade executed successfully',
          title: 'Trade Success',
        );

        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to execute trade';
        CustomToastService.showError(message: errorMessage.value);
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error placing trade: $e';
      print('DashboardController: Error placing trade: $e');
      return false;
    } finally {
      isLoadingMT5Accounts.value = false;
      print('DashboardController: placeTradeOrder completed');
    }
  }

  // ==================== PRIVATE HELPERS ====================
  void _setLoading(bool loading) {
    _isLoading.value = loading;
  }

  void _setError(String error) {
    errorMessage.value = error;
    if (error.isNotEmpty) {
      CustomToastService.showError(
        message: error,
        position: SnackPosition.TOP,
      );
    }
  }

  void _clearError() {
    errorMessage.value = '';
  }
}