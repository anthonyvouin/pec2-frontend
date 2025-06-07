import 'package:firstflutterapp/components/form/custom_form_field.dart';
import 'package:firstflutterapp/components/form/loading_button.dart';
import 'package:firstflutterapp/config/router.dart';
import 'package:firstflutterapp/screens/update_password/update_password_service.dart';
import 'package:firstflutterapp/services/toast_service.dart';
import 'package:firstflutterapp/services/validators_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';
import '../../services/api_service.dart';

class UpdatePasswordView extends StatefulWidget {
  const UpdatePasswordView({Key? key}) : super(key: key);

  @override
  _UpdatePasswordViewState createState() => _UpdatePasswordViewState();
}

class _UpdatePasswordViewState extends State<UpdatePasswordView> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitted = false;

  final ApiService _apiService = ApiService();
  final ToastService _toastService = ToastService();
  final UpdatePasswordService _updatePasswordService = UpdatePasswordService();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    setState(() {
      _isSubmitted = true;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitted = false;
      });
      return;
    }

    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;


    try {
      final response = await _apiService.request(
        method: 'PUT',
        endpoint: '/users/password',
        body: {'oldPassword': oldPassword, 'newPassword': newPassword},
        withAuth: true,
      );
      if (response.success) {
        if (!mounted) return;
        context.go(profileRoute);
        ToastService.showToast(
            'Nouveau mot de passe enregistré', ToastificationType.success);
      } else {
        ToastService.showToast(
          _updatePasswordService.getMessageError(response.error),
          ToastificationType.error,
        );
      }
    } catch (e) {
      ToastService.showToast(
        _updatePasswordService.getMessageError("Erreur lors de l'enregistrement du nouveau mot de passe"),
        ToastificationType.error,
      );
    }finally {
      setState(() {
        _isSubmitted = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mettre à jour le mot de passe")),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double formWidth =
            constraints.maxWidth > 800
                ? constraints.maxWidth / 3
                : double.infinity;
            return SingleChildScrollView(
              child: Center(
                child: Container(
                  width: formWidth,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 32),
                      const Text(
                        'Modification du mot de passe',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            CustomTextField(
                              controller: _oldPasswordController,
                              label: "Ancien mot de passe",
                              obscure: true,
                              validators: [
                                RequiredValidator(),
                              ],
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _newPasswordController,
                              label: "Nouveau mot de passe",
                              obscure: true,
                              validators: [
                                RequiredValidator(),
                                PasswordValidator(),
                              ],
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _confirmPasswordController,
                              label: "Nouveau mot de passe",
                              obscure: true,
                              validators: [
                                RequiredValidator(),
                                SamePasswordValidator(
                                      () => _newPasswordController.text,
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Center(
                              child: SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: LoadingButton(
                                  label: 'Modifier le mot de passe',
                                  isSubmitted: _isSubmitted,
                                  onPressed: _updatePassword,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
