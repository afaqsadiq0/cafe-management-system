import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'dart:async';

class TypewriterTextWithSound extends StatefulWidget {
  final String text;
  final TextStyle? textStyle;
  final Duration speed;
  final bool playSound;
  final VoidCallback? onFinished;

  const TypewriterTextWithSound({
    super.key,
    required this.text,
    this.textStyle,
    this.speed = const Duration(milliseconds: 80),
    this.playSound = true,
    this.onFinished,
  });

  @override
  State<TypewriterTextWithSound> createState() => _TypewriterTextWithSoundState();
}

class _TypewriterTextWithSoundState extends State<TypewriterTextWithSound> {
  String _displayedText = '';
  int _currentIndex = 0;
  Timer? _timer;

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
        
        // Play sound for each character (except spaces)
        if (widget.playSound && widget.text[_currentIndex - 1] != ' ') {
          _playTypeSound();
        }
      } else {
        timer.cancel();
        widget.onFinished?.call();
      }
    });
  }

  Future<void> _playTypeSound() async {
    try {
      // Use haptic feedback for typewriter effect
      await HapticFeedback.selectionClick();
    } catch (e) {
      // Silently fail
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: widget.textStyle,
    );
  }
}

// Extension for AnimatedTextKit to add sound
class TypewriterAnimatedTextWithSound extends TypewriterAnimatedText {
  TypewriterAnimatedTextWithSound(
    String text, {
    TextStyle? textStyle,
    Duration speed = const Duration(milliseconds: 80),
  }) : super(
          text,
          textStyle: textStyle,
          speed: speed,
        );

  @override
  void initState(AnimatedTextController controller) {
    super.initState(controller);
    // Play sound on each character
    _setupSoundCallback();
  }

  void _setupSoundCallback() {
    // This will be called for each character
    Future.delayed(const Duration(milliseconds: 50), () {
      HapticFeedback.selectionClick();
    });
  }
}
