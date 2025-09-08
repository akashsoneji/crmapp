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

import 'package:audioplayers/audioplayers.dart';
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
  final AudioPlayer _player = AudioPlayer();

  // ==================== CONFIG ====================
  final String apiUrl = "API_URL"; // Replace with your endpoint
  final String token = "Bearer YOUR_TOKEN"; // Replace with secure token

  Future<void> _playNoMoneySound() async {
    try {
      print('=== PLAYING NO MONEY SOUND ===');

      // Stop any currently playing audio
      await _player.stop();

      // Set volume to maximum
      await _player.setVolume(1.0);

      // Play the no money sound from assets
      print('Playing no_money.wav from audio/ folder');
      await _player.play(AssetSource('audio/no_money.wav'));
      print('Successfully played no money sound!');
    } catch (e) {
      print('Error playing no money sound: $e');

      try {
        // Fallback: try alternative path
        print('Trying fallback path: no_money.wav');
        await _player.play(AssetSource('no_money.wav'));
        print('Successfully played no money sound from fallback!');
      } catch (e2) {
        print('Error playing no money sound fallback: $e2');

        // Last fallback: play alert sound
        try {
          print('Trying alert sound as final fallback');
          await _player.play(AssetSource('audio/alert_sound.mp3'));
          print('Successfully played alert sound as fallback!');
        } catch (e3) {
          print('All sound playback attempts failed: $e3');
        }
      }
    }
  }

  Future<void> _playSuccessSound() async {
    try {
      print('=== PLAYING NO MONEY SOUND ===');

      // Stop any currently playing audio
      await _player.stop();

      // Set volume to maximum
      await _player.setVolume(1.0);

      // Play the no money sound from assets
      print('Playing no_money.wav from audio/ folder');
      await _player.play(AssetSource('audio/success.mp3'));
      print('Successfully played no money sound!');
    } catch (e) {
      print('Error playing no money sound: $e');

      try {
        // Fallback: try alternative path
        print('Trying fallback path: success.mp3');
        await _player.play(AssetSource('success.mp3'));
        print('Successfully played no money sound from fallback!');
      } catch (e2) {
        print('Error playing no money sound fallback: $e2');

        // Last fallback: play alert sound
        try {
          print('Trying alert sound as final fallback');
          await _player.play(AssetSource('audio/success.mp3'));
          print('Successfully played alert sound as fallback!');
        } catch (e3) {
          print('All sound playback attempts failed: $e3');
        }
      }
    }
  }

  Future<void> _playTradeCloseSound() async {
    try {
      print('=== PLAYING NO MONEY SOUND ===');

      // Stop any currently playing audio
      await _player.stop();

      // Set volume to maximum
      await _player.setVolume(1.0);

      // Play the no money sound from assets
      print('Playing no_money.wav from audio/ folder');
      await _player.play(AssetSource('audio/tradeclose.wav'));
      print('Successfully played no money sound!');
    } catch (e) {
      print('Error playing no money sound: $e');

      try {
        // Fallback: try alternative path
        print('Trying fallback path: tradeclose.wav');
        await _player.play(AssetSource('tradeclose.wav'));
        print('Successfully played no money sound from fallback!');
      } catch (e2) {
        print('Error playing no money sound fallback: $e2');

        // Last fallback: play alert sound
        try {
          print('Trying alert sound as final fallback');
          await _player.play(AssetSource('audio/tradeclose.wav'));
          print('Successfully played alert sound as fallback!');
        } catch (e3) {
          print('All sound playback attempts failed: $e3');
        }
      }
    }
  }

  // ==================== TRADE METHOD ====================
  // Place Trade Order (Buy/Sell)
  Future<bool> placeTradeOrder({
    required String mt5Account,
    required String symbol,
    required double volume,
    required String type, // "buy" or "sell"
    String? priceSl,
    String? priceTp,
    String? price,
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
      print('DashboardController: Trade API response data: ${response.data}');

      if (response.success) {
        final data = response.data;

        if (data['message'].toString().toLowerCase() == 'not enough money') {
          print('Playing no money sound for insufficient funds error...');
          await testNoMoneySound();
        }
        if (data['message'].toString().toLowerCase() ==
            'trade has been successfully placed') {
          print('Playing no money sound for insufficient funds error...');
          await _playSuccessSound();
        }

        CustomToastService.showSuccess(
          message: data['message'] ?? 'Trade executed successfully',
          title: 'Trade Success',
        );

        return true;
      } else {
        print("object it go to Error ${response.message}");
        errorMessage.value = response.message ?? 'Failed to execute trade';
        CustomToastService.showError(message: errorMessage.value);

        // Play no money sound if the error is about insufficient funds
        final responseErrorMessage = response.message?.toLowerCase() ?? '';
        final responseData = response.data;
        final dataMessage =
            responseData is Map<String, dynamic>
                ? responseData['message']?.toString().toLowerCase() ?? ''
                : '';

        if (responseErrorMessage.contains('not enough money') ||
            responseErrorMessage.contains('insufficient') ||
            dataMessage.contains('not enough money') ||
            dataMessage.contains('insufficient')) {
          try {
            print('Playing no money sound for insufficient funds error...');
            await _playNoMoneySound();
          } catch (e) {
            print('Error playing no money sound: $e');
          }
        }

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
      CustomToastService.showError(message: error, position: SnackPosition.TOP);
    }
  }

  void _clearError() {
    errorMessage.value = '';
  }

  // ==================== TEST METHODS ====================
  // Test method to play no money sound
  Future<void> testNoMoneySound() async {
    try {
      print('Testing no money sound...');
      await _playNoMoneySound();
      print('No money sound test completed');
    } catch (e) {
      print('Error testing no money sound: $e');
    }
  }

  // ==================== CLEANUP ====================
  @override
  void onClose() {
    _player.dispose();
    super.onClose();
  }
}
