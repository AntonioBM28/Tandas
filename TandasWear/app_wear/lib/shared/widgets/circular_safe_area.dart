import 'package:flutter/material.dart';

class CircularSafeArea extends StatelessWidget {
  final Widget child;
  final double padding;

  const CircularSafeArea({
    super.key,
    required this.child,
    this.padding = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      alignment: Alignment.center,
      child: child,
    );
  }
}
