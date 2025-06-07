import 'dart:developer' as developer;
import 'package:firstflutterapp/components/form/custom_form_field.dart';
import 'package:firstflutterapp/components/form/loading_button.dart';
import 'package:firstflutterapp/config/router.dart';
import 'package:firstflutterapp/notifiers/userNotififers.dart';
import 'package:firstflutterapp/screens/login/login_service.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:firstflutterapp/services/toast_service.dart';
import 'package:firstflutterapp/services/validators_service.dart';
import 'package:firstflutterapp/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

class LoginView extends StatefulWidget {
  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  final LoginService _loginService = LoginService();
  bool _isSubmitted = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    setState(() {
      _isSubmitted = true;
    });

    final userNotifier = context.read<UserNotifier>();
    final email = _emailController.text;
    final password = _passwordController.text;

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitted = false;
      });
      return;
    }

    try {
      final response = await _apiService.request(
        method: 'POST',
        endpoint: '/login',
        body: {'email': email, 'password': password},
        withAuth: false,
      );

      if (response.success) {
        final token = response.data['token'];
        developer.log('Mobile login - Token reçu: $token');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        userNotifier.onAuthenticationSuccess(response.data);

        if (!mounted) return;

        if (await userNotifier.isAdmin()) {
          context.go(adminDashboard);
        } else {
          context.go(homeRoute);
        }
      } else {
        ToastService.showToast(
          _loginService.getMessageError(response.error),
          ToastificationType.error,
        );
        if (response.error == "user don't valid email") {
          context.push(confirmEmailRoute);
        }
      }
    } catch (e) {
      ToastService.showToast(
        'Erreur lors de la connexion',
        ToastificationType.error,
      );
      developer.log('Erreur login: $e');
    } finally {
      setState(() {
        _isSubmitted = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double formWidth =
                constraints.maxWidth > 800
                    ? constraints.maxWidth / 3
                    : double.infinity;

            return Center(
              child: Container(
                width: formWidth,
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 200,
                      height: 200,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Ravis de vous revoir sur",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Text(
                      "OnlyFlick",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomTextField(
                            controller: _emailController,
                            label: 'Email',
                            validators: [RequiredValidator(), EmailValidator()],
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _passwordController,
                            label: 'Mot de passe',
                            obscure: true,
                            showText: false,
                            validators: [RequiredValidator()],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push(resetPasswordRoute),
                              child: Text(
                                'Mot de passe perdu ?',
                                style: TextStyle(
                                  color: AppTheme.darkColor,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text(
                                "Pas de compte ?",
                                style: TextStyle(fontSize: 14),
                              ),
                              InkWell(
                                onTap: () => context.push(registerRoute),
                                child: Text(
                                  "(S'inscrire)",
                                  style: TextStyle(
                                    color: AppTheme.darkColor,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: LoadingButton(
                                label: 'Se connecter',
                                isSubmitted: _isSubmitted,
                                onPressed: _onSubmit,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
