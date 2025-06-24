
import 'package:firstflutterapp/utils/check-form-data.dart';

class UpdateProfileService {
  final CheckFormData _checkFormData = CheckFormData();

  String getSexe(String? selectedSexe) {
    if (selectedSexe != null) {
      switch (selectedSexe) {
        case "WOMAN":
          return "Femme";
        case "MAN":
          return "Homme";
        case "OTHER":
          return "Autre";
        default:
          return "";
      }
    } else {
      return "";
    }
  }

  bool checkFormIsValid(
    DateTime? birthDay,
    String? sexe,
  ) {
    final bool validBirthDay = _checkFormData.dateIsNotEmpty(birthDay);
    final bool validSexe = _checkFormData.inputIsNotEmptyOrNull(sexe);
    return validBirthDay && validSexe;
  }

  String getErrorMessage(int status){
    switch(status){
      case 401:
        return "Vous n'êtes pas connecté";
      case 400:
        return "Données invalides";
      default:
        return "Impossible de faire les modifications";
    }
  }
}
