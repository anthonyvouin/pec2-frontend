import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firstflutterapp/interfaces/file_picker_web.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class FileService {
  static String _getMimeType(PlatformFile pickedFile) {
    switch (pickedFile.extension?.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  static Future<FilePickerWeb?> getFilePicker() async {
    final FilePickerResult? resultPicker = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (resultPicker != null && resultPicker.files.isNotEmpty) {
      final PlatformFile pickedFile = resultPicker.files.single;

      final Uint8List fileBytes = pickedFile.bytes!;
      final base64Image = base64Encode(fileBytes);

      final String mimeType = _getMimeType(pickedFile);
      return FilePickerWeb(
        name: pickedFile.name,
        file: "data:$mimeType;base64,$base64Image",
      );
    }
    return null;
  }

  static http.MultipartFile getMultipartFileWeb(String selectedFile) {
    final imageData = selectedFile.split(',')[1];
    final imageBytes = base64Decode(imageData);
    final headerSplit = selectedFile.split(',');
    final mime = headerSplit[0].split(':')[1].split(';')[0];
    final ext = mime.split('/')[1];
    final mimeType = lookupMimeType('', headerBytes: imageBytes);
    final mediaType =
    mimeType != null
        ? MediaType.parse(mimeType)
        : MediaType('application', 'octet-stream');
    return http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: 'profile.$ext',
      contentType: mediaType,
    );
  }

  static Future<http.MultipartFile> getMultipartFileMobile(String selectedFile) async {
    String? mimeType = lookupMimeType(selectedFile);
    return await http.MultipartFile.fromPath(
      'file',
      selectedFile,
      contentType: mimeType != null ? MediaType.parse(mimeType) : null,
    );
  }
}
