# WebSocket Integration for Instruments Screen

This document explains how to use the WebSocket functionality integrated into your instruments screen.

## Overview

The WebSocket integration provides real-time price updates for trading instruments, allowing users to see live market data without refreshing the screen.

## Files Created/Modified

### 1. `lib/controllers/instruments_websocket_controller.dart`
- **Purpose**: Manages WebSocket connection and handles real-time data
- **Features**:
  - Automatic connection to WebSocket server
  - Automatic reconnection on connection loss
  - Real-time price updates
  - Connection status monitoring
  - Error handling and logging

### 2. `lib/controllers/instruments_controller.dart`
- **Added Methods**:
  - `updateInstrumentPrice()`: Updates instrument prices from WebSocket data
  - `updatePriceTick()`: Updates price ticks from WebSocket data
  - `updateInstrumentsList()`: Updates the entire instruments list
  - `isWebSocketConnected`: Getter for WebSocket connection status

### 3. `lib/bindings/instruments_websocket_binding.dart`
- **Purpose**: Dependency injection for the WebSocket controller

### 4. `lib/screens/home/instruments_screen.dart`
- **Added Features**:
  - WebSocket connection status indicator
  - Real-time update indicators on price fields
  - Connect/Disconnect button
  - Automatic subscription to instrument updates

## How It Works

### 1. Connection Management
- WebSocket automatically connects when the screen loads
- Shows connection status (Connected/Disconnected/Error)
- Automatic reconnection on connection loss
- Manual connect/disconnect button available

### 2. Real-time Updates
- Automatically subscribes to all instrument updates
- Updates instrument prices in real-time
- Shows visual indicators for live data
- Timestamps for last updates

### 3. Data Flow
```
WebSocket Server → InstrumentsWebSocketController → InstrumentsController → UI Update
```

## Configuration

### WebSocket URL
Update the WebSocket URL in `instruments_websocket_controller.dart`:

```dart
final String socketUrl = 'wss://your-websocket-server.com:port';
```

### Message Format
The WebSocket expects messages in this format:

```json
{
  "type": "instrument_update",
  "symbol": "EURUSD",
  "bid": "1.24948",
  "ask": "1.24959",
  "high": "1.25000",
  "low": "1.24800"
}
```

Or for price ticks:

```json
{
  "type": "price_tick",
  "symbol": "EURUSD",
  "price": "1.24948",
  "change": "+0.0012"
}
```

## Usage Examples

### 1. Subscribe to Specific Instrument
```dart
_webSocketController.subscribeToInstrument("EURUSD");
```

### 2. Send Custom Event
```dart
_webSocketController.sendEvent({
  "action": "subscribe",
  "symbol": "EURUSD",
  "type": "instrument"
});
```

### 3. Check Connection Status
```dart
if (_webSocketController.isConnected.value) {
  print("WebSocket is connected");
} else {
  print("WebSocket is disconnected");
}
```

### 4. Get Last Update Time
```dart
final lastUpdate = _webSocketController.lastUpdateTime.value;
print("Last update: $lastUpdate");
```

## UI Features

### 1. Connection Status Indicator
- Green dot + "Connected" when WebSocket is active
- Red dot + "Disconnected" when connection is lost
- Shows last update timestamp

### 2. Real-time Price Indicators
- Small green dots next to bid/ask prices when connected
- Grey dots when disconnected
- Visual feedback for live data

### 3. Connection Management Button
- "Connect" button when disconnected
- "Disconnect" button when connected
- Easy manual connection control

## Error Handling

- Automatic reconnection on connection loss
- Error logging for debugging
- Graceful fallback when WebSocket is unavailable
- User-friendly error messages

## Testing

### 1. Test Connection
1. Open the instruments screen
2. Check if connection status shows "Connected"
3. Verify green dots appear next to prices

### 2. Test Disconnection
1. Click the "Disconnect" button
2. Verify status changes to "Disconnected"
3. Check if green dots turn grey

### 3. Test Reconnection
1. Disconnect the WebSocket
2. Click "Connect" button
3. Verify reconnection and status update

## Troubleshooting

### Common Issues

1. **Connection Failed**
   - Check WebSocket URL
   - Verify server is running
   - Check network connectivity

2. **No Real-time Updates**
   - Verify WebSocket connection
   - Check message format from server
   - Ensure proper subscription

3. **Performance Issues**
   - Monitor WebSocket message frequency
   - Check for memory leaks
   - Verify efficient UI updates

### Debug Information
Enable debug logging by checking console output:
- Connection status changes
- Message processing
- Error details
- Reconnection attempts

## Future Enhancements

1. **Message Queuing**: Buffer messages during disconnection
2. **Selective Updates**: Subscribe only to visible instruments
3. **Data Compression**: Optimize message size
4. **Multiple Servers**: Fallback server support
5. **Message Validation**: Enhanced data validation
6. **Performance Metrics**: Connection quality monitoring

## Support

For issues or questions about the WebSocket integration:
1. Check the console logs for error messages
2. Verify WebSocket server configuration
3. Test with a simple WebSocket client
4. Review the integration code for customizations
