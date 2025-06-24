import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../services/api_service.dart';

class CategoryUpdate {
  final BuildContext context;
  final Function onUpdateSuccess;

  CategoryUpdate({
    required this.context,
    required this.onUpdateSuccess,
  });

  void showUpdateDialog(Map<String, dynamic> category) {
    developer.log('showUpdateDialog appelé avec la catégorie: ${category['name']}');
    
    try {
      showDialog(
        context: context,
        builder: (BuildContext context) => _CategoryUpdateDialog(
          category: category,
          onUpdate: (name, imageBytes, mimeType) => 
            _updateCategory(category['id'], name, imageBytes, mimeType),
        ),
      );
      developer.log('Dialog affiché avec succès');
    } catch (e) {
      developer.log('Erreur lors de l\'affichage du dialog: $e');
    }
  }

  Future<void> _updateCategory(
    String categoryId,
    String name,
    Uint8List? imageBytes,
    String? mimeType,
  ) async {
    developer.log('_updateCategory appelé - categoryId: $categoryId, name: $name, image fournie: ${imageBytes != null}');
    
    try {
      if (imageBytes != null && mimeType != null) {
        final fields = {'name': name};
        final file = http.MultipartFile.fromBytes(
          'picture',
          imageBytes,
          filename: 'category.$mimeType',
          contentType: MediaType('image', mimeType),
        );

        developer.log('Envoi d\'une requête avec image');
        final response = await ApiService().uploadMultipart(
          endpoint: '/categories/$categoryId',
          method: 'PUT',
          fields: fields,
          file: file,
          withAuth: true,
        );

        _handleResponse(response);
      } else {
        developer.log('Envoi d\'une requête sans image');
        final response = await ApiService().request(
          method: 'PUT',
          endpoint: '/categories/$categoryId',
          body: {'name': name},
          withAuth: true,
        );

        _handleResponse(response);
      }
    } catch (e) {
      developer.log('Erreur lors de la mise à jour: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleResponse(dynamic response) {
    developer.log('Réponse reçue: ${response.success ? 'succès' : 'échec'}');
    
    if (response.success) {
      onUpdateSuccess();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catégorie mise à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${response.error ?? "Une erreur est survenue"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _CategoryUpdateDialog extends StatefulWidget {
  final Map<String, dynamic> category;
  final Function(String name, Uint8List? imageBytes, String? mimeType) onUpdate;

  const _CategoryUpdateDialog({
    Key? key,
    required this.category,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _CategoryUpdateDialogState createState() => _CategoryUpdateDialogState();
}

class _CategoryUpdateDialogState extends State<_CategoryUpdateDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  Uint8List? _selectedImageBytes;
  String? _selectedImageMimeType;
  String? _currentImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category['name']);
    _currentImageUrl = widget.category['pictureUrl'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      setState(() {
        _selectedImageBytes = result.files.first.bytes;
        _selectedImageMimeType = result.files.first.name.split('.').last;
      });
    }
  }

  bool _validateForm() {
    return _formKey.currentState!.validate();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        "Modifier la catégorie",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: 400, // Largeur fixe pour éviter les problèmes de dimensionnement
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la catégorie',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom de la catégorie est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Image de la catégorie (optionnelle)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _selectedImageBytes != null
                    ? Stack(
                        fit: StackFit.expand, // Assure que le Stack prend tout l'espace disponible
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _selectedImageBytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity, // Assure que l'image prend toute la hauteur
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "Nouvelle image",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : _currentImageUrl != null
                      ? Stack(
                          fit: StackFit.expand, // Assure que le Stack prend tout l'espace disponible
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _currentImageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity, // Assure que l'image prend toute la hauteur
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Colors.red.shade400,
                                    ),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  "Image actuelle",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Cliquez pour ajouter une image",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Choisir une nouvelle image'),
                  ),
                ),
                if (_currentImageUrl != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    "L'image actuelle sera conservée si vous n'en sélectionnez pas une nouvelle.",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () {
                  if (_validateForm()) {
                    setState(() => _isLoading = true);
                    widget.onUpdate(
                      _nameController.text.trim(),
                      _selectedImageBytes,
                      _selectedImageMimeType,
                    );
                    Navigator.of(context).pop();
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
} 