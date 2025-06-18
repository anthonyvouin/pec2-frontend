import 'package:firstflutterapp/components/form/custom_form_field.dart';
import 'package:firstflutterapp/config/router.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:firstflutterapp/services/toast_service.dart';
import 'package:firstflutterapp/services/validators_service.dart';
import 'package:firstflutterapp/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

import '../../components/form/loading_button.dart' show LoadingButton;

class ConfirmEmailPage extends StatefulWidget {
  const ConfirmEmailPage({super.key});

  @override
  State<ConfirmEmailPage> createState() => _ConfirmEmailPageState();
}

class _ConfirmEmailPageState extends State<ConfirmEmailPage> {
  final _formKeyCode = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isSubmitted = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Confirmation Email")),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          double formWidth =
          constraints.maxWidth > 800
              ? constraints.maxWidth / 3
              : double.infinity;

          return Center(
            child: Container(
              width: formWidth,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Vous ne retrouvez pas votre mail ?"),
                  Text("Votre code est expiré ?"),
                  const SizedBox(height: 16),
                  Image.asset(
                    'assets/images/panda.png',
                    width: 200,
                    height: 200,
                  ),

                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => {
                      context.push(resendConfirmEmailRoute)
                    },
                    child: Text(
                      "Recevoir un nouveau code de confirmation",
                      style: TextStyle(
                        color: AppTheme.darkColor,
                        decoration: TextDecoration.underline,
                        fontSize: 16
                      ),
                    ),

                  ),
                  const SizedBox(height: 32),
                  Center(child: Container(width: 200, height: 3, color: Colors.grey)),
                  const SizedBox(height: 32),
                  Form(
                    key: _formKeyCode,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomTextField(
                          controller: _codeController,
                          label: 'Code',
                          validators: [
                            RequiredValidator(),
                            MinimumValidator(
                              minLength: 5,
                              maxLength: 5,
                              formValue: () => _codeController.text,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        LoadingButton(
                          label: "Valider",
                          isSubmitted: _isSubmitted,
                          onPressed: _submitForm,
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

  Future<void> _submitForm() async {
    String code = _codeController.text;
    if (_formKeyCode.currentState!.validate()) {
      setState(() {
        _isSubmitted = true;
      });
      final response = await _apiService.request(
        method: 'GET',
        endpoint: '/valid-email/$code',
        withAuth: false,
      );

      if (response.success) {
        if (!mounted) return;
        context.go(loginRoute);
      } else {
        ToastService.showToast(
          "Une erreur s'est produite",
          ToastificationType.error,
        );
      }
    }else{
      ToastService.showToast(
        "Données invalides",
        ToastificationType.error,
      );
    }
    setState(() {
      _isSubmitted = false;
    });
  }
}
