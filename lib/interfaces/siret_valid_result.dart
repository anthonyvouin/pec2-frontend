import 'package:firstflutterapp/interfaces/siret_response.dart';

class SiretValidationResult {
  final bool isValid;
  final SiretResponse? data;

  SiretValidationResult({
    required this.isValid,
    this.data,
  });
}