import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  // Play no money sound
  static Future<void> playNoMoneySound() async {
    try {
      debugPrint('=== AUDIO SERVICE: Playing no money sound ===');

      // Stop any currently playing audio
      await _audioPlayer.stop();

      // Play the no money sound from assets
      await _audioPlayer.play(AssetSource('audio/no_money.wav'));
      debugPrint('Successfully played no money sound!');
    } catch (e) {
      debugPrint('Error playing no money sound: $e');

      try {
        // Fallback: try alternative path
        await _audioPlayer.play(AssetSource('no_money.wav'));
        debugPrint('Successfully played no money sound from fallback!');
      } catch (e2) {
        debugPrint('Error playing no money sound fallback: $e2');

        // Last fallback: play alert sound
        try {
          await _audioPlayer.play(AssetSource('audio/alert_sound.mp3'));
          debugPrint('Successfully played alert sound as fallback!');
        } catch (e3) {
          debugPrint('All sound playback attempts failed: $e3');
        }
      }
    }
  }

  // Play alert sound
  static Future<void> playAlertSound() async {
    try {
      debugPrint('=== AUDIO SERVICE: Playing alert sound ===');

      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/alert_sound.mp3'));
      debugPrint('Successfully played alert sound!');
    } catch (e) {
      debugPrint('Error playing alert sound: $e');
    }
  }

  // Play success sound
  static Future<void> playSuccessSound() async {
    try {
      debugPrint('=== AUDIO SERVICE: Playing success sound ===');

      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/success.mp3'));
      debugPrint('Successfully played success sound!');
    } catch (e) {
      debugPrint('Error playing success sound: $e');
    }
  }

  // Play trade close sound
  static Future<void> playTradeCloseSound() async {
    try {
      debugPrint('=== AUDIO SERVICE: Playing trade close sound ===');

      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/tradeclose.wav'));
      debugPrint('Successfully played trade close sound!');
    } catch (e) {
      debugPrint('Error playing trade close sound: $e');
    }
  }

  // Test method
  static Future<void> testSound() async {
    debugPrint('=== AUDIO SERVICE: Testing sound playback ===');
    await playNoMoneySound();
  }

  // Dispose the audio player
  static Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
