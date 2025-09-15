import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static AudioPlayer? _audioPlayer;
  static bool _isInitialized = false;

  // Initialize the audio player
  static Future<void> _initializePlayer() async {
    if (!_isInitialized) {
      _audioPlayer = AudioPlayer();
      _isInitialized = true;
      debugPrint('=== AUDIO SERVICE: Player initialized ===');
    }
  }

  // Play no money sound
  static Future<void> playNoMoneySound() async {
    try {
      debugPrint('=== AUDIO SERVICE: Playing no money sound ===');

      await _initializePlayer();

      if (_audioPlayer == null) {
        debugPrint('Error: Audio player not initialized');
        return;
      }

      // Stop any currently playing audio
      await _audioPlayer!.stop();

      // Try different asset paths
      try {
        // First try: assets/audio/ path
        await _audioPlayer!.play(AssetSource('audio/no_money.wav'));
        debugPrint('Successfully played no money sound from assets/audio/!');
        return;
      } catch (e1) {
        debugPrint('Error with assets/audio/ path: $e1');
      }

      try {
        // Second try: direct asset path
        await _audioPlayer!.play(AssetSource('no_money.wav'));
        debugPrint('Successfully played no money sound from direct path!');
        return;
      } catch (e2) {
        debugPrint('Error with direct path: $e2');
      }

      try {
        // Third try: Android raw resources
        await _audioPlayer!.play(
          AssetSource('android/app/src/main/res/raw/no_money.wav'),
        );
        debugPrint('Successfully played no money sound from Android raw!');
        return;
      } catch (e3) {
        debugPrint('Error with Android raw path: $e3');
      }

      // Final fallback: play alert sound
      await playAlertSound();
    } catch (e) {
      debugPrint('Error playing no money sound: $e');
    }
  }

  // Play alert sound
  static Future<void> playAlertSound() async {
    try {
      debugPrint('=== AUDIO SERVICE: Playing alert sound ===');

      await _initializePlayer();

      if (_audioPlayer == null) {
        debugPrint('Error: Audio player not initialized');
        return;
      }

      await _audioPlayer!.stop();

      // Try different asset paths
      try {
        await _audioPlayer!.play(AssetSource('audio/alert_sound.mp3'));
        debugPrint('Successfully played alert sound from assets/audio/!');
        return;
      } catch (e1) {
        debugPrint('Error with assets/audio/ path: $e1');
      }

      try {
        await _audioPlayer!.play(
          AssetSource('android/app/src/main/res/raw/alert_sound.mp3'),
        );
        debugPrint('Successfully played alert sound from Android raw!');
        return;
      } catch (e2) {
        debugPrint('Error with Android raw path: $e2');
      }
    } catch (e) {
      debugPrint('Error playing alert sound: $e');
    }
  }

  // Play success sound
  static Future<void> playSuccessSound() async {
    try {
      debugPrint('=== AUDIO SERVICE: Playing success sound ===');

      await _initializePlayer();

      if (_audioPlayer == null) {
        debugPrint('Error: Audio player not initialized');
        return;
      }

      await _audioPlayer!.stop();

      // Try different asset paths
      try {
        await _audioPlayer!.play(AssetSource('audio/success.mp3'));
        debugPrint('Successfully played success sound from assets/audio/!');
        return;
      } catch (e1) {
        debugPrint('Error with assets/audio/ path: $e1');
      }

      try {
        await _audioPlayer!.play(
          AssetSource('android/app/src/main/res/raw/success.mp3'),
        );
        debugPrint('Successfully played success sound from Android raw!');
        return;
      } catch (e2) {
        debugPrint('Error with Android raw path: $e2');
      }
    } catch (e) {
      debugPrint('Error playing success sound: $e');
    }
  }

  // Play trade close sound
  static Future<void> playTradeCloseSound() async {
    try {
      debugPrint('=== AUDIO SERVICE: Playing trade close sound ===');

      await _initializePlayer();

      if (_audioPlayer == null) {
        debugPrint('Error: Audio player not initialized');
        return;
      }

      await _audioPlayer!.stop();

      // Try different asset paths
      try {
        await _audioPlayer!.play(AssetSource('audio/tradeclose.wav'));
        debugPrint('Successfully played trade close sound from assets/audio/!');
        return;
      } catch (e1) {
        debugPrint('Error with assets/audio/ path: $e1');
      }

      try {
        await _audioPlayer!.play(
          AssetSource('android/app/src/main/res/raw/tradeclose.wav'),
        );
        debugPrint('Successfully played trade close sound from Android raw!');
        return;
      } catch (e2) {
        debugPrint('Error with Android raw path: $e2');
      }
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
    if (_audioPlayer != null) {
      await _audioPlayer!.dispose();
      _audioPlayer = null;
      _isInitialized = false;
      debugPrint('=== AUDIO SERVICE: Player disposed ===');
    }
  }
}
