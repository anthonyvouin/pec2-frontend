import 'package:firstflutterapp/services/api_service.dart';

class UserSettings {
  final bool commentEnabled;
  final bool messageEnabled;
  final bool subscriptionEnabled;
  final String? id;
  final String? userId;

  UserSettings({
    required this.commentEnabled, 
    required this.messageEnabled,
    required this.subscriptionEnabled,
    this.id,
    this.userId
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    print('Parsing UserSettings from json: $json');
    return UserSettings(
      id: json['id'],
      userId: json['userId'],
      commentEnabled: json['commentEnabled'] ?? true,
      messageEnabled: json['messageEnabled'] ?? true,
      subscriptionEnabled: json['subscriptionEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'commentEnabled': commentEnabled,
      'messageEnabled': messageEnabled,
      'subscriptionEnabled': subscriptionEnabled,
    };
  }
}

class UserSettingsService {
  final ApiService _apiService = ApiService();
  static const String _endpoint = '/user-settings';  Future<ApiResponse<UserSettings>> getUserSettings() async {
    try {
      final response = await _apiService.request(
        method: 'GET',
        endpoint: _endpoint,
        withAuth: true,
      );

      // Si la réponse est déjà une ApiResponse
      if (response is ApiResponse) {
        if (response.success && response.data != null) {
          try {
            final userSettings = UserSettings.fromJson(response.data);
            return ApiResponse<UserSettings>(
              statusCode: response.statusCode,
              success: true,
              data: userSettings,
            );
          } catch (e) {
            print('Error parsing UserSettings from ApiResponse.data: $e');
            return ApiResponse<UserSettings>(
              statusCode: 500,
              success: false,
              error: 'Erreur de traitement des données: $e',
            );
          }
        } else {
          return ApiResponse<UserSettings>(
            statusCode: response.statusCode,
            success: false,
            error: response.error ?? 'Une erreur est survenue',
          );
        }
      }
      
      // Si la réponse est une Map (format JSON brut)
      if (response is Map<String, dynamic>) {
        try {
          final userSettings = UserSettings.fromJson(response);
          return ApiResponse<UserSettings>(
            statusCode: 200,
            success: true,
            data: userSettings,
          );
        } catch (e) {
          print('Error parsing UserSettings from Map: $e');
          return ApiResponse<UserSettings>(
            statusCode: 500,
            success: false,
            error: 'Erreur de traitement des données: $e',
          );
        }
      }

      // Format inconnu
      print('Unexpected response type: ${response.runtimeType}');
      return ApiResponse<UserSettings>(
        statusCode: 500,
        success: false,
        error: 'Format de réponse non reconnu',
      );
    } catch (e) {
      print('Error in getUserSettings: $e');
      return ApiResponse<UserSettings>(
        statusCode: 500,
        success: false,
        error: 'Erreur lors de la récupération des paramètres: $e',
      );
    }
  }  Future<ApiResponse<UserSettings>> updateUserSettings({
    bool? commentEnabled,
    bool? messageEnabled,
    bool? subscriptionEnabled,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      
      if (commentEnabled != null) {
        updates['commentEnabled'] = commentEnabled;
      }
      
      if (messageEnabled != null) {
        updates['messageEnabled'] = messageEnabled;
      }
      
      if (subscriptionEnabled != null) {
        updates['subscriptionEnabled'] = subscriptionEnabled;
      }

      final response = await _apiService.request(
        method: 'PUT',
        endpoint: _endpoint,
        body: updates,
        withAuth: true,
      );

      // Si la réponse est déjà une ApiResponse
      if (response is ApiResponse) {
        if (response.success && response.data != null) {
          try {
            final userSettings = UserSettings.fromJson(response.data);
            return ApiResponse<UserSettings>(
              statusCode: response.statusCode,
              success: true,
              data: userSettings,
            );
          } catch (e) {
            print('Error parsing UserSettings from ApiResponse.data: $e');
            return ApiResponse<UserSettings>(
              statusCode: 500,
              success: false,
              error: 'Erreur de traitement des données: $e',
            );
          }
        } else {
          return ApiResponse<UserSettings>(
            statusCode: response.statusCode,
            success: false,
            error: response.error ?? 'Une erreur est survenue lors de la mise à jour',
          );
        }
      }
      
      // Si la réponse est une Map (format JSON brut)
      if (response is Map<String, dynamic>) {
        try {
          final userSettings = UserSettings.fromJson(response);
          return ApiResponse<UserSettings>(
            statusCode: 200,
            success: true,
            data: userSettings,
          );
        } catch (e) {
          print('Error parsing UserSettings from Map: $e');
          return ApiResponse<UserSettings>(
            statusCode: 500,
            success: false,
            error: 'Erreur de traitement des données: $e',
          );
        }
      }

      // Format inconnu
      print('Unexpected response type: ${response.runtimeType}');
      return ApiResponse<UserSettings>(
        statusCode: 500,
        success: false,
        error: 'Format de réponse non reconnu',
      );
    } catch (e) {
      print('Error in updateUserSettings: $e');
      return ApiResponse<UserSettings>(
        statusCode: 500,
        success: false,
        error: 'Erreur lors de la mise à jour des paramètres: $e',
      );
    }
  }
}
