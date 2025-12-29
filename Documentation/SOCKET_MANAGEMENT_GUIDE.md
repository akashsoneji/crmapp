# Socket Management Implementation Guide

## Overview
This guide explains the comprehensive socket management system implemented for the chart and instruments screens to handle real-time price data with proper connection management.

## Key Features

### 1. **Symbol Change Management**
- **Close existing socket** when changing symbols
- **Reconnect with new symbol** automatically
- **Clear old price data** before connecting to new symbol
- **Proper timing** with delays to ensure clean disconnection

### 2. **App Lifecycle Handling**
- **App Resume**: Reconnects socket if disconnected
- **App Pause**: Maintains connection but logs status
- **App Detached**: Properly closes socket connection
- **App Restart**: Handles complete reconnection with current symbol

### 3. **Real-time Price Updates**
- **Chart Screen**: Displays real-time bid/ask prices and spread
- **Instruments Screen**: Shows live price updates for all instruments
- **Stream-based Updates**: Uses reactive streams for UI updates

## Implementation Details

### ChartSocketController (`lib/controllers/chart_socket_controller.dart`)

#### Key Methods:
- `changeSymbol(String newSymbol)`: Handles symbol changes with proper socket management
- `initializeSocketForSymbol(String symbol)`: Initializes socket for specific symbol
- `handleAppRestart()`: Manages app restart scenarios
- `_disconnectWebSocket()`: Properly closes socket and cleans up data

#### Socket Flow:
1. **Symbol Change**: Disconnect → Clear Data → Wait → Reconnect with New Symbol
2. **App Resume**: Check Connection → Reconnect if Needed
3. **App Detached**: Close Connection → Clean Up

### Chart Screen (`lib/screens/home/chart_screen.dart`)

#### Key Features:
- **Symbol Change Listener**: Responds to symbol changes from instruments screen
- **Price Stream Listener**: Updates UI with real-time price data
- **Lifecycle Management**: Handles app state changes

#### Flow:
1. **Instruments → Chart**: Sets symbol → Triggers socket change
2. **Price Updates**: Stream listener updates UI automatically
3. **App Lifecycle**: Manages socket connection based on app state

### Instruments Screen (`lib/screens/home/instruments_screen.dart`)

#### Key Features:
- **Navigation to Chart**: Properly sets symbol and navigates
- **Real-time Updates**: Displays live price data from socket
- **Symbol Selection**: Handles user symbol selection

## Usage Examples

### 1. Changing Symbol from Instruments to Chart
```dart
// In InstrumentsScreen
void _navigateToChartWithSymbol(String symbol) {
  ChartScreen.setSelectedSymbol(symbol);  // Sets symbol
  widget.onNavigateToChart!(symbol);     // Navigates to chart
}

// In ChartScreen
void _onSymbolChangedFromInstruments() {
  final newSymbol = ChartScreen._selectedSymbolNotifier.value;
  if (newSymbol != selectedSymbol && mounted) {
    setState(() {
      selectedSymbol = newSymbol;
    });
    _changeChartSymbol(newSymbol);  // Handles socket change
  }
}
```

### 2. Socket Symbol Change
```dart
// In ChartSocketController
Future<void> changeSymbol(String newSymbol) async {
  // Disconnect existing connection
  if (isConnected.value) {
    _disconnectWebSocket();
    await Future.delayed(const Duration(milliseconds: 300));
  }
  
  // Update symbol and clear data
  currentSymbol.value = newSymbol;
  realTimePrice.clear();
  
  // Reconnect with new symbol
  await Future.delayed(const Duration(milliseconds: 500));
  initializeWebSocket();
}
```

### 3. App Lifecycle Handling
```dart
// In ChartScreen
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  switch (state) {
    case AppLifecycleState.resumed:
      if (!chartSocketController.isConnected.value) {
        chartSocketController.handleAppRestart();
      }
      break;
    case AppLifecycleState.detached:
      chartSocketController.resetController();
      break;
  }
}
```

## Socket Data Format

The socket receives data in this format:
```json
{
  "singleSymbol": {
    "Ask": 1.16733,
    "Bid": 1.16715,
    "Digits": 5,
    "Last": 0,
    "SpreadDiff": 0,
    "Symbol": "EURUSD.c",
    "Volume": 0,
    "VolumeReal": 0,
    "data_source": "realtime_synchronized_local",
    "logo": "https://beta.pipze.com/assets/themes/frontend/images/currency/EURUSD.png",
    "timestamp": 1757051584185,
    "spread": 19
  },
  "realtime": true,
  "server_timestamp": 1757051584185
}
```

## Logging

The implementation includes comprehensive logging:
- `🎯 Symbol`: Symbol changes
- `📡 Connection`: Socket connection status
- `💰 Price`: Price updates
- `🔄 Process`: Symbol change process
- `✅ Success`: Successful operations
- `❌ Error`: Error handling

## Testing the Flow

1. **Start App**: Socket connects with default symbol
2. **Navigate to Instruments**: Shows real-time price data
3. **Select Different Symbol**: Navigates to chart with new symbol
4. **Chart Updates**: Shows real-time data for selected symbol
5. **Change Symbol Again**: Socket disconnects and reconnects with new symbol
6. **App Background/Foreground**: Socket reconnects properly
7. **App Restart**: Socket reconnects with last selected symbol

## Error Handling

- **Connection Errors**: Automatic reconnection with exponential backoff
- **Symbol Mismatch**: Flexible symbol matching (with/without .c suffix)
- **Disposal**: Prevents updates after controller disposal
- **Network Issues**: Graceful handling of network problems

## Performance Considerations

- **Stream Management**: Proper disposal of stream controllers
- **Memory Management**: Clearing old data when changing symbols
- **Connection Pooling**: Single connection per symbol
- **Reconnection Limits**: Maximum 5 reconnection attempts

This implementation ensures robust, real-time price data management with proper socket lifecycle handling for both chart and instruments screens.
