import 'dart:convert';

import 'package:firstflutterapp/services/api_service.dart';
import 'package:http/http.dart' as http;

import '../../interfaces/siret_response.dart';
import '../../interfaces/siret_valid_result.dart';

class CreatorService {
  final ApiService _apiService = ApiService();

  Future<List<String>> loadCountries() async {
    final response = await http.get(
      Uri.parse('https://restcountries.com/v3.1/all'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      List<String> countryNames =
          data.map((country) => country['name']['common'] as String).toList();
      if (countryNames.isNotEmpty) {
        countryNames.sort();
      }
      return countryNames;
    } else {
      return [];
    }
  }

  Future<SiretValidationResult> siretIsValid(String siret) async {
    final ApiResponse response = await _apiService.request(
      method: 'Get',
      endpoint: '/insee/$siret',
    );
    if (response.statusCode == 200 && response.data != null) {
      final siretResponse = SiretResponse.fromJson(response.data);
      return SiretValidationResult(
        isValid: true,
        data: siretResponse,
      );
    } else {
      return SiretValidationResult(
        isValid: false,
        data: null,
      );
    }
  }
}
