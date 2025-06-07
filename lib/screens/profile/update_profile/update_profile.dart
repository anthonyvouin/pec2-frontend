import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firstflutterapp/components/label-and-input/label-and-input-text.dart';
import 'package:firstflutterapp/config/constantes.dart';
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

import 'update_profil_service.dart';

class UpdateProfile extends StatefulWidget {
  const UpdateProfile({Key? key}) : super(key: key);

  @override
  _UpdateProfileState createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  late TextEditingController pseudoController;
  late TextEditingController emailController;
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController bioController;
  String avatarUrl = "";
  final LabelAndInput _labelAndInput = LabelAndInput();
  final UpdateProfileService _updateProfileService = UpdateProfileService();
  final CheckFormData _checkFormData = CheckFormData();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  late UserNotifier userNotifier;
  DateTime? birthdayDate;
  String? selectedSexe;
  bool isValidPseudo = true;
  bool isValidFirstName = true;
  bool isValidLastName = true;
  bool isValidBirthdayDate = true;
  bool isValidSexe = true;
  bool _isLoading = false;
  bool isChangeImage = false;
  late User user;

  @override
  void initState() {
    super.initState();
    userNotifier = context.read<UserNotifier>();
    user = userNotifier.user!;
    avatarUrl =
        user.profilePicture.trim() != ""
            ? userNotifier.user!.profilePicture
            : "";
    pseudoController = TextEditingController(text: user.userName);
    emailController = TextEditingController(text: user.email);
    firstNameController = TextEditingController(text: user.firstName);
    lastNameController = TextEditingController(text: user.lastName);
    bioController = TextEditingController(text: user.bio ?? "");
    setState(() {
      birthdayDate = user.birthDayDate;
      selectedSexe = _updateProfileService.getSexe(user.sexe);
    });
  }

  @override
  void dispose() {
    pseudoController.dispose();
    emailController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Modification profil")),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF6C3FFE)),
              )
              : _buildUpdateProfileContent(),
    );
  }

  Widget _buildUpdateProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Modification image Profile"),
                    content: const Text(""),
                    actions: <Widget>[
                      TextButton(
                        child: const Text("Télécharger une image"),
                        onPressed: () async {
                          Navigator.of(
                            context,
                          ).pop(); // On ferme le Dialog avant

                          if (PlatformUtils.isWebPlatform()) {
                            final FilePickerResult? resultPicker =
                                await FilePicker.platform.pickFiles(
                                  type: FileType.image,
                                );

                            if (resultPicker != null &&
                                resultPicker.files.isNotEmpty) {
                              final PlatformFile pickedFile =
                                  resultPicker.files.single;

                              final Uint8List fileBytes = pickedFile.bytes!;
                              final base64Image = base64Encode(fileBytes);

                              setState(() {
                                avatarUrl = "data:image/${pickedFile.extension};base64,$base64Image"; // Encodage en base64
                                isChangeImage = true;
                              });
                            }
                          } else {
                            XFile? pickedFile = await _picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (pickedFile != null) {
                              setState(() {
                                avatarUrl = pickedFile.path;
                                isChangeImage = true;
                              });
                            }
                          }
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: CircleAvatar(
              radius: 40,              backgroundImage:
                  avatarUrl.isNotEmpty
                      ? PlatformUtils.isWebPlatform()
                          ? NetworkImage(avatarUrl)
                          : FileImage(File(avatarUrl)) as ImageProvider
                      : AssetImage('assets/images/dog.webp'),
              backgroundColor: const Color(0xFFE4DAFF),
            ),
          ),
          _labelAndInput.buildLabelAndInputText(
            "Pseudo",
            pseudoController,
            "Entrez votre pseudo",
            obscureText: false,
            hasError: !isValidPseudo,
            messageError: "*Vous devez rentrer un pseudo",
          ),
          _labelAndInput.buildLabelAndInputText(
            "Nom de famille",
            lastNameController,
            "Entrez votre nom de famille",
            obscureText: false,
            hasError: !isValidLastName,
            messageError: "Le nom est vide",
          ),
          _labelAndInput.buildLabelAndInputText(
            "Prénom",
            firstNameController,
            "Entrez votre prénom",
            obscureText: false,
            hasError: !isValidFirstName,
            messageError: "Le prénom est vide",
          ),
          _labelAndInput.buildLabelAndInputText(
            "Bio",
            bioController,
            "Entrez votre bio",
            obscureText: false,
            maxLine: 5,
          ),
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
          ElevatedButton(
            onPressed: () {
              // Ici, tu peux récupérer les nouvelles valeurs du formulaire
              _submitForm();
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    final isValidValid = _updateProfileService.checkFormIsValid(
      pseudoController.text,
      lastNameController.text,
      firstNameController.text,
      birthdayDate,
      selectedSexe,
    );

    if (isValidValid) {
      user.userName = pseudoController.text;
      user.firstName = firstNameController.text;
      user.lastName = lastNameController.text;
      user.bio = bioController.text;

      if (birthdayDate != null) {
        user.birthDayDate = birthdayDate ?? DateTime(2023, 12, 4);
      }
      user.sexe = selectedSexe ?? "MAN";
      setState(() {
        _isLoading = true;
      });

      late final ApiResponse response;
      try {
        var file;
        if (isChangeImage) {
          if (PlatformUtils.isWebPlatform()) {
            final imageData =
                avatarUrl.split(
                  ',',
                )[1]; // Enlève la partie "data:image/...;base64,"
            final imageBytes = base64Decode(imageData);
            final headerSplit = avatarUrl.split(',');
            final mime =
                headerSplit[0].split(':')[1].split(';')[0]; // e.g. image/png
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
              contentType:
                  mediaType, // Utiliser le mimeType de l'image, adapte-le à ton besoin
            );
          } else {
            String? mimeType = lookupMimeType(avatarUrl);
            file = await http.MultipartFile.fromPath(
              'profilePicture',
              avatarUrl,
              contentType: mimeType != null ? MediaType.parse(mimeType) : null,
            );
          }

          response = await _apiService.uploadMultipart(
            endpoint: '/users/profile',
            fields: {
              "userName": pseudoController.text,
              "bio": bioController.text,
              "firstName": firstNameController.text,
              "email": user.email,
              "lastName": lastNameController.text,
              "birthDayDate": birthdayDate?.toUtc().toIso8601String() ?? "",
              "sexe": selectedSexe ?? "",
            },
            file: file,
            method: 'put',
          );
        } else {
          response = await _apiService.request(
            method: 'put',
            endpoint: '/users/profile',
            body: {
              "userName": pseudoController.text,
              "bio": bioController.text,
              "firstName": firstNameController.text,
              "email": user.email,
              "lastName": lastNameController.text,
              "birthDayDate": birthdayDate?.toUtc().toIso8601String(),
              "sexe": selectedSexe,
            },
            withAuth: true,
          );
        }

        if (response.success) {
          userNotifier.updateUser(response.data);
          context.pushReplacement(profileRoute);
        } else {
          String message = _updateProfileService.getErrorMessage(
            response.statusCode,
          );
          ToastService.showToast(
            "Erreur lors de la création \n du compte \n$message",
            ToastificationType.error
          );
        }
      } catch (e) {
        ToastService.showToast(
          "Erreur lors de la création \n du compte",
            ToastificationType.error
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        isValidPseudo = _checkFormData.inputIsNotEmptyOrNull(
          pseudoController.text,
        );
        isValidFirstName = _checkFormData.inputIsNotEmptyOrNull(
          firstNameController.text,
        );
        isValidLastName = _checkFormData.inputIsNotEmptyOrNull(
          lastNameController.text,
        );
        isValidBirthdayDate = _checkFormData.dateIsNotEmpty(birthdayDate);
        isValidSexe = _checkFormData.inputIsNotEmptyOrNull(selectedSexe);
      });
    }
    ;
  }
}
