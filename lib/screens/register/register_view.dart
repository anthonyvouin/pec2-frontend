import 'package:firstflutterapp/components/form/loading_button.dart';
import 'package:firstflutterapp/config/router.dart';
import 'package:firstflutterapp/services/toast_service.dart';
import 'package:firstflutterapp/services/validators_service.dart';
import 'package:firstflutterapp/screens/register/register-service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';
import '../../components/form/custom_form_field.dart';
import '../../components/label-and-input/label-and-input-text.dart';
import '../../services/api_service.dart';

class RegisterView extends StatefulWidget {
  @override
  _RegisterViewState createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  int step = 1;
  final RegisterService _registerService = RegisterService();
  final LabelAndInput _labelAndInput = LabelAndInput();
  final ApiService _apiService = ApiService();

  // Step 1 Controllers
  final _formKey1 = GlobalKey<FormState>();
  final TextEditingController _pseudoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Step 2 Controllers
  final _formKey2 = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  DateTime? birthdayDate;
  String? selectedSexe;
  bool isValidBirthdayDate = true;
  bool isValidSexe = true;
  bool _isSubmitted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Inscription")),
      body: _buildRegisterContent(),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pseudoController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Widget _buildRegisterContent() {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          double formWidth =
              constraints.maxWidth > 800
                  ? constraints.maxWidth / 3
                  : double.infinity;

          return Center(
            child: Container(
              width: formWidth,
              padding: const  EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              "Bienvenue sur \nOnlyFlick",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 30),
                          if (step == 2)
                            GestureDetector(
                              onTap: () => setState(() => step = 1),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.arrow_back,
                                    size: 18,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 4),
                                  Text("Retour"),
                                ],
                              ),
                            ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                step == 1
                                    ? "Informations générales"
                                    : "Informations personnelles",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Étape \n ${step}/2",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          if (step == 1) _buildStep1(),
                          if (step == 2) _buildStep2(),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child:   LoadingButton(
                              label: step == 1 ? "Suivant" : "Créer un compte",
                              isSubmitted: _isSubmitted,
                              onPressed: () {
                                if (step == 1) {
                                  if (_formKey1.currentState!.validate()) {
                                    setState(() {
                                      step = 2;
                                    });
                                  }
                                } else {
                                  _submitForm();
                                }
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            controller: _pseudoController,
            label: 'Pseudo',
            validators: [RequiredValidator()],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _emailController,
            label: 'Email',
            validators: [RequiredValidator(), EmailValidator()],
          ),
          const SizedBox(height: 32),
          Center(child: Container(width: 200, height: 3, color: Colors.grey)),
          SizedBox(height: 32),
          Text(
            'Format de mot de passe :',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(' - 1 majuscule \n - 1 chiffre \n - 6 caractères minimum'),
          const SizedBox(height: 32),
          CustomTextField(
            controller: _passwordController,
            label: 'Mot de passe',
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
            validators: [
              RequiredValidator(),
              SamePasswordValidator(() => _passwordController.text),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            controller: _firstNameController,
            label: 'Prénom',
            validators: [RequiredValidator()],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _lastNameController,
            label: 'Nom de famille',
            validators: [RequiredValidator()],
          ),
          const SizedBox(height: 32),
          _labelAndInput.buildLabelAndCalendar(
            "Date d'anniversaire",
            !isValidBirthdayDate,
            "La date doit être renseignée",
            context,
            setState,
            birthdayDate,
            (newDate) => setState(() => birthdayDate = newDate),
          ),
          _labelAndInput.buildLabelAndRadioList(
            "Sexe",
            !isValidSexe,
            "Cochez une option",
            ["Homme", "Femme", "Autre"],
            selectedSexe,
            (option) => setState(() => selectedSexe = option),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey2.currentState!.validate()) {
      final formIsValid = _registerService.checkStep2IsOk(
        birthdayDate,
        selectedSexe,
      );
      if (formIsValid) {
        setState(() {
          isValidSexe = true;
          isValidBirthdayDate = true;
          _isSubmitted = true;
        });

        final response = await _apiService.request(
          method: 'POST',
          endpoint: '/register',
          body: {
            'email': _emailController.text,
            'password': _passwordController.text,
            "userName": _pseudoController.text,
            "firstName": _firstNameController.text,
            "lastName": _lastNameController.text,
            "birthDayDate": birthdayDate?.toUtc().toIso8601String(),
            "sexe": _registerService.getSexe(selectedSexe),
          },
          withAuth: false,
        );

        if (response.success) {
          if (!mounted) return;
          context.go(registerInfoRoute);
        } else {
          ToastService.showToast(
            _registerService.getMessageError(response.error),
            ToastificationType.error,
          );
        }
        setState(() {
          _isSubmitted = false;
        });
      } else {
        ToastService.showToast(
          "Formulaire non valide",
          ToastificationType.error,
        );
        setState(() {
          isValidBirthdayDate = _registerService.isValidBirthdate(birthdayDate);
          isValidSexe = _registerService.isValidSexe(selectedSexe);
        });
      }
    }
  }
}
