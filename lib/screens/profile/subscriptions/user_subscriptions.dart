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
    final creator = subscription['creator'] as Map<String, dynamic>;
    final status = subscription['status'] as String;
    final startDate = formatDate(subscription['startDate'].toString());
    final endDate = formatDate(subscription['endDate'].toString());

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
          // Naviguer vers le profil du créateur
          context.go('/profile/${creator['userName']}');
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
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
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
              return _buildSubscriptionCard(
                subscriptions[index] as Map<String, dynamic>,
              );
            },
          );
        },
      ),
    );
  }
} 