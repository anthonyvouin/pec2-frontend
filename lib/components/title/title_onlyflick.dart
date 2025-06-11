import 'package:flutter/material.dart';

class TitleOnlyFlick extends StatelessWidget {
  const TitleOnlyFlick({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      ),
    );
  }
}
