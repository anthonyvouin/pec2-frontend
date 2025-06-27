import 'package:firstflutterapp/services/toast_service.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'dart:convert';
import 'dart:math' as math;
import 'package:firstflutterapp/config/router.dart';
import 'package:flutter/material.dart';
import 'package:firstflutterapp/interfaces/category.dart';
import 'package:firstflutterapp/screens/post-creation/post-creation-service.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import '../../components/form/custom_form_field.dart';
import '../../components/form/loading_button.dart';
import '../../notifiers/userNotififers.dart';
import '../../services/validators_service.dart'; // Ajout de l'import XFile

class PostDetailsView extends StatefulWidget {
  final XFile? imageFile; // Changé de File à XFile
  final String? name;
  final String? description;
  final List<Category>? categories;
  final bool? visibility;
  final String? imageUrl;
  final String step;
  final String? id;

  const PostDetailsView({
    Key? key,
    required this.step,
    this.imageFile,
    this.description,
    this.name,
    this.categories,
    this.visibility,
    this.imageUrl,
    this.id,
  }) : super(key: key);

  @override
  _PostDetailsViewState createState() => _PostDetailsViewState();
}

class _PostDetailsViewState extends State<PostDetailsView> {
  bool  _isCreator = false;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _nameController;
  String? _imageUrl;
  List<Category> _categories = [];
  List<Category> _selectedCategories = [];
  bool _isFree = false;
  bool _isLoading = false;
  bool _isSubmitted = false;
  final PostCreationService _postCreationService = PostCreationService();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _nameController = TextEditingController(text: widget.name ?? '');
    _descriptionController = TextEditingController(text: widget.description ?? '');
    _isFree = widget.visibility ?? true;
    _selectedCategories = widget.categories ?? [];
    _imageUrl = widget.imageUrl;
    print(widget.step);
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

    try {
      final categories = await _postCreationService.loadCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ToastService.showToast(
          'Erreur lors du chargement des catégories: $e',
          ToastificationType.error,
        );
      }
    }
  }

  Future<void> _publishPost() async {
    setState(() {
      _isSubmitted = true;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitted = false;
      });
      return;
    }
    // Validation des données du post
    final error = _postCreationService.validatePostData(
      selectedCategories: _selectedCategories,
    );

    if (error != null) {
      ToastService.showToast(error, ToastificationType.error);
    }

    if (widget.step == 'create') {
      _sendCreatePost();
    }else{
      _sendUpdatePost();
    }
  }

  Future<void> _sendUpdatePost() async{
    try{
      if(widget.id != null){
        await _postCreationService.updatePost(
          id: widget.id!,
          name: _nameController.text,
          description: _descriptionController.text,
          selectedCategories: _selectedCategories,
          isFree: _isFree,
        );
        ToastService.showToast(
          'Modification réussie',
          ToastificationType.success,
        );

        context.go(profileRoute);
      }

    }catch(e){
      ToastService.showToast("Erreur lors de la modification de l'image $e", ToastificationType.error);
    }
  }

  Future<void> _sendCreatePost() async {
    try {
      // Pour le web, on doit traiter l'image différemment
      String imageData;
      if (widget.imageFile != null) {
        if (kIsWeb) {
          // Lire les bytes de l'image et les convertir en base64
          final bytes = await widget.imageFile!.readAsBytes();
          final base64Image = base64Encode(bytes);

          // Déterminer le type MIME en fonction de l'extension du fichier
          final fileName = widget.imageFile!.name.toLowerCase();
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
            print('Nom du fichier: ${widget.imageFile!.name}');
            print('Type MIME détecté: $mimeType');
            print('Taille des bytes: ${bytes.length}');
            print('Taille de la chaîne base64: ${base64Image.length}');
            print(
              'Début du data URI: ${imageData.substring(0, math.min(50, imageData.length))}...',
            );
          }
        } else {
          // Pour les plateformes mobiles, utiliser simplement le chemin
          imageData = widget.imageFile!.path;
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
        ToastService.showToast(
          'Publication réussie',
          ToastificationType.success,
        );

        context.go(homeRoute);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ToastService.showToast(
          'Erreur lors de la publication: $e',
          ToastificationType.error,
        );
      }
    }
  }

  Widget _selectedImage() {
    if (widget.imageFile != null) {
      if (kIsWeb) {
        return FutureBuilder<Uint8List>(
          future: widget.imageFile!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.contain,
                width: double.infinity,
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        );
      } else {
        return FutureBuilder<Uint8List>(
          future: widget.imageFile!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.contain,
                width: double.infinity,
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        );
      }
    }
    return Image.network(
      widget.imageUrl!,
      fit: BoxFit.cover,
      width: 200,
      height: 200,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userNotifier = Provider.of<UserNotifier>(context);
    _isCreator = userNotifier.user?.role == 'CONTENT_CREATOR';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _imageUrl != null ? 'Éditer une publication' : 'Nouvelle publication',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goNamed('profile'),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                builder: (context, constraints) {
                  double formWidth =
                      constraints.maxWidth > 800
                          ? constraints.maxWidth / 2
                          : double.infinity;

                  return SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: formWidth),
                        child: Padding(
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
                                  child: Center(child: _selectedImage()),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    CustomTextField(
                                      controller: _nameController,
                                      label: 'Nom de l\'image',
                                      validators: [RequiredValidator()],
                                    ),
                                    const SizedBox(height: 16),
                                    CustomTextField(
                                      controller: _descriptionController,
                                      label: 'Description',
                                      maxLine: 4,
                                      validators: [RequiredValidator()],
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      width: double.infinity,
                                      alignment: Alignment.centerLeft,
                                      child: const Text(
                                        'Catégories',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (_selectedCategories.isNotEmpty)
                                      Container(
                                        width: double.infinity,
                                        alignment: Alignment.centerLeft,
                                        child: Wrap(
                                          spacing: 8,
                                          children:
                                              _selectedCategories.map((
                                                category,
                                              ) {
                                                return Chip(
                                                  label: Text(category.name),
                                                  onDeleted: () {
                                                    setState(() {
                                                      _selectedCategories
                                                          .remove(category);
                                                    });
                                                  },
                                                );
                                              }).toList(),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<Category>(
                                              isExpanded: true,
                                              hint: const Text(
                                                'Ajouter une catégorie',
                                              ),
                                              value: null,
                                              items:
                                                  _categories
                                                      .where(
                                                        (category) =>
                                                            !_selectedCategories
                                                                .contains(
                                                                  category,
                                                                ),
                                                      )
                                                      .map((Category category) {
                                                        return DropdownMenuItem<
                                                          Category
                                                        >(
                                                          value: category,
                                                          child: Text(
                                                            category.name,
                                                          ),
                                                        );
                                                      })
                                                      .toList(),
                                              onChanged: (Category? newValue) {
                                                if (newValue != null &&
                                                    !_selectedCategories
                                                        .contains(newValue)) {
                                                  setState(() {
                                                    _selectedCategories.add(
                                                      newValue,
                                                    );
                                                  });
                                                }
                                              },
                                            ),
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
                                    const SizedBox(height: 24),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Publique ?',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  _isFree
                                                      ? 'Image visible par tous'
                                                      : 'Image pour les abonnés',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Switch(
                                              value: _isFree,
                                              onChanged: _isCreator
                                                  ? (value) {
                                                setState(() {
                                                  _isFree = value;
                                                });
                                              }
                                                  : null, // désactivé si _isCreator est false
                                              activeColor:
                                                  Theme.of(
                                                    context,
                                                  ).primaryColor,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 32),
                                    Center(
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: LoadingButton(
                                          label:
                                              widget.step == 'create'
                                                  ? 'Partager'
                                                  : 'Enregistrer',
                                          isSubmitted: _isSubmitted,
                                          onPressed: _publishPost,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
