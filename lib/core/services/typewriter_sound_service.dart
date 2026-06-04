import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class TypewriterSoundService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isInitialized = false;
  static bool _isEnabled = true;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setVolume(0.2);
      _isInitialized = true;
    } catch (e) {
      print('TypewriterSoundService: Failed to initialize - $e');
    }
  }

  static void enable() => _isEnabled = true;
  static void disable() => _isEnabled = false;

  static Future<void> playTypeSound() async {
    if (!_isEnabled || !_isInitialized) return;
    
    try {
      // Play system click sound as typewriter effect
      await HapticFeedback.lightImpact();
      
      // Alternative: Use a very short beep tone
      // Since we don't have audio file, we use haptic feedback
      // which gives a nice tactile response
    } catch (e) {
      // Silently fail
    }
  }

  static void dispose() {
    _audioPlayer.dispose();
  }
}
