import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firstflutterapp/components/label-and-input/label-and-input-text.dart';
import 'package:firstflutterapp/config/router.dart';
import 'package:firstflutterapp/interfaces/user.dart';
import 'package:firstflutterapp/utils/check-form-data.dart';
import 'package:firstflutterapp/utils/platform_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firstflutterapp/notifiers/userNotififers.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:firstflutterapp/services/toast_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:toastification/toastification.dart';

import '../../../components/form/custom_form_field.dart';
import '../../../components/form/loading_button.dart';
import '../../../services/validators_service.dart';
import 'update_profil_service.dart';

class UpdateProfile extends StatefulWidget {
  const UpdateProfile({Key? key}) : super(key: key);

  @override
  _UpdateProfileState createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  late TextEditingController _pseudoController;
  late TextEditingController _emailController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _bioController;
  String _avatarUrl = "";
  final LabelAndInput _labelAndInput = LabelAndInput();
  final UpdateProfileService _updateProfileService = UpdateProfileService();
  final CheckFormData _checkFormData = CheckFormData();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  late UserNotifier _userNotifier;
  DateTime? _birthdayDate;
  String? _selectedSexe;
  bool isValidBirthdayDate = true;
  bool isValidSexe = true;
  bool isChangeImage = false;
  late User _user;
  bool _isSubmitted = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _userNotifier = context.read<UserNotifier>();
    _user = _userNotifier.user!;
    _avatarUrl =
        _user.profilePicture.trim() != ""
            ? _userNotifier.user!.profilePicture
            : "";
    _pseudoController = TextEditingController(text: _user.userName);
    _emailController = TextEditingController(text: _user.email);
    _firstNameController = TextEditingController(text: _user.firstName);
    _lastNameController = TextEditingController(text: _user.lastName);
    _bioController = TextEditingController(text: _user.bio ?? "");
    setState(() {
      _birthdayDate = _user.birthDayDate;
      _selectedSexe = _updateProfileService.getSexe(_user.sexe);
    });
  }

  @override
  void dispose() {
    _pseudoController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Modification profil")),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double formWidth =
            constraints.maxWidth > 800 ? constraints.maxWidth / 3 : double.infinity;

            return SingleChildScrollView(
              // Ce gesture permet de scroller peu importe où est la souris
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Center(
                child: Container(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24),
                  width: formWidth,
                  child: _buildUpdateProfileContent(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  ImageProvider getProfileImage() {
    bool avartUrlIsCloudinary = _avatarUrl.contains(
      "https://res.cloudinary.com/",
    );
    if (_avatarUrl.isNotEmpty) {
      if (avartUrlIsCloudinary || PlatformUtils.isWebPlatform()) {
        return NetworkImage(_avatarUrl);
      } else {
        return FileImage(File(_avatarUrl)) as ImageProvider;
      }
    } else {
      return AssetImage('assets/images/dog.webp');
    }
  }

  Widget _buildUpdateProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () async {
              if (PlatformUtils.isWebPlatform()) {
                final FilePickerResult? resultPicker = await FilePicker.platform
                    .pickFiles(type: FileType.image);

                if (resultPicker != null && resultPicker.files.isNotEmpty) {
                  final PlatformFile pickedFile = resultPicker.files.single;

                  final Uint8List fileBytes = pickedFile.bytes!;
                  final base64Image = base64Encode(fileBytes);

                  setState(() {
                    _avatarUrl =
                        "data:image/${pickedFile.extension};base64,$base64Image"; // Encodage en base64
                    isChangeImage = true;
                  });
                }
              } else {
                XFile? pickedFile = await _picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (pickedFile != null) {
                  setState(() {
                    _avatarUrl = pickedFile.path;
                    isChangeImage = true;
                  });
                }
              }
            },
            child: CircleAvatar(
              radius: 40,
              backgroundImage: getProfileImage(),
              backgroundColor: const Color(0xFFE4DAFF),
            ),
          ),
          const SizedBox(height: 32),
          Form(
            key: _formKey,
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
                  controller: _lastNameController,
                  label: 'Nom de famille',
                  validators: [RequiredValidator()],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _firstNameController,
                  label: 'Prénom',
                  validators: [RequiredValidator()],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _bioController,
                  label: 'Bio',
                  maxLine: 5,
                  validators: [RequiredValidator()],
                ),
                const SizedBox(height: 16),
                _labelAndInput.buildLabelAndCalendar(
                  "Date d'anniversaire",
                  !isValidBirthdayDate,
                  "La date doit être renseignée",
                  context,
                  setState,
                  _birthdayDate,
                  (newDate) => setState(() => _birthdayDate = newDate),
                ),
                _labelAndInput.buildLabelAndRadioList(
                  "Sexe",
                  !isValidSexe,
                  "Cochez une option",
                  ["Homme", "Femme", "Autre"],
                  _selectedSexe,
                  (option) => setState(() => _selectedSexe = option),
                ),
                const SizedBox(height: 24),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: LoadingButton(
                      label: 'Enregistrer',
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
    );
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
    final isValidValid = _updateProfileService.checkFormIsValid(
      _birthdayDate,
      _selectedSexe,
    );

    if (isValidValid && _formKey.currentState!.validate()) {
      _user.userName = _pseudoController.text;
      _user.firstName = _firstNameController.text;
      _user.lastName = _lastNameController.text;
      _user.bio = _bioController.text;

      if (_birthdayDate != null) {
        _user.birthDayDate = _birthdayDate ?? DateTime(2023, 12, 4);
      }
      _user.sexe = _selectedSexe ?? "MAN";

      late final ApiResponse response;
      try {
        var file;
        if (isChangeImage) {
          if (PlatformUtils.isWebPlatform()) {
            final imageData = _avatarUrl.split(',')[1];
            final imageBytes = base64Decode(imageData);
            final headerSplit = _avatarUrl.split(',');
            final mime = headerSplit[0].split(':')[1].split(';')[0];
            final ext = mime.split('/')[1];
            final mimeType = lookupMimeType('', headerBytes: imageBytes);
            final mediaType =
                mimeType != null
                    ? MediaType.parse(mimeType)
                    : MediaType('application', 'octet-stream');
            file = http.MultipartFile.fromBytes(
              'profilePicture',
              imageBytes,
              filename: 'profile.$ext',
              contentType: mediaType,
            );
          } else {
            String? mimeType = lookupMimeType(_avatarUrl);
            file = await http.MultipartFile.fromPath(
              'profilePicture',
              _avatarUrl,
              contentType: mimeType != null ? MediaType.parse(mimeType) : null,
            );
          }

          response = await _apiService.uploadMultipart(
            endpoint: '/users/profile',
            fields: {
              "userName": _pseudoController.text,
              "bio": _bioController.text,
              "firstName": _firstNameController.text,
              "email": _user.email,
              "lastName": _lastNameController.text,
              "birthDayDate": _birthdayDate?.toUtc().toIso8601String() ?? "",
              "sexe": _selectedSexe ?? "",
            },
            file: file,
            method: 'put',
          );
        } else {
          response = await _apiService.request(
            method: 'put',
            endpoint: '/users/profile',
            body: {
              "userName": _pseudoController.text,
              "bio": _bioController.text,
              "firstName": _firstNameController.text,
              "email": _user.email,
              "lastName": _lastNameController.text,
              "birthDayDate": _birthdayDate?.toUtc().toIso8601String(),
              "sexe": _selectedSexe,
            },
            withAuth: true,
          );
        }

        if (response.success) {
          _userNotifier.updateUser(response.data);
          context.pushReplacement(profileRoute);
          ToastService.showToast(
            "Profil mit à jour",
            ToastificationType.success,
          );
        } else {
          String message = _updateProfileService.getErrorMessage(
            response.statusCode,
          );
          ToastService.showToast(
            "Erreur lors de la création \n du compte \n$message",
            ToastificationType.error,
          );
        }
      } catch (e) {
        ToastService.showToast(
          "Erreur lors de la création \n du compte",
          ToastificationType.error,
        );
      }
    } else {
      setState(() {
        isValidBirthdayDate = _checkFormData.dateIsNotEmpty(_birthdayDate);
        isValidSexe = _checkFormData.inputIsNotEmptyOrNull(_selectedSexe);
      });
    }
    ;
  }
}
