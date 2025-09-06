# Socket Debug Guide - Issues and Solutions

## Issues Identified from Logs:

### 1. **Multiple Socket Initialization**
```
[log] Chart: Initializing WebSocket connection
[log] Chart: Initializing socket with symbol: EURUSD.c
[log] Chart: Initializing WebSocket connection
[log] Chart: Initializing socket with symbol: EURUSD.c
[log] Chart: Initializing WebSocket connection
```

### 2. **Socket Connection Closing Immediately**
```
[log] Chart WebSocket connection closed
[log] Chart: Scheduling reconnection attempt 1 in 3 seconds
```

### 3. **"Cannot add event after closing" Error**
```
E/flutter: [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: Bad state: Cannot add event after closing.
```

## Root Causes:

1. **Controller Initialization**: ChartSocketController tries to initialize WebSocket immediately in `onInit()` without a symbol
2. **Multiple Calls**: `_initializeWithFirstInstrument()` and other methods calling `initializeSocketForSymbol()` multiple times
3. **Race Conditions**: Socket being closed while trying to send events
4. **Missing Symbol Check**: `getSocketData()` being called without a symbol set

## Solutions Implemented:

### 1. **Fixed Controller Initialization**
```dart
@override
void onInit() {
  super.onInit();
  dev.log('ChartSocketController: onInit called');
  
  // Add lifecycle observer to handle app state changes
  WidgetsBinding.instance.addObserver(this);
  
  // Don't initialize WebSocket immediately - wait for symbol to be set
  dev.log('Chart: Waiting for symbol to be set before initializing WebSocket');
}
```

### 2. **Added Symbol Check in getSocketData()**
```dart
void getSocketData() async {
  // Check if we have a symbol set
  if (currentSymbol.value.isEmpty) {
    dev.log('Chart: No symbol set, cannot get socket data');
    return;
  }
  // ... rest of the method
}
```

### 3. **Prevented Multiple Initializations**
```dart
void initializeWebSocket() {
  // Prevent multiple initializations
  if (isConnected.value) {
    dev.log('Chart: WebSocket already connected, skipping initialization');
    return;
  }
  // ... rest of the method
}
```

### 4. **Fixed Send Event Error Handling**
```dart
void sendEvent(Map<String, dynamic> event) {
  try {
    if (isConnected.value) {
      final encoded = jsonEncode(event);
      channel.sink.add(encoded);
      dev.log('Chart: Sent event: $event');
    } else {
      dev.log('Chart: Cannot send event - socket not connected');
    }
  } catch (e) {
    dev.log('Chart: Error sending event: $e');
    // If sending fails, mark as disconnected
    isConnected.value = false;
  }
}
```

## Expected Flow After Fixes:

1. **App Start**: Controller created, no socket initialized
2. **Chart Screen Init**: Gets first instrument symbol
3. **Socket Init**: Initializes socket with symbol
4. **Data Request**: Sends request for specific symbol
5. **Data Received**: Updates UI with real-time data
6. **Symbol Change**: Clean disconnect/reconnect cycle

## Testing Steps:

1. **Start App**: Should see "Waiting for symbol to be set"
2. **Navigate to Chart**: Should see "Initializing socket for first instrument"
3. **Socket Connection**: Should see "Chart: Initializing WebSocket connection"
4. **Data Request**: Should see "Requesting data for symbol: EURUSD.c"
5. **Data Received**: Should see price updates in UI
6. **Change Symbol**: Should see clean disconnect/reconnect

## Debug Commands:

```bash
# Run with verbose logging
flutter run --debug --verbose

# Check for compilation errors
flutter analyze

# Clean and rebuild
flutter clean && flutter pub get && flutter run
```

## Key Log Messages to Look For:

✅ **Good Signs:**
- `Chart: Waiting for symbol to be set before initializing WebSocket`
- `Chart: Initializing socket for first instrument: EURUSD.c`
- `Chart: Requesting data for symbol: EURUSD.c`
- `Chart: Sent event: {...}`
- `Chart: Updated realTimePrice.value with new data`

❌ **Bad Signs:**
- `Chart: Initializing WebSocket connection` (multiple times)
- `Chart WebSocket connection closed` (immediately after init)
- `Cannot add event after closing`
- `Chart: No symbol set, cannot get socket data`
