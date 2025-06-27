import 'package:flutter/material.dart';

class TitleOnlyFlick extends StatelessWidget {
  const TitleOnlyFlick({required this.text, this.fontSize = 32, super.key});

  final String text;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
    );
  }
}
