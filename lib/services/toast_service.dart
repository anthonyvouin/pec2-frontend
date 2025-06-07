import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

enum TypeToast {
  success,
  danger,
  warning,
}

class ToastService {
  static void showToast(String message, ToastificationType toastType) {
    toastification.show(title: Text(message), type: toastType, autoCloseDuration: const Duration(seconds: 5));
  }
}