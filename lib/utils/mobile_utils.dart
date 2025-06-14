import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool isMobileBrowser(BuildContext context) {
  if (!kIsWeb) return false;
  final width = MediaQuery.of(context).size.width;
  return width < 600;
}