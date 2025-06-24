import 'package:flutter/material.dart';

class EmptyStateView extends StatelessWidget {
  final String title;
  
  final String message;
  
  final IconData icon;
  
  final Color? iconColor;
  
  final VoidCallback onPrimaryAction;
  
  final String primaryActionText;
  
  final VoidCallback? onSecondaryAction;
  
  final String? secondaryActionText;
  
  final String? conditionalMessage;
  
  final bool showConditionalMessage;

  const EmptyStateView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.image_not_supported,
    this.iconColor,
    required this.onPrimaryAction,
    required this.primaryActionText,
    this.onSecondaryAction,
    this.secondaryActionText,
    this.conditionalMessage,
    this.showConditionalMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: iconColor ?? Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          if (showConditionalMessage && conditionalMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 32, right: 32),
              child: Text(
                conditionalMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onPrimaryAction,
            child: Text(primaryActionText),
          ),
          if (onSecondaryAction != null && secondaryActionText != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: TextButton(
                onPressed: onSecondaryAction,
                child: Text(secondaryActionText!),
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget pour afficher un état d'erreur
class ErrorStateView extends StatelessWidget {
  /// Message d'erreur à afficher
  final String errorMessage;
  
  /// Callback pour le bouton de réessai
  final VoidCallback onRetry;
  
  /// Callback pour le bouton alternatif (optionnel)
  final VoidCallback? onAlternativeAction;
  
  /// Texte du bouton alternatif
  final String? alternativeActionText;

  const ErrorStateView({
    super.key,
    required this.errorMessage,
    required this.onRetry,
    this.onAlternativeAction,
    this.alternativeActionText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Réessayer'),
          ),
          if (onAlternativeAction != null && alternativeActionText != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: TextButton(
                onPressed: onAlternativeAction,
                child: Text(alternativeActionText!),
              ),
            ),
        ],
      ),
    );
  }
}
