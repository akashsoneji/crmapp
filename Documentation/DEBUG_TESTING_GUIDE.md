# Debug Mode Testing & Logging Guide

## 🚀 Running in Debug Mode

### Quick Start
```cmd
REM Windows
flutter run --flavor afx -t lib/main.dart --dart-define=FLAVOR=afx --debug -d 63c805060706

REM Or use the debug script
.\debug.bat afx 63c805060706
```

---

## 📱 Testing Your App

### 1. **Hot Reload Testing**
While the app is running in debug mode:
- **Press `r`** in terminal → Hot reload (fast refresh, keeps state)
- **Press `R`** in terminal → Hot restart (full restart)
- **Press `q`** → Quit debug session

**Test Steps:**
1. Make a code change in your editor
2. Save the file
3. Press `r` in terminal
4. See changes instantly on your device!

### 2. **UI Testing**
- ✅ **Navigation** - Test all screens and navigation flows
- ✅ **Buttons** - Click all buttons and check responses
- ✅ **Forms** - Fill forms and submit
- ✅ **Trading** - Test buy/sell orders
- ✅ **Charts** - Check chart rendering and updates
- ✅ **WebSocket** - Verify real-time data updates

### 3. **Feature Testing Checklist**
```
□ Login/Logout flow
□ Account switching
□ Trading operations (Buy/Sell)
□ Order management
□ Chart display
□ Price updates
□ WebSocket connections
□ API calls
□ Error handling
□ Navigation between screens
```

---

## 📋 Viewing Logs

### Method 1: Terminal Logs (While Running)
All logs appear automatically in the terminal where you ran `flutter run`.

**Log Categories:**
- `[Trading]` - Trading operations and orders
- `[Chart]` - Chart updates and rendering  
- `[WebSocket]` - WebSocket connections and messages
- `[API]` - API calls and responses
- `[Order]` - Order placement and management
- `[Price]` - Price updates and quotes
- `[Debug]` - Debug information
- `[Error]` - Errors and exceptions

### Method 2: Separate Log Viewing
Open a **new terminal** and run:

```cmd
REM View all logs from your device
flutter logs -d 63c805060706

REM Filter specific log categories
flutter logs -d 63c805060706 | findstr "Trading"
flutter logs -d 63c805060706 | findstr "WebSocket"
flutter logs -d 63c805060706 | findstr "Error"
```

### Method 3: Android Logcat (Advanced)
```cmd
REM View all Android logs
adb logcat

REM Filter by tag
adb logcat -s Trading:* Chart:* WebSocket:* Error:*

REM Clear logs and start fresh
adb logcat -c
adb logcat
```

### Method 4: Filter Logs in Terminal
While app is running, you can filter logs:
```cmd
REM In PowerShell, filter logs
flutter logs -d 63c805060706 | Select-String "Trading"
flutter logs -d 63c805060706 | Select-String "Error"
```

---

## 🔍 What to Check in Logs

### 1. **App Initialization**
Look for:
```
[Debug] App started in DEBUG mode - All logs enabled
[Trading] Pipze Trading App initialized
[Chart] Chart system ready
[WebSocket] WebSocket system ready
```

### 2. **Authentication**
Look for:
```
[API] API Call: /api/auth/login
[Debug] User authenticated
[Trading] Primary account loaded
```

### 3. **WebSocket Connection**
Look for:
```
[WebSocket] WebSocket connecting...
[WebSocket] WebSocket connected
[WebSocket] WebSocket message received
```

### 4. **Trading Operations**
Look for:
```
[Order] Order Placement:
  - Symbol: EURUSD
  - Type: Buy
  - Volume: 0.01
[API] API Call: /api/orders/place
[Order] Order placed successfully
```

### 5. **Price Updates**
Look for:
```
[Price] Price Update - EURUSD: Bid: 1.0850, Ask: 1.0852
```

### 6. **Errors**
Look for:
```
[Error] Error message here
[Error] Stack trace details
```

---

## 🐛 Debugging Tips

### 1. **Set Breakpoints**
- In VS Code: Click left of line number to set breakpoint
- In Android Studio: Click left of line number
- App will pause at breakpoint when code executes

### 2. **Inspect Variables**
- Hover over variables in debugger
- Check "Variables" panel in debugger
- Use `print()` or `AppLogger.debug()` for quick checks

### 3. **Check Network Requests**
```cmd
REM View network traffic
adb logcat | findstr "HTTP"
```

### 4. **Monitor Performance**
- Check Flutter DevTools (accessible via debug console)
- Look for performance warnings in logs
- Monitor memory usage

### 5. **Test Error Scenarios**
- Disconnect internet → Check WebSocket reconnection logs
- Invalid login → Check error handling logs
- Network timeout → Check API error logs

---

## 📊 Log Examples

### Successful Login
```
[API] API Call:
  - Endpoint: /api/auth/login
  - Method: POST
  - Status: 200
[Debug] User authenticated
[Trading] Primary account loaded: 123456 (server1)
```

### WebSocket Connection
```
[WebSocket] WebSocket connecting to wss://api.afx.com/trade-engine
[WebSocket] WebSocket connected successfully
[WebSocket] WebSocket message received: {"type":"price","symbol":"EURUSD"}
```

### Order Placement
```
[Order] Order Placement:
  - Symbol: EURUSD
  - Type: Buy
  - Volume: 0.01
  - Price: Market
  - Take Profit: 1.0900
  - Stop Loss: 1.0800
[API] API Call: /api/orders/place
[Order] Order placed successfully: Order #12345
```

### Error Example
```
[Error] Flutter Error: Null check operator used on a null value
[Error] Stack trace:
  #0 TradingController.placeOrder (trading_controller.dart:45)
  #1 TradingScreen._handleBuy (trading_screen.dart:123)
```

---

## 🎯 Quick Testing Commands

### Test Hot Reload
1. Change a color or text in your code
2. Save file
3. Press `r` in terminal
4. See change instantly!

### Test Hot Restart
1. Make a significant change
2. Press `R` in terminal
3. App restarts with changes

### View Real-time Logs
```cmd
REM In a separate terminal
flutter logs -d 63c805060706
```

### Clear Logs and Start Fresh
```cmd
adb logcat -c
flutter run --flavor afx -t lib/main.dart --dart-define=FLAVOR=afx --debug -d 63c805060706
```

---

## ✅ Testing Checklist

After running in debug mode, verify:

- [ ] App launches successfully
- [ ] All screens load correctly
- [ ] Navigation works (back button, drawer, etc.)
- [ ] Login/logout works
- [ ] Trading operations work (buy/sell)
- [ ] Charts display correctly
- [ ] Price updates in real-time
- [ ] WebSocket connects and stays connected
- [ ] API calls succeed
- [ ] Error handling works (test with invalid inputs)
- [ ] Hot reload works (`r` key)
- [ ] Hot restart works (`R` key)
- [ ] Logs show all expected information
- [ ] No critical errors in logs

---

## 🆘 Troubleshooting

### App Not Launching
```cmd
REM Check if device is connected
flutter devices

REM Check for build errors
flutter doctor -v
```

### Logs Not Showing
```cmd
REM Check if debug mode is enabled
REM Look for: "App started in DEBUG mode" in logs

REM View logs separately
flutter logs -d 63c805060706
```

### Hot Reload Not Working
- Make sure you're in debug mode (`--debug` flag)
- Press `r` (lowercase) in the terminal where `flutter run` is active
- Check for compilation errors

### Can't See Specific Logs
```cmd
REM Filter logs by category
flutter logs -d 63c805060706 | findstr "Trading"
flutter logs -d 63c805060706 | findstr "Error"
```

---

## 📝 Summary

**To Run:**
```cmd
flutter run --flavor afx -t lib/main.dart --dart-define=FLAVOR=afx --debug -d 63c805060706
```

**To Test:**
- Use hot reload (`r`) for quick changes
- Test all features manually
- Check logs for issues

**To View Logs:**
- Terminal shows logs automatically
- Use `flutter logs -d 63c805060706` in separate terminal
- Filter with `findstr` or `Select-String`

**Debug Commands:**
- `r` = Hot reload
- `R` = Hot restart  
- `q` = Quit
- `h` = Help

Happy Debugging! 🐛✨

