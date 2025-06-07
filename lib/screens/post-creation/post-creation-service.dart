import 'dart:convert';
import 'dart:io' show File;
import 'package:firstflutterapp/utils/platform_utils.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:firstflutterapp/interfaces/category.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

class PostCreationService {
  final ApiService _apiService = ApiService();

  Future<List<Category>> loadCategories() async {
    final response = await _apiService.request(
      method: 'get',
      endpoint: '/categories',
      withAuth: true,
    );

    if (response.success) {
      return (response.data as List)
          .map((item) => Category.fromJson(item))
          .toList();
    }

    throw Exception('Échec du chargement des catégories');
  }

  // Valider les données du post
  String? validatePostData({
    required List<Category> selectedCategories,
    required String name,
    required String description,
  }) {
    if (selectedCategories.isEmpty) {
      return 'Veuillez sélectionner au moins une catégorie';
    }

    if (name.trim().isEmpty) {
      return 'Veuillez ajouter un nom';
    }

    if (description.trim().isEmpty) {
      return 'Veuillez ajouter une description';
    }

    return null;
  }

  // Publier un nouveau post
  Future<void> publishPost({
    required String imageUrl, // Changé de File à XFile
    required String name,
    required String description,
    required List<Category> selectedCategories,
    required bool isFree,
  }) async {
    try {
      var file;
      if (PlatformUtils.isWebPlatform()) {
        print('Web platform detected, processing image URL: $imageUrl');
        final imageData = imageUrl.split(',')[1];
        print('Image data length: ${imageData.length}');
        final imageBytes = base64Decode(imageData);
        final headerSplit = imageUrl.split(',');
        final mime = headerSplit[0].split(':')[1].split(';')[0];
        final ext = mime.split('/')[1];
        final mimeType = lookupMimeType('', headerBytes: imageBytes);
        final mediaType = mimeType != null
                ? MediaType.parse(mimeType)
                : MediaType('application', 'octet-stream');
        
        file = http.MultipartFile.fromBytes(
          'postPicture',
          imageBytes,
          filename: 'profile.$ext',
          contentType: mediaType,
        );

        print('Image URL: $imageUrl');
        print('Image Bytes Length: ${imageBytes.length}');
      } else {
        String? mimeType = lookupMimeType(imageUrl);
        file = await http.MultipartFile.fromPath(
          'postPicture',
          imageUrl,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        );
      }
      List<String> categoryIds =
          selectedCategories.map((category) => category.id).toList();
      await _apiService.uploadMultipart(
        endpoint: '/posts',
        fields: {
          "name": name.trim(),
          "description": description.trim(),
          "categoryIds": categoryIds.toString(),
          "isFree": isFree.toString(),
        },
        file: file,
        method: 'Post',
        withAuth: true,
      );
    } catch (e) {
      throw Exception('Erreur lors de la publication: $e');
    }
  }

  // Méthode pour initialiser la caméra
  Future<List<CameraDescription>> getAvailableCameras() async {
    try {
      return await availableCameras();
    } catch (e) {
      throw Exception('Erreur lors de l\'initialisation de la caméra: $e');
    }
  }

  File convertXFileToFile(XFile xFile) {
    if (foundation.kIsWeb) {
      throw Exception(
        'La conversion de XFile en File n\'est pas supportée sur le web',
      );
    }
    return File(xFile.path);
  }
}
