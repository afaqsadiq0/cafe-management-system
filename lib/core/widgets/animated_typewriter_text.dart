import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class AnimatedTypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration speed;
  final bool enableSound;
  final VoidCallback? onComplete;

  const AnimatedTypewriterText({
    super.key,
    required this.text,
    this.style,
    this.speed = const Duration(milliseconds: 80),
    this.enableSound = true,
    this.onComplete,
  });

  @override
  State<AnimatedTypewriterText> createState() => _AnimatedTypewriterTextState();
}

class _AnimatedTypewriterTextState extends State<AnimatedTypewriterText> {
  String _displayedText = '';
  int _currentIndex = 0;
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // High-quality typewriter key sound URL
  static const String _typewriterSoundUrl = 'https://assets.mixkit.co/active_storage/sfx/2358/2358-preview.mp3';

  @override
  void initState() {
    super.initState();
    if (widget.enableSound) {
      _prepareAudio();
    }
    _startTyping();
  }

  Future<void> _prepareAudio() async {
    // Audio will be played directly from URL to avoid initialization crashes
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.speed, (timer) {
      if (_currentIndex < widget.text.length) {
        if (mounted) {
          setState(() {
            _displayedText += widget.text[_currentIndex];
            _currentIndex++;
          });
        }
        
        // Play sound for each character (except spaces and emojis)
        final char = widget.text[_currentIndex - 1];
        if (widget.enableSound && char != ' ' && !_isEmoji(char)) {
          _playTypeSound();
        }
      } else {
        timer.cancel();
        widget.onComplete?.call();
      }
    });
  }

  bool _isEmoji(String char) {
    // Simple emoji detection
    final code = char.codeUnitAt(0);
    return code > 0x1F300;
  }

  Future<void> _playTypeSound() async {
    try {
      if (widget.enableSound) {
        await _audioPlayer.play(UrlSource(_typewriterSoundUrl), volume: 0.4);
        await HapticFeedback.selectionClick();
      }
    } catch (e) {
      // Silently fail if error occurs
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: widget.style,
    );
  }
}


