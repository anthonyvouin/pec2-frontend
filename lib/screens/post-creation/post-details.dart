import 'package:flutter/foundation.dart' hide Category;
import 'dart:convert';
import 'dart:math' as math;
import 'package:firstflutterapp/config/router.dart';
import 'package:flutter/material.dart';
import 'package:firstflutterapp/interfaces/category.dart';
import 'package:firstflutterapp/screens/post-creation/post-creation-service.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart'; // Ajout de l'import XFile

class PostDetailsView extends StatefulWidget {
  final XFile imageFile; // Changé de File à XFile

  const PostDetailsView({Key? key, required this.imageFile}) : super(key: key);

  @override
  _PostDetailsViewState createState() => _PostDetailsViewState();
}

class _PostDetailsViewState extends State<PostDetailsView> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  List<Category> _categories = [];
  List<Category> _selectedCategories = [];
  bool _isFree = false;
  bool _isLoading = false;
  final PostCreationService _postCreationService = PostCreationService();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {      final categories = await _postCreationService.loadCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des catégories: $e'),
          ),
        );
      }
    }
  }  Future<void> _publishPost() async {
    // Validation des données du post
    final error = _postCreationService.validatePostData(
      selectedCategories: _selectedCategories,
      name: _nameController.text,
      description: _descriptionController.text,
    );

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Pour le web, on doit traiter l'image différemment
      String imageData;
      if (kIsWeb) {
        // Lire les bytes de l'image et les convertir en base64
        final bytes = await widget.imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        
        // Déterminer le type MIME en fonction de l'extension du fichier
        final fileName = widget.imageFile.name.toLowerCase();
        String mimeType = 'image/jpeg'; // par défaut
        
        if (fileName.endsWith('.png')) {
          mimeType = 'image/png';
        } else if (fileName.endsWith('.gif')) {
          mimeType = 'image/gif';
        } else if (fileName.endsWith('.webp')) {
          mimeType = 'image/webp';
        }
        
        // Créer une chaîne d'image data URI
        imageData = 'data:$mimeType;base64,$base64Image';
        
        if (kDebugMode) {          
          print('Web: Création d\'une image en base64');
          print('Nom du fichier: ${widget.imageFile.name}');
          print('Type MIME détecté: $mimeType');
          print('Taille des bytes: ${bytes.length}');
          print('Taille de la chaîne base64: ${base64Image.length}');
          print('Début du data URI: ${imageData.substring(0, math.min(50, imageData.length))}...');
        }
      } else {
        // Pour les plateformes mobiles, utiliser simplement le chemin
        imageData = widget.imageFile.path;
        if (kDebugMode) {
          print('Mobile: Utilisation du chemin de fichier');
          print('Chemin: $imageData');
        }
      }

      await _postCreationService.publishPost(
        imageUrl: imageData,
        name: _nameController.text,
        description: _descriptionController.text,
        selectedCategories: _selectedCategories,
        isFree: _isFree,
      );

      // Message de succès
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Publication réussie')));

      context.go(homeRoute);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la publication: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle publication'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Aperçu de l'image avec label
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aperçu de l\'image',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),                          
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb
                                ? FutureBuilder<Uint8List>(
                                    future: widget.imageFile.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return Image.memory(
                                          snapshot.data!,
                                          fit: BoxFit.contain,
                                          width: double.infinity,
                                        );
                                      }
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                  )
                                : FutureBuilder<Uint8List>(
                                    future: widget.imageFile.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return Image.memory(
                                          snapshot.data!,
                                          fit: BoxFit.contain,
                                          width: double.infinity,
                                        );
                                      }
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Nom de l'image avec label explicite
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nom de l\'image',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: 'Saisissez un nom pour cette image',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description avec label
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Décrivez votre image',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sélection de catégories (multiples)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Catégories',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              // Afficher les catégories sélectionnées
                              if (_selectedCategories.isNotEmpty)
                                Wrap(
                                  spacing: 8,
                                  children: _selectedCategories.map((category) {
                                    return Chip(
                                      label: Text(category.name),
                                      onDeleted: () {
                                        setState(() {
                                          _selectedCategories.remove(category);
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),

                              // Liste déroulante pour ajouter des catégories
                              DropdownButtonHideUnderline(
                                child: DropdownButton<Category>(
                                  isExpanded: true,
                                  hint: const Text('Ajouter une catégorie'),
                                  value: null,
                                  items: _categories
                                      .where((category) =>
                                          !_selectedCategories.contains(category))
                                      .map((Category category) {
                                    return DropdownMenuItem<Category>(
                                      value: category,
                                      child: Text(category.name),
                                    );
                                  }).toList(),
                                  onChanged: (Category? newValue) {
                                    if (newValue != null &&
                                        !_selectedCategories.contains(newValue)) {
                                      setState(() {
                                        _selectedCategories.add(newValue);
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sélectionnez une ou plusieurs catégories',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Option privée/publique avec description plus claire
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Visibilité',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Publique ?',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  _isFree
                                      ? 'Image visible par tous'
                                      : 'Image privée',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _isFree,
                              onChanged: (value) {
                                setState(() {
                                  _isFree = value;
                                });
                              },
                              activeColor: Theme.of(context).primaryColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bouton Partager
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        onPressed: _publishPost,
                        child: const Text(
                          'Partager',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}