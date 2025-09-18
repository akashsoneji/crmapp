// ==================== TEST PENDING ORDERS ====================
// Use this to test if pending orders are working

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/pending_orders_initialization.dart';
import '../controllers/trading_controller.dart';
import '../widgets/pending_orders_list.dart';

class TestPendingOrdersScreen extends StatefulWidget {
  const TestPendingOrdersScreen({Key? key}) : super(key: key);

  @override
  State<TestPendingOrdersScreen> createState() =>
      _TestPendingOrdersScreenState();
}

class _TestPendingOrdersScreenState extends State<TestPendingOrdersScreen> {
  @override
  void initState() {
    super.initState();
    _initializeTest();
  }

  void _initializeTest() async {
    print('🚀 Starting pending orders test...');

    // Initialize pending orders
    await PendingOrdersInitialization.initialize();

    // Wait a bit for connection
    await Future.delayed(Duration(seconds: 2));

    // Check if we have any pending orders
    final tradingController = Get.find<TradingController>();
    print('📊 Pending orders count: ${tradingController.pendingOrders.length}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Pending Orders'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              PendingOrdersInitialization.reconnect();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.blue.withOpacity(0.1),
            child: Column(
              children: [
                Text(
                  'Pending Orders Test',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'This screen tests if pending orders are working correctly.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

          // Pending orders list
          Expanded(child: PendingOrdersList()),

          // Test buttons
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          PendingOrdersInitialization.initialize();
                        },
                        child: Text('Initialize'),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          PendingOrdersInitialization.reconnect();
                        },
                        child: Text('Reconnect'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          PendingOrdersInitialization.disconnect();
                        },
                        child: Text('Disconnect'),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                        },
                        child: Text('Close'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== HOW TO USE ====================
/*
1. Add this to your main.dart:
   Get.to(() => TestPendingOrdersScreen());

2. Or add a test button somewhere:
   ElevatedButton(
     onPressed: () => Get.to(() => TestPendingOrdersScreen()),
     child: Text('Test Pending Orders'),
   ),

3. Check the console for debug messages
4. Verify if pending orders are loading
5. Test the connection status
*/
