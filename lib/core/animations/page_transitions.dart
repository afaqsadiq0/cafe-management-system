import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppPageTransitions {
  static CustomTransitionPage<T> slideFade<T>({
    required Widget child,
    required LocalKey key,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
    );
  }

  static CustomTransitionPage<T> scaleUp<T>({
    required Widget child,
    required LocalKey key,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var tween = Tween<double>(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack));
        var fadeTween = Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut));

        return ScaleTransition(
          scale: animation.drive(tween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
    );
  }

  static CustomTransitionPage<T> sharedAxis<T>({
    required Widget child,
    required LocalKey key,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var tween = Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut));

        return FadeTransition(
          opacity: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}
