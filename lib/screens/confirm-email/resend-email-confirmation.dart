import 'package:firstflutterapp/components/form/custom_form_field.dart';
import 'package:firstflutterapp/components/form/loading_button.dart';
import 'package:firstflutterapp/config/router.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:firstflutterapp/services/toast_service.dart';
import 'package:firstflutterapp/services/validators_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

class ResendEmailConfirmation extends StatefulWidget {
  const ResendEmailConfirmation({super.key});

  @override
  State<ResendEmailConfirmation> createState() =>
      _ResendEmailConfirmationState();
}

class _ResendEmailConfirmationState extends State<ResendEmailConfirmation> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isSubmitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Renvoyer le mail")),
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: SizedBox(
                        width: 400,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Pas de panique!",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Renseignez votre email \n pour recevoir un nouveau code",
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),

                    Image.asset(
                      'assets/images/sendEmail.png',
                      width: 300,
                      height: 300,
                    ),
                    const SizedBox(height: 32),
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
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitted = true;
      });
      String email = _emailController.text;
      final response = await _apiService.request(
        method: 'GET',
        endpoint: '/resend-valid-email/$email',
        withAuth: false,
      );

      if (response.success) {
        if (!mounted) return;
        context.go(confirmEmailRoute);
      } else {
        ToastService.showToast(
          "Une erreur s'est produite",
          ToastificationType.error,
        );
      }
    } else {
      ToastService.showToast("Données invalides", ToastificationType.error);
    }
    setState(() {
      _isSubmitted = false;
    });
  }
}
