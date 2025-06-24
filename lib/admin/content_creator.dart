import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/date_formatter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/admin/content_creator_update_dialogue.dart';

class AdminContentCreator extends StatefulWidget {
  const AdminContentCreator({Key? key}) : super(key: key);

  @override
  _AdminContentCreatorState createState() => _AdminContentCreatorState();
}

class _AdminContentCreatorState extends State<AdminContentCreator> {
  List<dynamic> _contentCreators = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchContentCreators();
  }

  String _getStatusFrench(String? status) {
    if (status == null) return 'N/A';

    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'En attente';
      case 'APPROVED':
        return 'Approuvé';
      case 'REJECTED':
        return 'Rejeté';
      default:
        return status;
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;

    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusBadge(dynamic creator) {
    final statusFrench = _getStatusFrench(creator['status']);
    final statusColor = _getStatusColor(creator['status']);

    return InkWell(
      onTap: () async {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return ContentCreatorUpdateDialog(
              contentCreator: creator,
              onStatusUpdated: _fetchContentCreators,
            );
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              statusFrench,
              style: TextStyle(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.edit, size: 14, color: statusColor),
          ],
        ),
      ),
    );
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
                  "Gestion des créateurs de contenu",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _fetchContentCreators,
                    icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.refresh),
                    label: Text(_isLoading ? "Chargement..." : "Actualiser"),
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Gestion des créateurs de contenu",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _fetchContentCreators,
                  icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.refresh),
                  label: Text(_isLoading ? "Chargement..." : "Actualiser"),
                ),
              ],
            ),
          const SizedBox(height: 24),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _contentCreators.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.business_center_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Aucune demande trouvée",
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _fetchContentCreators,
                            child: const Text("Essayer à nouveau"),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: _contentCreators.length,
                      itemBuilder: (context, index) {
                        final creator = _contentCreators[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          elevation: 2,
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.purple.shade100,
                              child: Text(
                                creator['companyName'] != null
                                    ? creator['companyName'][0].toUpperCase()
                                    : 'C',
                                style: TextStyle(color: Colors.purple.shade800),
                              ),
                            ),
                            title: Text(
                              creator['companyName'] ?? 'Entreprise inconnue',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  creator['companyType'] ?? 'Type non spécifié',
                                ),
                                isSmallScreen
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'SIRET: ${creator['siretNumber'] ?? 'Non spécifié'}',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          _buildStatusBadge(creator),
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'SIRET: ${creator['siretNumber'] ?? 'Non spécifié'}',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                          _buildStatusBadge(creator),
                                        ],
                                      ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailRow(
                                      'ID',
                                      creator['id']?.toString() ?? 'N/A',
                                      isSmallScreen,
                                    ),
                                    _buildDetailRow(
                                      'ID Utilisateur',
                                      creator['userId']?.toString() ?? 'N/A',
                                      isSmallScreen,
                                    ),
                                    _buildDetailRow(
                                      'Entreprise',
                                      creator['companyName'] ?? 'N/A',
                                      isSmallScreen,
                                    ),
                                    _buildDetailRow(
                                      'Type d\'entreprise',
                                      creator['companyType'] ?? 'N/A',
                                      isSmallScreen,
                                    ),
                                    _buildDetailRow(
                                      'SIRET',
                                      creator['siretNumber'] ?? 'N/A',
                                      isSmallScreen,
                                    ),
                                    _buildDetailRow(
                                      'TVA',
                                      creator['vatNumber'] ?? 'Non renseigné',
                                      isSmallScreen,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Adresse:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isSmallScreen ? 14 : 16,
                                        color: isSmallScreen ? Colors.grey.shade700 : null,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildDetailRow(
                                      'Rue',
                                      creator['streetAddress'] ?? 'N/A',
                                      isSmallScreen,
                                    ),
                                    _buildDetailRow(
                                      'Code postal',
                                      creator['postalCode'] ?? 'N/A',
                                      isSmallScreen,
                                    ),
                                    _buildDetailRow(
                                      'Ville',
                                      creator['city'] ?? 'N/A',
                                      isSmallScreen,
                                    ),
                                    _buildDetailRow(
                                      'Pays',
                                      creator['country'] ?? 'N/A',
                                      isSmallScreen,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Informations bancaires:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isSmallScreen ? 14 : 16,
                                        color: isSmallScreen ? Colors.grey.shade700 : null,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildDetailRow(
                                      'IBAN',
                                      creator['iban'] ?? 'N/A',
                                      isSmallScreen,
                                    ),
                                    _buildDetailRow(
                                      'BIC',
                                      creator['bic'] ?? 'N/A',
                                      isSmallScreen,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildDetailRow(
                                      'Document justificatif',
                                      creator['documentProofUrl'] ?? 'N/A',
                                      isSmallScreen,
                                      isLink: true,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildDetailRow(
                                      'Créé le',
                                      DateFormatter.formatDateTime(
                                        creator['createdAt'],
                                      ),
                                      isSmallScreen,
                                    ),
                                    if (creator['updatedAt'] != null)
                                      _buildDetailRow(
                                        'Mis à jour le',
                                        DateFormatter.formatDateTime(
                                          creator['updatedAt'],
                                        ),
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

  Widget _buildDetailRow(String label, String value, bool isSmallScreen, {bool isLink = false}) {
    if (isSmallScreen && !isLink) {
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
    } else if (isLink && value != 'N/A') {
      // Cas spécial pour les liens (documents)
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
                    width: 140,
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
            _isPdfFile(value)
                ? Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.picture_as_pdf,
                          size: 64,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Document PDF',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Cliquez sur "Voir en plein écran" pour ouvrir',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                : Stack(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          value,
                          fit: BoxFit.contain,
                          loadingBuilder: (
                            context,
                            child,
                            loadingProgress,
                          ) {
                            if (loadingProgress == null)
                              return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress
                                                .expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress
                                                .expectedTotalBytes!
                                        : null,
                              ),
                            );
                          },
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Erreur de chargement de l\'image',
                                    style: TextStyle(
                                      color: Colors.red,
                                    ),
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
                                mode:
                                    LaunchMode.externalApplication,
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
              width: 140,
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

  bool _isPdfFile(String url) {
    return url.toLowerCase().endsWith('.pdf');
  }

  Future<void> _fetchContentCreators() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService().request(
        method: 'GET',
        endpoint: '/content-creators/all',
        withAuth: true,
      );

      if (response.data is List) {
        setState(() {
          _contentCreators = response.data;
          _isLoading = false;
        });
      } else {
        developer.log(
          'Réponse reçue mais pas au format attendu: ${response.data}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Format de réponse inattendu de l'API"),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _contentCreators = [];
          _isLoading = false;
        });
      }
    } catch (error) {
      developer.log(
        'Erreur lors de la récupération des créateurs de contenu: $error',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $error"), backgroundColor: Colors.red),
      );
      setState(() {
        _contentCreators = [];
        _isLoading = false;
      });
    }
  }
}
