import 'package:pipze/services/audio_service.dart';

/// Test the audio service
void testAudioService() async {
  print('=== TESTING AUDIO SERVICE ===');

  try {
    // Test no money sound
    print('\n1. Testing no money sound...');
    await AudioService.playNoMoneySound();
    await Future.delayed(Duration(seconds: 2));

    // Test alert sound
    print('\n2. Testing alert sound...');
    await AudioService.playAlertSound();
    await Future.delayed(Duration(seconds: 2));

    // Test success sound
    print('\n3. Testing success sound...');
    await AudioService.playSuccessSound();
    await Future.delayed(Duration(seconds: 2));

    // Test trade close sound
    print('\n4. Testing trade close sound...');
    await AudioService.playTradeCloseSound();
    await Future.delayed(Duration(seconds: 2));

    print('\n✅ All audio tests completed!');
  } catch (e) {
    print('❌ Error during audio testing: $e');
  } finally {
    // Dispose the audio player
    await AudioService.dispose();
  }
}

/// Run the test
void main() async {
  await testAudioService();
}
