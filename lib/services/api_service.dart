import 'dart:convert';
import 'dart:io' show File;
import 'package:firstflutterapp/services/toast_service.dart';
import 'package:firstflutterapp/utils/platform_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';

class ApiResponse<T> {
  final T? data;
  final String? error;
  final int statusCode;
  final bool success;

  ApiResponse({
    required this.statusCode,
    required this.success,
    this.data,
    this.error,
  });
}

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal();

  String get baseUrl => PlatformUtils.getApiBaseUrl();

  Future<Map<String, String>> _getHeaders({bool withAuth = true}) async {
    Map<String, String> headers = {'Content-Type': 'application/json'};

    if (withAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> request({
    required String method,
    required String endpoint,
    dynamic body,
    bool withAuth = true,
    Map<String, String>? queryParams,
  }) async {
    final headers = await _getHeaders(withAuth: withAuth);

    var uri = Uri.parse('$baseUrl$endpoint');
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }

    String? data;

    if (body != null) {
      data = jsonEncode(body);
    }
    http.Response response;

    if (kDebugMode) {
      print('$method : $uri');
      // print(data);
    }

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(uri, headers: headers, body: data);
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: data);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        case 'PATCH':
          response = await http.patch(uri, headers: headers, body: data);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      if (kDebugMode) {
        print('Response: ${response.statusCode}');
        print('Data: ${response.body}');
      }

      return _handleResponse(response);
    } catch (e) {
      print('Error: $e');
      ToastService.showToast(
        'Erreur de connexion. Veuillez vérifier votre connexion Internet.',
        ToastificationType.error,
      );
      throw Exception('Network error: $e');
    }
  }

  Future<ApiResponse> uploadMultipart({
    required String endpoint,
    required Map<String, String> fields,
    required Object file,
    bool withAuth = true,
    required String method,
  }) async {
    late http.MultipartFile multipartFile;
    var uri = Uri.parse('$baseUrl$endpoint');

    if (kDebugMode) {
      print('Uploading multipart: $method $uri');
      print('Fields: $fields');
      if (file is File) {
        print('File path: ${file.path}');
      } else if (file is XFile) {
        print('XFile path: ${file.path}');
      } else if (file is http.MultipartFile) {
        print('Multipart file: ${file.filename}');
      }
    }

    print('Base URL: $baseUrl');
    var request = http.MultipartRequest(method.toUpperCase(), uri);
    print('Request method: ${request.method}');

    request.fields.addAll(fields);
    print('Request fields: ${request.fields}');
    if (file is http.MultipartFile) {
      multipartFile = file;
    } else if (file is XFile) {
      // Gestion des XFile (pour la compatibilité web et mobile)
      if (kIsWeb) {
        if (kDebugMode) {
          print('Detected web platform with XFile, reading as bytes');
        }

        List<int> bytes;
        String fileName = file.name;

        try {
          bytes = await file.readAsBytes();
          if (kDebugMode) {
            print('Successfully read ${bytes.length} bytes from XFile');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error reading XFile bytes: $e');
          }
          throw Exception('Failed to read XFile: $e');
        }

        multipartFile = http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        );
      } else {
        multipartFile = await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: file.name,
        );
      }
    } else if (file is File) {
      if (kIsWeb) {
        if (kDebugMode) {
          print('Detected web platform, reading file as bytes');
        }

        List<int> bytes;
        String fileName = 'web_file.jpg'; // Default avec extension

        try {
          if (kDebugMode) {
            print('Attempting to read web file: ${file.path}');
          }

          // Gestion spécifique pour les blob URLs
          if (file.path.startsWith('blob:')) {
            if (kDebugMode) {
              print('Detected blob URL, using specialized reading');
            }

            // Pour les blob URLs, on doit utiliser une approche différente
            try {
              bytes = await file.readAsBytes();
            } catch (e) {
              if (kDebugMode) {
                print('Blob URL reading failed, trying alternative: $e');
              }
              // Fallback
              bytes = await file.readAsBytes();
            }
          } else {
            // Fichier web standard (pas blob URL)
            bytes = await file.readAsBytes();
          }

          if (kDebugMode) {
            print('Successfully read ${bytes.length} bytes');
            print('Using filename: $fileName');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error reading web file bytes: $e');
            print('Error type: ${e.runtimeType}');
          }
          throw Exception('Failed to read web file: $e');
        }

        multipartFile = http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        );

        if (kDebugMode) {
          print('Created multipart file for web with name: $fileName');
        }
      } else {
        final fileName = file.path.split('/').last;
        multipartFile = await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: fileName,
        );
      }
    } else {
      throw ArgumentError('file must be a File, XFile or http.MultipartFile');
    }

    request.files.add(multipartFile);

    if (withAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) {
        print('Upload response status: ${response.statusCode}');
        print('Upload response body: ${response.body}');
      }

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('Upload error: $e');
      }
      throw Exception('Erreur d\'envoi multipart : $e');
    }
  }

  ApiResponse _handleResponse(http.Response response) {
    final decoded = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse(
        statusCode: response.statusCode,
        success: true,
        data: decoded,
      );
    } else {
      final message =
          decoded?['error'] ?? decoded?['message'] ?? response.reasonPhrase;
      return ApiResponse(
        statusCode: response.statusCode,
        success: false,
        error: message,
      );
    }
  }
}
