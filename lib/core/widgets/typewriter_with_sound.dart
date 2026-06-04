import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class TypewriterWithSound extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration speed;
  final bool playSound;

  const TypewriterWithSound({
    super.key,
    required this.text,
    this.style,
    this.speed = const Duration(milliseconds: 80),
    this.playSound = true,
  });

  @override
  State<TypewriterWithSound> createState() => _TypewriterWithSoundState();
}

class _TypewriterWithSoundState extends State<TypewriterWithSound> {
  String _displayedText = '';
  int _currentIndex = 0;
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.speed, (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayedText += widget.text[_currentIndex];
          _currentIndex++;
        });
        
        // Play sound for each character
        if (widget.playSound && widget.text[_currentIndex - 1] != ' ') {
          _playTypeSound();
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _playTypeSound() async {
    try {
      // Play a short click sound
      await _audioPlayer.play(
        AssetSource('sounds/click.mp3'),
        volume: 0.2,
        mode: PlayerMode.lowLatency,
      );
    } catch (e) {
      // Silently fail if sound not available
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
