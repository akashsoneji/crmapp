# Trading API Documentation

This document provides comprehensive documentation for the updated trading API implementation in the Pipze Flutter app.

## Overview

The trading API has been completely updated with new endpoints, models, and services to support both Normal Trade API and Python Trade API endpoints. All methods include parameter validation, detailed logging, and comprehensive error handling.

## API Endpoints

### Normal Trade API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/trade/new-order` | POST | Place new orders (Buy/Sell Market, Limit, Stop, etc.) |
| `/api/trade/closePositionByPositionId` | POST | Close specific position by ID |
| `/api/trade/closePositions` | POST | Close all positions for an account |
| `/api/trade/closePendingOrder` | POST | Close pending orders |
| `/api/trade/tradehistory` | GET | Get trade history with pagination |
| `/api/trade/symbols` | GET | Get all available trading symbols |
| `/api/trade/getSymbolDetails` | POST | Get detailed information for a symbol |
| `/api/trade/symbolPrice` | POST | Get market watch data (symbol prices) |

### Python Trade API Endpoints

| Endpoint | Method | Description | Headers |
|----------|--------|-------------|---------|
| `/api/python-trade/place-order` | POST | Place orders using Python API | `X-API-Key: master@1234` |
| `/api/python-trade/account-info` | GET | Get account information | `X-API-Key: master@1234` |
| `/api/python-trade/open-positions` | GET | Get open positions | `X-API-Key: master@1234` |
| `/api/python-trade/close-position` | POST | Close positions | `X-API-Key: master@1234` |
| `/api/python-trade/update-tp-sl` | POST | Update Take Profit and Stop Loss | `X-API-Key: master@1234` |

## Order Types

The API supports 8 different order types:

| Type | Value | Description |
|------|-------|-------------|
| `OrderType.buyMarket` | 0 | Buy (Market) |
| `OrderType.sellMarket` | 1 | Sell (Market) |
| `OrderType.buyLimit` | 2 | Buy Limit |
| `OrderType.sellLimit` | 3 | Sell Limit |
| `OrderType.buyStop` | 4 | Buy Stop |
| `OrderType.sellStop` | 5 | Sell Stop |
| `OrderType.buyStopLimit` | 6 | Buy Stop Limit |
| `OrderType.sellStopLimit` | 7 | Sell Stop Limit |

## Models

### Request Models

#### PlaceOrderRequest
```dart
PlaceOrderRequest({
  required String mt5Account,
  required String symbol,
  required double volume,
  required OrderType type,
  double? price,        // For limit/stop orders
  double? pricesl,      // Stop Loss
  double? pricetp,      // Take Profit
})
```

#### ClosePositionRequest
```dart
ClosePositionRequest({
  required String mt5Account,
  required int positionId,
  double? volume,       // For partial close
})
```

#### TradeHistoryRequest
```dart
TradeHistoryRequest({
  required String mt5Account,
  int page = 1,
  int perPage = 10,
  bool? today,
  String? startDate,
  String? endDate,
})
```

### Response Models

#### TradeOrderResponse
```dart
TradeOrderResponse({
  required bool success,
  required String message,
  TradeOrderData? data,
})
```

#### TradeOrderData
```dart
TradeOrderData({
  required String lot,
  required String mt5AccountId,
  required String orderNo,
  required double stopLoss,
  required double takeProfit,
  required String tradeDateTime,
  required String tradePrice,
  required String tradeProfit,
  required String tradeSymbol,
  required String tradeType,
  required int tradeVolume,
})
```

## Services

### TradingService

The `TradingService` class provides static methods for all trading operations:

#### Normal Trade API Methods

```dart
// Place order
static Future<ApiResponse<TradeOrderResponse>> placeOrder(PlaceOrderRequest request)

// Close position
static Future<ApiResponse> closePosition(ClosePositionRequest request)

// Close all positions
static Future<ApiResponse> closeAllPositions(CloseAllPositionsRequest request)

// Close pending orders
static Future<ApiResponse> closePendingOrder(ClosePendingOrderRequest request)

// Get trade history
static Future<ApiResponse<TradeHistoryResponse>> getTradeHistory(TradeHistoryRequest request)

// Get symbols
static Future<ApiResponse<SymbolResponse>> getSymbols()

// Get symbol details
static Future<ApiResponse> getSymbolDetails(SymbolDetailsRequest request)

// Get market watch
static Future<ApiResponse> getMarketWatch()
```

#### Python Trade API Methods

```dart
// Place order (Python API)
static Future<ApiResponse<TradeOrderResponse>> placeOrderPython(PlaceOrderRequest request)

// Get account info
static Future<ApiResponse> getAccountInfoPython(String mt5Account)

// Get open positions
static Future<ApiResponse> getOpenPositionsPython(String mt5Account)

// Close position (Python API)
static Future<ApiResponse> closePositionPython(ClosePositionRequest request)

// Update TP/SL
static Future<ApiResponse> updateTpSlPython(UpdateTpSlRequest request)
```

#### Convenience Methods

```dart
// Market orders
static Future<ApiResponse<TradeOrderResponse>> placeMarketBuyOrder({...})
static Future<ApiResponse<TradeOrderResponse>> placeMarketSellOrder({...})

// Limit orders
static Future<ApiResponse<TradeOrderResponse>> placeBuyLimitOrder({...})
static Future<ApiResponse<TradeOrderResponse>> placeSellLimitOrder({...})

// Position management
static Future<ApiResponse> closePositionFull({...})
static Future<ApiResponse> closePositionPartial({...})

// History
static Future<ApiResponse<TradeHistoryResponse>> getTodayTradeHistory(String mt5Account)
static Future<ApiResponse<TradeHistoryResponse>> getTradeHistoryByDateRange({...})
```

## Controllers

### TradingController

The `TradingController` has been updated with new methods that use the `TradingService`:

#### Order Placement Methods

```dart
// Generic order placement
Future<void> placeOrder({
  required String mt5Account,
  required String symbol,
  required double volume,
  required OrderType orderType,
  double? price,
  double? stopLoss,
  double? takeProfit,
  bool usePythonApi = false,
})

// Specific order types
Future<void> placeMarketBuyOrder({...})
Future<void> placeMarketSellOrder({...})
Future<void> placeBuyLimitOrder({...})
Future<void> placeSellLimitOrder({...})
```

#### Position Management Methods

```dart
// Close positions
Future<void> closePositionById({...})
Future<void> closeAllPositionsForAccount(String mt5Account)
Future<void> closePendingOrders({...})

// Update TP/SL
Future<void> updateTpSl({...})
```

#### Data Retrieval Methods

```dart
// Get trading data
Future<void> loadTradeHistory({...})
Future<void> loadSymbols()
Future<void> loadSymbolDetails(String symbol)
Future<void> loadMarketWatch()
Future<void> loadAccountInfo(String mt5Account)
Future<void> loadOpenPositions(String mt5Account)
```

## Usage Examples

### Basic Order Placement

```dart
// Get the trading controller
final tradingController = Get.find<TradingController>();

// Place a market buy order
await tradingController.placeMarketBuyOrder(
  mt5Account: '901335',
  symbol: 'EURUSD',
  volume: 0.1,
  stopLoss: 1.0750,
  takeProfit: 1.0900,
  usePythonApi: false,
);

// Place a buy limit order
await tradingController.placeBuyLimitOrder(
  mt5Account: '901335',
  symbol: 'EURUSD',
  volume: 0.1,
  price: 1.0700,
  stopLoss: 1.0650,
  takeProfit: 1.0800,
  usePythonApi: true,
);
```

### Position Management

```dart
// Close a position fully
await tradingController.closePositionById(
  mt5Account: '901335',
  positionId: 39118,
);

// Close a position partially
await tradingController.closePositionById(
  mt5Account: '901335',
  positionId: 39118,
  volume: 0.05,
);

// Close all positions
await tradingController.closeAllPositionsForAccount('901335');
```

### Data Retrieval

```dart
// Get today's trade history
await tradingController.loadTradeHistory(
  mt5Account: '901335',
  today: true,
);

// Get trade history for date range
await tradingController.loadTradeHistory(
  mt5Account: '901335',
  startDate: '2025-09-01',
  endDate: '2025-09-15',
  page: 1,
  perPage: 20,
);

// Get available symbols
await tradingController.loadSymbols();

// Get market watch data
await tradingController.loadMarketWatch();
```

### Direct Service Usage

```dart
// Use service directly without controller
final orderRequest = PlaceOrderRequest(
  mt5Account: '901335',
  symbol: 'EURUSD',
  volume: 0.1,
  type: OrderType.buyMarket,
  pricesl: 1.0750,
  pricetp: 1.0900,
);

final response = await TradingService.placeOrder(orderRequest);
if (response.success) {
  print('Order placed successfully!');
} else {
  print('Failed to place order: ${response.message}');
}
```

## Parameter Validation

All order requests are automatically validated:

```dart
// Validation checks:
// - MT5 Account is not empty
// - Symbol is not empty
// - Volume is greater than 0
// - Price is provided for limit/stop orders
// - Price is greater than 0 for limit/stop orders

final validationError = TradingService.validateOrderParameters(request);
if (validationError != null) {
  print('Validation error: $validationError');
}
```

## Logging and Debugging

All API calls include comprehensive logging:

- Request parameters are printed before each API call
- Response data is logged for successful calls
- Error messages are logged for failed calls
- Order types are printed for reference

Example output:
```
=== Place Order Request Parameters ===
MT5 Account: 901335
Symbol: EURUSD
Volume: 0.1
Order Type: Buy (Market) (0)
Stop Loss: 1.075
Take Profit: 1.09
=====================================

=== Trade Order Response ===
Success: true
Message: Trade has been successfully placed
Data:
  Lot: 0.10
  MT5 Account ID: 901335
  Order No: 39124
  Stop Loss: 1.075
  Take Profit: 1.09
  Trade DateTime: 2025-09-15 17:17:56
  Trade Price: 1.08500
  Trade Profit: 0.000
  Trade Symbol: EURUSD
  Trade Type: Buy
  Trade Volume: 1000
============================
```

## Error Handling

All methods include comprehensive error handling:

- Network errors are caught and logged
- API errors are properly parsed and displayed
- Validation errors are shown before API calls
- Loading states are managed automatically

## Testing

Use the provided examples in `lib/examples/trading_api_examples.dart` to test all functionality:

```dart
// Run all examples
await TradingApiExamples.runAllExamples();

// Run specific examples
await TradingApiExamples.placeOrderExamples();
await TradingApiExamples.closePositionExamples();
await TradingApiExamples.getTradingDataExamples();
```

## Migration Guide

If you're updating from the old trading implementation:

1. Replace direct API calls with `TradingService` methods
2. Use the new `OrderType` enum instead of integer values
3. Use the new request/response models
4. Update your UI to use the new controller methods
5. Test all functionality using the provided examples

## Support

For questions or issues with the trading API:

1. Check the console logs for detailed error messages
2. Use the validation methods to check parameters
3. Test with the provided examples
4. Review the API documentation for correct parameter formats
