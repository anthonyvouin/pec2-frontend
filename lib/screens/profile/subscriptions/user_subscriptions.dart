import 'package:flutter/material.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class UserSubscriptionsPage extends StatefulWidget {
  const UserSubscriptionsPage({Key? key}) : super(key: key);

  @override
  _UserSubscriptionsPageState createState() => _UserSubscriptionsPageState();
}

class _UserSubscriptionsPageState extends State<UserSubscriptionsPage> {
  late Future<List<dynamic>> _subscriptionsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _subscriptionsFuture = _fetchSubscriptions();
  }

  Future<List<dynamic>> _fetchSubscriptions() async {
    try {
      final ApiResponse response = await _apiService.request(
        method: 'GET',
        endpoint: '/subscriptions/user',
        withAuth: true,
      );
      
      if (response.success) {
        if (response.data == null) {
          return [];
        }
        return response.data as List<dynamic>;
      } else {
        throw Exception('Erreur: ${response.error}');
      }
    } catch (e) {
      throw Exception('Erreur lors du chargement des abonnements: $e');
    }
  }

  String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> subscription) {
    final creator = subscription['creator'] is Map<String, dynamic> 
        ? subscription['creator'] as Map<String, dynamic> 
        : <String, dynamic>{};
        
    final status = subscription['status']?.toString() ?? 'UNKNOWN';
    
    final startDate = formatDate(subscription['startDate']?.toString() ?? '');
    final endDate = formatDate(subscription['endDate']?.toString() ?? '');

    Color statusColor;
    switch (status) {
      case 'ACTIVE':
        statusColor = Colors.green;
        break;
      case 'CANCELED':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: creator['profilePicture'] != null
              ? NetworkImage(creator['profilePicture'].toString())
              : null,
          child: creator['profilePicture'] == null
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(creator['userName'] ?? 'Utilisateur inconnu'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Du $startDate au $endDate'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        onTap: () {
          if (creator['userName'] != null) {
            context.go('/profile/${creator['userName']}');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes abonnements'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _subscriptionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            String errorMessage = 'Une erreur est survenue';
            
            if (snapshot.error.toString().contains('TypeError: null')) {
              errorMessage = 'Impossible de charger les abonnements';
            } else {
              errorMessage = 'Erreur: ${snapshot.error.toString().length > 100 
                ? snapshot.error.toString().substring(0, 100) + '...' 
                : snapshot.error}';
            }
            
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _subscriptionsFuture = _fetchSubscriptions();
                      });
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Vous n\'avez aucun abonnement',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final subscriptions = snapshot.data!;
          return ListView.builder(
            itemCount: subscriptions.length,
            itemBuilder: (context, index) {
              try {
                if (subscriptions[index] is Map<String, dynamic>) {
                  return _buildSubscriptionCard(
                    subscriptions[index] as Map<String, dynamic>,
                  );
                } else {
                  return const Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Données d\'abonnement invalides'),
                    ),
                  );
                }
              } catch (e) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Erreur d\'affichage: $e'),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
} 