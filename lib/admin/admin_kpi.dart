import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:developer' as developer;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AdminKpiDashboard extends StatefulWidget {
  const AdminKpiDashboard({Key? key}) : super(key: key);

  @override
  State<AdminKpiDashboard> createState() => _AdminKpiDashboardState();
}

class _AdminKpiDashboardState extends State<AdminKpiDashboard> {
  bool _isLoading = true;
  Map<String, int> _roleStats = {};
  Map<String, int> _genderStats = {};
  int _last7DaysRevenue = 0;
  final currencyFormatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final roleResponse = await ApiService().request(
        method: 'GET',
        endpoint: '/users/stats/roles',
        withAuth: true,
      );

      final genderResponse = await ApiService().request(
        method: 'GET',
        endpoint: '/users/stats/gender',
        withAuth: true,
      );
      
      // Récupération des revenus des 7 derniers jours
      final DateTime now = DateTime.now();
      final DateTime sevenDaysAgo = now.subtract(const Duration(days: 7));
      
      final revenueResponse = await ApiService().request(
        method: 'GET',
        endpoint: '/subscriptions/revenue',
        withAuth: true,
        queryParams: {
          'start_date': DateFormat('yyyy-MM-dd').format(sevenDaysAgo),
          'end_date': DateFormat('yyyy-MM-dd').format(now),
        },
      );

      if (mounted) {
        setState(() {
          _roleStats = Map<String, int>.from(roleResponse.data);
          _genderStats = Map<String, int>.from(genderResponse.data);
          // L'API retourne le montant en centimes, donc on divise par 100 pour avoir en euros
          _last7DaysRevenue = (revenueResponse.data['total'] as int) ~/ 100;
          _isLoading = false;
        });
      }
    } catch (error) {
      developer.log('Erreur lors de la récupération des statistiques: $error');
      if (mounted) {
        setState(() {
          _roleStats = {};
          _genderStats = {};
          _last7DaysRevenue = 0;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques Générales',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildRevenueCard(),
          const SizedBox(height: 24),
          _buildRoleCards(),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildRoleChart()),
              const SizedBox(width: 24),
              Expanded(child: _buildGenderChart()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money, color: Colors.purple, size: 24),
              const SizedBox(width: 8),
              Text(
                'Revenus des 7 derniers jours',
                style: TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            currencyFormatter.format(_last7DaysRevenue),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Du ${DateFormat('dd/MM/yyyy').format(DateTime.now().subtract(const Duration(days: 7)))} au ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
            style: TextStyle(
              color: Colors.purple.shade700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Utilisateurs',
            _roleStats['USER'] ?? 0,
            Icons.person_outline,
            Colors.blue.shade100,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Administrateurs',
            _roleStats['ADMIN'] ?? 0,
            Icons.admin_panel_settings_outlined,
            Colors.red.shade100,
            Colors.red,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Créateurs',
            _roleStats['CONTENT_CREATOR'] ?? 0,
            Icons.create_outlined,
            Colors.green.shade100,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color bgColor, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChart() {
    final total = _roleStats.values.fold(0, (sum, value) => sum + value);
    return _buildChartContainer(
      'Répartition par Rôle',
      [
        ChartData('Utilisateurs', _roleStats['USER'] ?? 0, Colors.blue, total),
        ChartData('Administrateurs', _roleStats['ADMIN'] ?? 0, Colors.red, total),
        ChartData('Créateurs', _roleStats['CONTENT_CREATOR'] ?? 0, Colors.green, total),
      ],
    );
  }

  Widget _buildGenderChart() {
    final total = _genderStats.values.fold(0, (sum, value) => sum + value);
    return _buildChartContainer(
      'Répartition par Genre',
      [
        ChartData('Hommes', _genderStats['MAN'] ?? 0, Colors.blue, total),
        ChartData('Femmes', _genderStats['WOMAN'] ?? 0, Colors.pink, total),
        ChartData('Autres', _genderStats['OTHER'] ?? 0, Colors.purple, total),
      ],
    );
  }

  Widget _buildChartContainer(String title, List<ChartData> data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: data.map((item) => item.toPieChartSection()).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: data.map((item) => _buildLegendItem(item)).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(ChartData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: data.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${data.label} (${data.value})',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class ChartData {
  final String label;
  final int value;
  final Color color;
  final int total;

  ChartData(this.label, this.value, this.color, this.total);

  PieChartSectionData toPieChartSection() {
    final percentage = total > 0 ? (value / total * 100).round() : 0;
    return PieChartSectionData(
      color: color,
      value: value.toDouble(),
      title: '$percentage%',
      radius: 80,
      titleStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}
