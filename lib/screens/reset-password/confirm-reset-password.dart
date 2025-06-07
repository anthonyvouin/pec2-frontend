import 'package:flutter/material.dart';
import 'package:firstflutterapp/components/form/custom_form_field.dart';
import 'package:firstflutterapp/components/form/loading_button.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:firstflutterapp/services/toast_service.dart';
import 'package:firstflutterapp/services/validators_service.dart';
import 'package:toastification/toastification.dart';
import 'package:go_router/go_router.dart';
import '../../config/router.dart';

class ConfirmResetPasswordPage extends StatefulWidget {
  @override
  State<ConfirmResetPasswordPage> createState() => _ConfirmResetPasswordPageState();
}

class _ConfirmResetPasswordPageState extends State<ConfirmResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isSubmitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    if (extra is String && extra.isNotEmpty) {
      _emailController.text = extra;
    }
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
        endpoint: '/users/password/reset/confirm',
        body: {
          'email': _emailController.text,
          'code': _codeController.text,
          'newPassword': _passwordController.text,
        },
        withAuth: false,
      );
      if (response.success) {
        ToastService.showToast(
          'Mot de passe réinitialisé avec succès !',
          ToastificationType.success,
        );
        if (!mounted) return;
        context.go(loginRoute);
      } else {
        ToastService.showToast(
          response.error ?? 'Erreur lors de la réinitialisation',
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
        title: Text('Confirmer la réinitialisation'),
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
                Text(
                  'Entrez votre email, le code reçu et votre nouveau mot de passe.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  validators: [RequiredValidator(), EmailValidator()],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _codeController,
                  label: 'Code',
                  validators: [RequiredValidator()],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  label: 'Nouveau mot de passe',
                  obscure: true,
                  showText: false,
                  validators: [RequiredValidator(), PasswordValidator()],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Retaper le mot de passe',
                  obscure: true,
                  showText: false,
                  validators: [RequiredValidator(), SamePasswordValidator(() => _passwordController.text)],
                ),
                const SizedBox(height: 24),
                LoadingButton(
                  label: 'Réinitialiser',
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
