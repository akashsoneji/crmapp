// ==================== PENDING ORDERS INTEGRATION GUIDE ====================
// Follow these steps to integrate pending orders into your app

// ==================== STEP 1: Add to main.dart ====================
/*
import 'package:get/get.dart';
import 'services/pending_orders_initialization.dart';
import 'controllers/trading_controller.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // ... your existing config
    );
  }
}

class MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() async {
    // Initialize your existing controllers first
    Get.put(TradingController());
    
    // Then initialize pending orders
    await PendingOrdersInitialization.initialize();
  }
}
*/

// ==================== STEP 2: Add to your trade screen ====================
/*
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/trading_controller.dart';
import '../widgets/pending_orders_list.dart';

class YourTradeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trading'),
        actions: [
          // Add pending orders button
          IconButton(
            icon: Icon(Icons.schedule),
            onPressed: () => _showPendingOrders(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Your existing content
          Expanded(child: YourExistingContent()),
          
          // Pending orders summary
          _buildPendingOrdersSummary(),
        ],
      ),
    );
  }

  Widget _buildPendingOrdersSummary() {
    return Obx(() {
      final tradingController = Get.find<TradingController>();
      final pendingOrders = tradingController.pendingOrders;
      
      if (pendingOrders.isEmpty) return SizedBox.shrink();

      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          border: Border(
            top: BorderSide(color: Colors.blue.withOpacity(0.3)),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule, color: Colors.blue),
            SizedBox(width: 8),
            Text('${pendingOrders.length} Pending Orders'),
            Spacer(),
            TextButton(
              onPressed: () => _showPendingOrders(context),
              child: Text('View All'),
            ),
          ],
        ),
      );
    });
  }

  void _showPendingOrders(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Pending Orders',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Pending orders list
              Expanded(child: PendingOrdersList()),
            ],
          ),
        ),
      ),
    );
  }
}
*/

// ==================== STEP 3: Debug if not working ====================
/*
// Add this to your app for debugging
import 'screens/debug/pending_orders_debug_screen.dart';

// Add a debug button somewhere in your app
IconButton(
  icon: Icon(Icons.bug_report),
  onPressed: () => Get.to(() => PendingOrdersDebugScreen()),
),
*/

// ==================== STEP 4: WebSocket Message Format ====================
/*
// The WebSocket will send this message:
{
  "type": "pendingOrders",
  "authID": "your_jwt_token",
  "mt5AccountNumber": 301333,
  "isapp": "1"
}

// And receive responses like:
{
  "pendingOrders": {
    "pendingOrders": [
      {
        "MT5Account": 301333,
        "Order": 43748,
        "Action": "Buy Limit",
        "Symbol": "XAUUSD.c",
        "PriceOrder": 3660,
        "PriceCurrent": 3667.94,
        "Volume": 0.02,
        "PriceSL": 0,
        "PriceTP": 3666.17,
        "TimeCreate": "2025-09-18 14:56:31",
        "State": "PLACED",
        "Logo": "https://my.pipze.com/assets/themesfrontend/images/currency/XAUUSD.c.png"
      }
    ]
  },
  "realtime": true,
  "server_timestamp": 1758194149702
}
*/

// ==================== STEP 5: Troubleshooting ====================
/*
Common issues and solutions:

1. **No pending orders showing:**
   - Check if WebSocket is connected (use debug screen)
   - Verify auth token is valid
   - Check if MT5 account is active
   - Ensure WebSocket URL is correct

2. **WebSocket not connecting:**
   - Check internet connection
   - Verify WebSocket URL
   - Check auth token
   - Look at debug logs

3. **Data not updating:**
   - Check if TradingController is properly initialized
   - Verify WebSocket listeners are set up
   - Check if data is being received (debug screen)

4. **UI not updating:**
   - Make sure you're using Obx() or GetBuilder()
   - Check if controllers are properly registered
   - Verify reactive variables are being used
*/

// ==================== STEP 6: Testing ====================
/*
// Test the integration:
1. Open the debug screen
2. Check connection status
3. Send test message
4. Verify data is received
5. Check if UI updates
*/
