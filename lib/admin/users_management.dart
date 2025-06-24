import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/date_formatter.dart';
import '../components/admin/admin_layout.dart';

class UsersManagement extends StatefulWidget {
  const UsersManagement({Key? key}) : super(key: key);

  @override
  _UsersManagementState createState() => _UsersManagementState();
}

class _UsersManagementState extends State<UsersManagement> {
  List<dynamic> _users = [];
  bool _loadingUsers = false;

  String _getRoleFrench(String? role) {
    if (role == null) return 'Utilisateur';

    switch (role) {
      case 'ADMIN':
        return 'Administrateur';
      case 'CONTENT_CREATOR':
        return 'Créateur';
      case 'USER':
        return 'Utilisateur';
      default:
        return role;
    }
  }

  Color _getRoleColor(String? role) {
    if (role == null) return Colors.blue;

    switch (role) {
      case 'ADMIN':
        return Colors.red;
      case 'CONTENT_CREATOR':
        return Colors.purple;
      case 'USER':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRoleBadge(String? role) {
    final roleFrench = _getRoleFrench(role);
    final roleColor = _getRoleColor(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: roleColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: roleColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        roleFrench,
        style: TextStyle(
          fontSize: 11,
          color: roleColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchUsers();
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
                  "Gestion des utilisateurs",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _fetchUsers,
                    icon: Icon(
                      _loadingUsers ? Icons.hourglass_empty : Icons.refresh,
                    ),
                    label: Text(_loadingUsers ? "Chargement..." : "Actualiser"),
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Gestion des utilisateurs",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _fetchUsers,
                  icon: Icon(
                    _loadingUsers ? Icons.hourglass_empty : Icons.refresh,
                  ),
                  label: Text(_loadingUsers ? "Chargement..." : "Actualiser"),
                ),
              ],
            ),
          const SizedBox(height: 24),
          Expanded(
            child: _loadingUsers
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Aucun utilisateur trouvé",
                              style: TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _fetchUsers,
                              child: const Text("Essayer à nouveau"),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          if (user is! Map) {
                            return ListTile(
                              title: Text("Format d'utilisateur invalide"),
                              subtitle: Text("Données: $user"),
                            );
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            elevation: 2,
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: Text(
                                  user['userName'] != null &&
                                          (user['userName'] as String).isNotEmpty
                                      ? (user['userName'] as String)[0]
                                          .toUpperCase()
                                      : 'U',
                                  style: TextStyle(color: Colors.blue.shade800),
                                ),
                              ),
                              title: Text(
                                user['userName'] as String? ??
                                    'Utilisateur inconnu',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                user['email'] as String? ??
                                    'Email non disponible',
                              ),
                              trailing: isSmallScreen
                                  ? const Icon(Icons.chevron_right)
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildRoleBadge(user['role'] as String?),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.chevron_right),
                                      ],
                                    ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (isSmallScreen)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 16.0),
                                          child: _buildRoleBadge(user['role'] as String?),
                                        ),
                                      ..._buildUserDetailsList(user, isSmallScreen),
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

  List<Widget> _buildUserDetailsList(Map<dynamic, dynamic> user, bool isSmallScreen) {
    List<Widget> details = [];

    if (user['id'] != null) {
      details.add(_buildDetailRow('ID', user['id'].toString(), isSmallScreen));
    }

    if (user['firstName'] != null || user['lastName'] != null) {
      final firstName = user['firstName'] as String? ?? '';
      final lastName = user['lastName'] as String? ?? '';
      details.add(_buildDetailRow('Nom complet', '$firstName $lastName', isSmallScreen));
    }

    if (user['birthDayDate'] != null) {
      details.add(
        _buildDetailRow(
          'Date de naissance',
          DateFormatter.formatDate(user['birthDayDate']),
          isSmallScreen,
        ),
      );
      details.add(
        _buildDetailRow(
          'Âge',
          DateFormatter.calculateAge(user['birthDayDate']),
          isSmallScreen,
        ),
      );
    }

    if (user['sexe'] != null) {
      details.add(_buildDetailRow('Sexe', _translateSexe(user['sexe']), isSmallScreen));
    }

    if (user['bio'] != null) {
      details.add(_buildDetailRow('Bio', user['bio'], isSmallScreen));
    }

    if (user['subscriptionPrice'] != null) {
      details.add(
        _buildDetailRow('Prix abonnement', '${user['subscriptionPrice']} €', isSmallScreen),
      );
    }

    if (user['stripeCustomerId'] != null) {
      details.add(_buildDetailRow('ID Stripe', user['stripeCustomerId'], isSmallScreen));
    }

    final List<Widget> statusWidgets = [];

    if (user['enable'] != null) {
      final bool enabled = user['enable'] == true;
      statusWidgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          margin: const EdgeInsets.only(bottom: 4, right: 4),
          decoration: BoxDecoration(
            color: enabled ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: enabled ? Colors.green.shade200 : Colors.red.shade200,
              width: 1,
            ),
          ),
          child: Text(
            enabled ? 'Compte activé' : 'Compte désactivé',
            style: TextStyle(
              fontSize: 11,
              color: enabled ? Colors.green.shade700 : Colors.red.shade700,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      );
    }

    if (user['subscriptionEnable'] != null) {
      final bool subEnabled = user['subscriptionEnable'] == true;
      statusWidgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          margin: const EdgeInsets.only(bottom: 4, right: 4),
          decoration: BoxDecoration(
            color: subEnabled ? Colors.green.shade50 : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: subEnabled ? Colors.green.shade200 : Colors.orange.shade200,
              width: 1,
            ),
          ),
          child: Text(
            subEnabled ? 'Abonnement actif' : 'Pas d\'abonnement',
            style: TextStyle(
              fontSize: 11,
              color: subEnabled ? Colors.green.shade700 : Colors.orange.shade700,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      );
    }

    if (user['commentsEnable'] != null) {
      final bool commentsEnabled = user['commentsEnable'] == true;
      statusWidgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          margin: const EdgeInsets.only(bottom: 4, right: 4),
          decoration: BoxDecoration(
            color: commentsEnabled ? Colors.green.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: commentsEnabled ? Colors.green.shade200 : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Text(
            commentsEnabled ? 'Commentaires activés' : 'Commentaires désactivés',
            style: TextStyle(
              fontSize: 11,
              color: commentsEnabled ? Colors.green.shade700 : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      );
    }

    if (user['messageEnable'] != null) {
      final bool messagesEnabled = user['messageEnable'] == true;
      statusWidgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          margin: const EdgeInsets.only(bottom: 4, right: 4),
          decoration: BoxDecoration(
            color: messagesEnabled ? Colors.green.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: messagesEnabled ? Colors.green.shade200 : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Text(
            messagesEnabled ? 'Messages activés' : 'Messages désactivés',
            style: TextStyle(
              fontSize: 11,
              color: messagesEnabled ? Colors.green.shade700 : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      );
    }

    if (statusWidgets.isNotEmpty) {
      details.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Statut du compte:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: statusWidgets,
              ),
            ],
          ),
        ),
      );
    }

    if (user['emailVerified'] != null && user['emailVerified'] is Map) {
      final emailVerified = user['emailVerified'] as Map;
      final bool isVerified = emailVerified['valid'] == true;

      details.add(
        Chip(
          backgroundColor:
              isVerified ? Colors.green.shade100 : Colors.orange.shade100,
          label: Text(
            isVerified ? 'Email vérifié' : 'Email non vérifié',
            style: TextStyle(
              color:
                  isVerified ? Colors.green.shade800 : Colors.orange.shade800,
            ),
          ),
        ),
      );

      if (emailVerified['time'] != null) {
        details.add(
          _buildDetailRow(
            'Vérifié le',
            DateFormatter.formatDateTime(emailVerified['time']),
            isSmallScreen,
          ),
        );
      }
    }

    if (user['createdAt'] != null) {
      details.add(
        _buildDetailRow(
          'Créé le',
          DateFormatter.formatDateTime(user['createdAt']),
          isSmallScreen,
        ),
      );
    }

    if (user['tokenVerificationEmail'] != null) {
      final token = user['tokenVerificationEmail'].toString();
      details.add(
        _buildDetailRow(
          'Token de vérification',
          token.length > 20 ? '${token.substring(0, 20)}...' : token,
          isSmallScreen,
        ),
      );
    }

    return details;
  }

  String _translateSexe(String sexe) {
    switch (sexe) {
      case 'MAN':
        return 'Homme';
      case 'WOMAN':
        return 'Femme';
      case 'OTHER':
        return 'Autre';
      default:
        return sexe;
    }
  }

  Widget _buildDetailRow(String label, String value, bool isSmallScreen) {
    if (isSmallScreen) {
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
            Text(
              value,
              style: const TextStyle(fontSize: 14),
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

  Future<void> _fetchUsers() async {
    setState(() {
      _loadingUsers = true;
    });

    try {
      final response = await ApiService().request(
        method: 'GET',
        endpoint: '/users',
        withAuth: true,
      );

      if (response.data is List) {
        setState(() {
          _users = response.data;
          _loadingUsers = false;
        });
      } else {
        if (response.data is Map<String, dynamic>) {
          final possibleListKeys = [
            'data',
            'users',
            'results',
            'items',
            'content',
          ];

          for (final key in possibleListKeys) {
            if (response.data.containsKey(key) && response[key] is List) {
              setState(() {
                _users = response.data[key];
                _loadingUsers = false;
              });
              return;
            }
          }
        }

        developer.log('Réponse reçue mais pas au format attendu: $response');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Format de réponse inattendu de l'API"),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _users = [];
          _loadingUsers = false;
        });
      }
    } catch (error) {
      developer.log('Erreur lors de la récupération des utilisateurs: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $error"), backgroundColor: Colors.red),
      );
      setState(() {
        _users = [];
        _loadingUsers = false;
      });
    }
  }
}
