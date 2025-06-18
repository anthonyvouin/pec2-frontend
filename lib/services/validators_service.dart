abstract class Validator {
  String? validate(String? value);
}

class RequiredValidator implements Validator {
  @override
  String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vous devez remplir ce champs';
    }

    return null;
  }
}

class EmailValidator implements Validator {
  @override
  String? validate(String? value) {
    if (value == null) {
      return 'Email non valide';
    }
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email non valide';
    }
    return null;
  }
}

class PasswordValidator implements Validator {
  @override
  String? validate(String? value) {
    if (value == null) {
      return 'Vous devez remplir ce champs';
    }
    final hasUpper = value.contains(RegExp(r'[A-Z]'));
    final hasDigit = value.contains(RegExp(r'[0-9]'));
    final hasMinimumString = value.length >= 6;
    final okPassword = hasUpper && hasDigit && hasMinimumString;
    if (!okPassword) {
      return "format incorrect";
    }
    return null;
  }
}

class SamePasswordValidator implements Validator {
  final String Function() getPassword;

  SamePasswordValidator(this.getPassword);

  @override
  String? validate(String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Vous devez remplir ce champs';
    }

    if (confirmPassword != getPassword()) {
      return 'Les mots de passe ne sont pas identiques';
    }
    return null;
  }
}

class MinimumValidator implements Validator {
  final int minLength;
  final int maxLength;
  final String Function()? formValue;

  MinimumValidator({
    this.formValue,
    required this.minLength,
    required this.maxLength,
  });

  @override
  String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vous devez remplir ce champs';
    }

    if (value.length < minLength || value.length > maxLength) {
      return 'Format incorrect';
    }
    return null;
  }
}

class IsNumberValidator implements Validator {
  @override
  String? validate(String? value) {
    if (value == null) {
      return 'Champs non complété';
    }

    print(value);

    if (num.tryParse(value) == null) {
      return 'Ce champ doit être un nombre';
    }

    return null;
  }
}
