import 'package:flutter/material.dart';
import 'package:firstflutterapp/components/form/custom_form_field.dart';
import 'package:firstflutterapp/components/form/loading_button.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:firstflutterapp/services/toast_service.dart';
import 'package:firstflutterapp/services/validators_service.dart';
import 'package:toastification/toastification.dart';
import '../../config/router.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordRequestPage extends StatefulWidget {
  @override
  State<ResetPasswordRequestPage> createState() => _ResetPasswordRequestPageState();
}

class _ResetPasswordRequestPageState extends State<ResetPasswordRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isSubmitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    setState(() {
      _isSubmitted = true;
    });
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitted = false;
      });
      return;
    }
    try {
      final response = await _apiService.request(
        method: 'POST',
        endpoint: '/users/password/reset/request',
        body: {'email': _emailController.text},
        withAuth: false,
      );
      if (response.success) {
        ToastService.showToast(
          'Un code a été envoyé à votre adresse email si elle existe.',
          ToastificationType.success,
        );
        if (mounted) {
          context.go(confirmResetPasswordRoute, extra: _emailController.text);
        }
      } else {
        ToastService.showToast(
          response.error ?? 'Erreur lors de la demande',
          ToastificationType.error,
        );
      }
    } catch (e) {
      ToastService.showToast(
        'Erreur réseau',
        ToastificationType.error,
      );
    } finally {
      setState(() {
        _isSubmitted = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Réinitialiser le mot de passe'),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/reset-password.png',
                    width: 300,
                    height: 300,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Entrez votre adresse email pour recevoir un code de réinitialisation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  validators: [RequiredValidator(), EmailValidator()],
                ),
                const SizedBox(height: 24),
                LoadingButton(
                  label: 'Envoyer',
                  isSubmitted: _isSubmitted,
                  onPressed: _onSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
