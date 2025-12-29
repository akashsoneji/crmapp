# Trading WebSocket Integration

This document explains how the trading screen now integrates with real-time WebSocket data to display live trading positions and account information.

## Overview

The trading screen now fetches real-time data from the WebSocket server instead of using hardcoded sample data. This includes:

- **Live Trading Positions**: Real-time position data with current profit/loss
- **Account Information**: Live balance, equity, margin, and other account metrics
- **Automatic Updates**: Data updates automatically when new WebSocket messages are received

## Implementation Details

### 1. WebSocket Response Models

**File**: `lib/models/websocket_trading_response.dart`

- `WebSocketTradingResponse`: Main response wrapper
- `OpenPositionsData`: Contains positions and account info
- `TradingPosition`: Individual position data from WebSocket
- `AccountInfo`: Account metrics and balance information

### 2. Trading WebSocket Service

**File**: `lib/services/trading_websocket_service.dart`

- Manages WebSocket connection lifecycle
- Handles automatic reconnection
- Processes incoming trading data
- Updates the TradingController with real-time data

### 3. Updated Trading Controller

**File**: `lib/controllers/trading_controller.dart`

- Added `updateWebSocketData()` method to handle real-time updates
- Added `accountInfo` getter for account metrics
- Converts WebSocket data to TradePosition objects

### 4. Updated Trade Screen

**File**: `lib/screens/home/trade_screen.dart`

- Displays real account metrics instead of hardcoded values
- Shows live trading positions from WebSocket
- Automatically updates when new data arrives

## WebSocket Message Format

The WebSocket expects messages in this format:

```json
{
  "type": "openPositions",
  "authID": "eyJpdiI6IitoVEMyTzZjbCtOR3QyVGZ0Tzk3ZHc9PSIsInZhbHVlIjoi...",
  "mt5AccountNumber": 301333,
  "isapp": "1"
}
```

## Response Format

The WebSocket returns data in this format:

```json
{
  "openPositions": {
    "positions": [
      {
        "MT5Account": 301333,
        "Position": 38714,
        "Action": "Buy",
        "Volume": "0.020",
        "PriceOpen": "0.86432",
        "PriceSL": "0.00000",
        "PriceTP": "0.00000",
        "PriceCurrent": "0.86417",
        "CloseTime": "-",
        "TimeCreate": "2025-09-15 14:51:14",
        "Symbol": "EURGBP.c",
        "Logo": "https://beta.pipze.com/assets/themes/frontend/images/currency/EURGBP.png",
        "Profit": -0.41,
        "Digits": 5
      }
    ],
    "accountinfo": [
      {
        "Assets": 0,
        "Balance": 260.09,
        "BlockedCommission": 0,
        "BlockedProfit": 3.09,
        "Credit": 0,
        "CurrencyDigits": 2,
        "Equity": 261,
        "Floating": 0.91,
        "Liabilities": 0,
        "Login": 301333,
        "Margin": 9.39,
        "MarginFree": 251.61,
        "MarginInitial": 0,
        "MarginLevel": 2779.55,
        "MarginLeverage": 500,
        "MarginMaintenance": 0,
        "Profit": 0.91,
        "SOActivation": 0,
        "SOEquity": 0,
        "SOLevel": 0,
        "SOMargin": 0,
        "SOTime": 0,
        "Storage": 0
      }
    ]
  },
  "realtime": true,
  "server_timestamp": 1757927404918
}
```

## Usage

### 1. Automatic Initialization

The WebSocket service is automatically initialized when the trade screen loads:

```dart
@override
void initState() {
  super.initState();
  // Initialize WebSocket service for trading data
  Get.put(TradingWebSocketService());
}
```

### 2. Manual Refresh

You can manually refresh the trading data:

```dart
void _refreshTradingData() {
  final tradingWebSocketService = Get.find<TradingWebSocketService>();
  tradingWebSocketService.refreshTradingData();
}
```

### 3. Accessing Real Data

The UI automatically updates when new data arrives:

```dart
// Account metrics are automatically updated
Obx(() => _buildAccountMetrics(tradingController))

// Trading positions are automatically updated
Obx(() => _buildPositionsList(tradingController))
```

## Features

### 1. Real-time Account Metrics

- **Balance**: Current account balance
- **Equity**: Account equity
- **Credit**: Available credit
- **Swap**: Storage/swap costs
- **Margin**: Used margin
- **Free Margin**: Available margin
- **Margin Level**: Margin level percentage

### 2. Live Trading Positions

- **Symbol**: Trading instrument (e.g., EURUSD, GBPUSD)
- **Action**: Buy or Sell
- **Volume**: Position size
- **Entry Price**: Price when position was opened
- **Current Price**: Current market price
- **Profit/Loss**: Real-time P&L
- **Flag**: Country flag emoji for the currency pair

### 3. Connection Management

- **Automatic Reconnection**: Reconnects if connection is lost
- **App Lifecycle Handling**: Manages connection during app state changes
- **Error Handling**: Graceful error handling and logging

## Error Handling

The service includes comprehensive error handling:

- **Connection Errors**: Automatic reconnection with exponential backoff
- **Data Parsing Errors**: Logged but don't crash the app
- **Authentication Errors**: Handles missing or invalid tokens
- **Network Errors**: Graceful fallback to cached data

## Logging

All WebSocket activities are logged for debugging:

```dart
dev.log('Trading WS: Connected successfully');
dev.log('Trading WS: Received data: $data');
dev.log('Trading WS: Updated trading data successfully');
```

## Testing

To test the integration:

1. **Start the app** and navigate to the trade screen
2. **Check the logs** for WebSocket connection status
3. **Verify data updates** when new positions are opened/closed
4. **Test reconnection** by toggling network connectivity

## Troubleshooting

### Common Issues

1. **No Data Displayed**: Check if WebSocket token is available
2. **Connection Failed**: Verify WebSocket URL and network connectivity
3. **Data Not Updating**: Check if WebSocket service is properly initialized

### Debug Steps

1. Check logs for WebSocket connection status
2. Verify authentication token is valid
3. Confirm MT5 account number is correct
4. Test WebSocket connection manually if needed
