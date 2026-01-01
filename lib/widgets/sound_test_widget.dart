import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chart_controller.dart';

class SoundTestWidget extends StatelessWidget {
  const SoundTestWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Test Audio Playback',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Test No Money Sound Button
            ElevatedButton(
              onPressed: () async {
                try {
                  final controller = Get.put(ChartController());
                  await controller.testNoMoneySound();

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No Money Sound Test Completed'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
              child: const Text(
                'Test No Money Sound',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),

            const SizedBox(height: 20),

            // Instructions
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. Make sure your device volume is turned up'),
                    Text('2. Click the button above to test the sound'),
                    Text('3. Check the console logs for debug information'),
                    Text(
                      '4. The sound should play when you get "Not enough money" error',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
