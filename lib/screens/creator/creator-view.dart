import 'package:firstflutterapp/components/form/loading_button.dart';
import 'package:firstflutterapp/interfaces/creator.dart';
import 'package:firstflutterapp/interfaces/siret_response.dart';
import 'package:firstflutterapp/interfaces/siret_valid_result.dart';
import 'package:firstflutterapp/screens/creator/creator-service.dart';
import 'package:firstflutterapp/services/file_picker_service.dart';
import 'package:firstflutterapp/services/toast_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';
import '../../components/form/custom_form_field.dart';
import '../../interfaces/file_picker_web.dart';
import '../../services/api_service.dart';
import '../../services/validators_service.dart';
import '../../utils/platform_utils.dart';

class CreatorView extends StatefulWidget {
  @override
  _CreatorViewState createState() => _CreatorViewState();
}

class _CreatorViewState extends State<CreatorView> {
  final CreatorService _creatorService = CreatorService();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  TextEditingController _siretController = TextEditingController();
  TextEditingController _companyNameController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _cityController = TextEditingController();
  TextEditingController _zipCodeController = TextEditingController();
  TextEditingController _ibanController = TextEditingController();
  TextEditingController _bicController = TextEditingController();

  SiretResponse? responseSiret;

  int _step = 1;
  String _selectedFile = "";
  String _selectedFileName = "";
  bool _isSubmitted = false;
  bool _isAlreadyCreator = false;
  Creator? _creator;

  @override
  void initState() {
    super.initState();
    _getInscription();
  }

  _populateForm() {
    if (_creator != null) {
      _siretController = TextEditingController(
        text: _creator?.siretNumber ?? "",
      );
      _companyNameController = TextEditingController(
        text: _creator?.companyName ?? "",
      );
      _addressController = TextEditingController(
        text: _creator?.streetAddress ?? "",
      );
      _cityController = TextEditingController(text: _creator?.city ?? "");
      _zipCodeController = TextEditingController(
        text: _creator?.postalCode ?? "",
      );
      _ibanController = TextEditingController(text: _creator?.iban ?? "");
      _bicController = TextEditingController(text: _creator?.bic ?? "");
    }
  }

  @override
  void dispose() {
    _siretController.dispose();
    _companyNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    _ibanController.dispose();
    _bicController.dispose();
    super.dispose();
  }

  Future<void> _getInscription() async {
    try {
      final response = await _apiService.request(
        method: 'GET',
        endpoint: '/content-creators',
        withAuth: true,
      );
      if (response.statusCode == 200) {
        setState(() {
          _isAlreadyCreator = response.data != null;
          if (response.data != null) {
            _creator = Creator.fromJson(response.data);
            _populateForm();
          }
        });
      }
    } catch (e) {
      ToastService.showToast(
        "Impossible de récupérer l'inscription",
        ToastificationType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Demande créateur")),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double formWidth =
                constraints.maxWidth > 800
                    ? constraints.maxWidth / 2
                    : double.infinity;
            return Center(
              child: Container(
                width: formWidth,
                padding: const EdgeInsets.all(24.0),
                child: Column(children: [_buildCreatorContent()]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCreatorContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_step == 1) _buildStep1(),
          if (_step == 2) _buildStep2(),
          if (_step == 3) _buildStep3(),
          const SizedBox(height: 16),
          if (_step == 1 || _step == 2)
            SizedBox(
              width: double.infinity,
              child: LoadingButton(
                label: _step == 1 ? "Suivant" : "Valider",
                isSubmitted: _isSubmitted,
                onPressed: () async {
                  if (_step == 1) {
                    if (_formKey1.currentState!.validate()) {
                      final SiretValidationResult isValidSiret =
                          await _creatorService.siretIsValid(
                            _siretController.text,
                          );
                      if (isValidSiret.isValid && isValidSiret.data != null) {
                        final data = isValidSiret.data!;
                        setState(() {
                          if(!_isAlreadyCreator){
                            _companyNameController.text = data.company_name ?? '';
                            _addressController.text = data.address ?? '';
                            _cityController.text = data.city ?? '';
                            _zipCodeController.text = data.postal_code ?? '';
                          }

                          _step = 2;
                        });
                      } else {
                        ToastService.showToast(
                          'Siret invalide',
                          ToastificationType.error,
                        );
                      }
                    }
                  } else {
                    _submitForm();
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Information entreprise',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              "Étape  ${_step}/2",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),

        SizedBox(height: 20),
        Form(
          key: _formKey1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _siretController,
                label: 'Siret',
                validators: [
                  RequiredValidator(),
                  MinimumValidator(
                    minLength: 14,
                    maxLength: 14,
                    formValue: () => _siretController.text,
                  ),
                  IsNumberValidator(),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Votre demande a bien été transmise",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20),
        ),
        SizedBox(height: 24),
        Image.asset('assets/images/creator.png', width: 300, height: 300),
        SizedBox(height: 24),
        Text(
          "Un administrateur doit vérifier votre demande",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        Text(
          "Vous recevrez la réponse prochainement",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Information entreprise',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              "Étape  ${_step}/2",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
          ],
        ),
        Form(
          key: _formKey2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),
              CustomTextField(
                controller: _companyNameController,
                label: 'Nom de la société',
                validators: [RequiredValidator()],
              ),
              SizedBox(height: 20),
              CustomTextField(
                controller: _addressController,
                label: 'Adresse',
                validators: [RequiredValidator()],
              ),
              SizedBox(height: 20),
              CustomTextField(
                controller: _cityController,
                label: 'Ville',
                validators: [RequiredValidator()],
              ),
              SizedBox(height: 20),
              CustomTextField(
                controller: _zipCodeController,
                label: 'Code postal',
                validators: [RequiredValidator()],
              ),
              SizedBox(height: 20),
              CustomTextField(
                controller: _ibanController,
                label: 'Iban',
                validators: [RequiredValidator()],
              ),
              SizedBox(height: 20),
              CustomTextField(
                controller: _bicController,
                label: 'Bic',
                validators: [RequiredValidator()],
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedFileName == "" && !_isAlreadyCreator)
              Row(
                children: [
                  FilledButton(
                    onPressed: () async {
                      if (PlatformUtils.isWebPlatform()) {
                        FilePickerWeb? filePickerWeb =
                            await FileService.getFilePicker();

                        setState(() {
                          if (filePickerWeb != null) {
                            _selectedFileName = filePickerWeb.name;
                            _selectedFile = filePickerWeb.file;
                          }
                        });
                      } else {
                        final XFile? pickedFile = await _picker.pickMedia();

                        if (pickedFile != null) {
                          setState(() {
                            _selectedFile = pickedFile.path;
                            final String fileName = pickedFile.name;
                            _selectedFileName =
                                fileName.length > 15
                                    ? fileName.substring(0, 15)
                                    : fileName;
                          });
                        }
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Ajouter le KBIS'),
                        SizedBox(width: 8),
                        Icon(Icons.upload_file),
                      ],
                    ),
                  ),
                ],
              ),

            if (_selectedFileName != "" && !_isAlreadyCreator)
              Row(
                children: [
                  Text('Kbis : $_selectedFileName'),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedFileName = "";
                        _selectedFile = "";
                      });
                    },
                    icon: const Icon(Icons.delete),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _create() async {
    if (_selectedFile != "") {
      http.MultipartFile file;
      if (PlatformUtils.isWebPlatform()) {
        file = FileService.getMultipartFileWeb(_selectedFile);
      } else {
        file = await FileService.getMultipartFileMobile(_selectedFile);
      }

      final ApiResponse response = await _apiService.uploadMultipart(
        endpoint: '/content-creators',
        fields: {
          "siretNumber": _siretController.text,
          "companyName": _companyNameController.text,
          "streetAddress": _addressController.text,
          "postalCode": _zipCodeController.text,
          "city": _cityController.text,
          "country": "France",
          "companyType": "Micro",
          "iban": _ibanController.text,
          "bic": _bicController.text,
          "vatNumber": "FR12345678901",
        },
        file: file,
        method: 'post',
      );

      if (response.success) {
        setState(() {
          _step = 3;
        });
      } else {
        ToastService.showToast(
          "Une erreur s'est produite",
          ToastificationType.error,
        );
      }
    } else {
      ToastService.showToast(
        "Vous devez selectionner un KBIS",
        ToastificationType.error,
      );
    }
  }

  Future<void> _update() async {

      final ApiResponse response = await _apiService.request(
        endpoint: '/content-creators',
        body: {
          "siretNumber": _siretController.text,
          "companyName": _companyNameController.text,
          "streetAddress": _addressController.text,
          "postalCode": _zipCodeController.text,
          "city": _cityController.text,
          "country": "France",
          "companyType": "Micro",
          "iban": _ibanController.text,
          "bic": _bicController.text,
          "vatNumber": "FR12345678901",
        },
        method: 'put',
      );

      if (response.success) {
        setState(() {
          _step = 3;
        });
      } else {
        ToastService.showToast(
          "Une erreur s'est produite",
          ToastificationType.error,
        );
      }
  }

  Future<void> _submitForm() async {
    setState(() {
      _isSubmitted = true;
    });

    if (_formKey2.currentState!.validate()) {
      if(_isAlreadyCreator){
        _update();

      }else{
        _create();
      }
    }

    setState(() {
      _isSubmitted = false;
    });
  }
}
