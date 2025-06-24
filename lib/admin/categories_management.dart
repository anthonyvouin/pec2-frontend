import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/date_formatter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/admin/category_create_dialog.dart';
import '../components/admin/category_delete.dart';
import '../components/admin/category_update.dart';

class CategoriesManagement extends StatefulWidget {
  const CategoriesManagement({Key? key}) : super(key: key);

  @override
  _CategoriesManagementState createState() => _CategoriesManagementState();
}

class _CategoriesManagementState extends State<CategoriesManagement> {
  List<dynamic> _categories = [];
  bool _loadingCategories = false;
  late CategoryDelete _deleteHandler;
  late CategoryUpdate _updateHandler;

  @override
  void initState() {
    super.initState();
    developer.log('CategoriesManagement - initState');
    _fetchCategories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    developer.log('CategoriesManagement - didChangeDependencies');
    
    _deleteHandler = CategoryDelete(
      context: context,
      onDeleteSuccess: () {
        developer.log('Delete success callback appelé');
        setState(() {
          _fetchCategories();
        });
      },
    );
    
    _updateHandler = CategoryUpdate(
      context: context,
      onUpdateSuccess: () {
        developer.log('Update success callback appelé');
        setState(() {
          _fetchCategories();
        });
      },
    );
    
    developer.log('Handlers initialisés');
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 900;

    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSmallScreen)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Gestion des catégories",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return CategoryCreateDialog(
                            onCategoryCreated: () {
                              _fetchCategories();
                            },
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Nouvelle catégorie"),
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Gestion des catégories",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return CategoryCreateDialog(
                          onCategoryCreated: () {
                            _fetchCategories();
                          },
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Nouvelle catégorie"),
                ),
              ],
            ),
          const SizedBox(height: 24),
          Expanded(
            child: _loadingCategories
                ? const Center(child: CircularProgressIndicator())
                : _categories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.category_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Aucune catégorie trouvée",
                              style: TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _fetchCategories,
                              child: const Text("Actualiser"),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            elevation: 2,
                            child: ExpansionTile(
                              leading: category['pictureUrl'] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(25),
                                      child: SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: Image.network(
                                          category['pictureUrl'],
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return CircleAvatar(
                                              radius: 25,
                                              backgroundColor: Colors.grey.shade200,
                                              child: const Icon(Icons.image_not_supported),
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
                                    )
                                  : CircleAvatar(
                                      radius: 25,
                                      backgroundColor: Colors.grey.shade200,
                                      child: const Icon(Icons.category),
                                    ),
                              title: Text(
                                category['name'] ?? 'Sans nom',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: null,
                              trailing: isSmallScreen
                                  ? IconButton(
                                      icon: const Icon(Icons.more_vert),
                                      onPressed: () {
                                        showModalBottomSheet(
                                          context: context,
                                          builder: (context) {
                                            return SafeArea(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ListTile(
                                                    leading: const Icon(Icons.edit_outlined),
                                                    title: const Text('Modifier'),
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      developer.log('Bouton modifier cliqué (mobile) pour ${category['name']}');
                                                      _updateHandler.showUpdateDialog(category);
                                                    },
                                                  ),
                                                  ListTile(
                                                    leading: const Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.red,
                                                    ),
                                                    title: const Text(
                                                      'Supprimer',
                                                      style: TextStyle(color: Colors.red),
                                                    ),
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      _deleteHandler.showDeleteDialog(category);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined),
                                          onPressed: () {
                                            developer.log('Bouton modifier cliqué (desktop) pour ${category['name']}');
                                            _updateHandler.showUpdateDialog(category);
                                          },
                                          tooltip: 'Modifier',
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            _deleteHandler.showDeleteDialog(category);
                                          },
                                          tooltip: 'Supprimer',
                                        ),
                                      ],
                                    ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildDetailRow('ID', category['id'] ?? 'N/A', isSmallScreen),
                                      _buildDetailRow('Nom', category['name'] ?? 'N/A', isSmallScreen),
                                      if (category['pictureUrl'] != null)
                                        _buildDetailRow(
                                          'Image',
                                          category['pictureUrl'],
                                          isSmallScreen,
                                          isImage: true,
                                        ),
                                      _buildDetailRow(
                                        'Créé le',
                                        DateFormatter.formatDateTime(category['createdAt']),
                                        isSmallScreen,
                                      ),
                                      _buildDetailRow(
                                        'Mis à jour le',
                                        DateFormatter.formatDateTime(category['updatedAt']),
                                        isSmallScreen,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isSmallScreen, {bool isImage = false}) {
    if (isSmallScreen && !isImage) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(value),
          ],
        ),
      );
    } else if (isImage && value != 'N/A') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSmallScreen)
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              )
            else
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      '$label:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                final url = Uri.parse(value);
                if (await canLaunchUrl(url)) {
                  await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
              icon: const Icon(Icons.fullscreen),
              label: const Text('Voir en plein écran'),
            ),
            const SizedBox(height: 8),
            Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      value,
                      fit: BoxFit.contain,
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
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red.shade400,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Erreur de chargement de l\'image',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () async {
                        final url = Uri.parse(value);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                '$label:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );
    }
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _loadingCategories = true;
    });

    try {
      final response = await ApiService().request(
        method: 'GET',
        endpoint: '/categories',
        withAuth: true,
      );

      if (response.data is List) {
        setState(() {
          _categories = response.data;
          _loadingCategories = false;
        });
      } else {
        developer.log('Réponse reçue mais pas au format attendu: $response');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Format de réponse inattendu de l'API"),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _categories = [];
          _loadingCategories = false;
        });
      }
    } catch (error) {
      developer.log('Erreur lors de la récupération des catégories: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur: $error"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _categories = [];
        _loadingCategories = false;
      });
    }
  }
}
