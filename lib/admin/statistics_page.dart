import 'package:flutter/material.dart';
import 'users_chart.dart';
import 'posts_chart.dart';
import 'revenue_chart.dart';
import 'likes_chart.dart';
import 'package:intl/intl.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  final GlobalKey<UserStatsChartState> _userChartKey = GlobalKey();
  final GlobalKey<PostsChartState> _postsChartKey = GlobalKey();
  final GlobalKey<RevenueChartState> _revenueChartKey = GlobalKey();
  final GlobalKey<LikesChartState> _likesChartKey = GlobalKey();

  void _updateDateRange() {
    _userChartKey.currentState?.updateDateRange(_startDate, _endDate);
    _postsChartKey.currentState?.updateDateRange(_startDate, _endDate);
    _revenueChartKey.currentState?.updateDateRange(_startDate, _endDate);
    _likesChartKey.currentState?.updateDateRange(_startDate, _endDate);
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 900;
    
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Sélecteur de dates commun
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Période',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    isSmallScreen
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDatePicker(
                                label: 'Date de début',
                                selectedDate: _startDate,
                                onDateSelected: (date) {
                                  if (date != null && date.isBefore(_endDate)) {
                                    setState(() {
                                      _startDate = date;
                                    });
                                    _updateDateRange();
                                  } else if (date != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('La date de début doit être avant la date de fin')),
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              _buildDatePicker(
                                label: 'Date de fin',
                                selectedDate: _endDate,
                                onDateSelected: (date) {
                                  if (date != null && date.isAfter(_startDate)) {
                                    setState(() {
                                      _endDate = date;
                                    });
                                    _updateDateRange();
                                  } else if (date != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('La date de fin doit être après la date de début')),
                                    );
                                  }
                                },
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _buildDatePicker(
                                  label: 'Date de début',
                                  selectedDate: _startDate,
                                  onDateSelected: (date) {
                                    if (date != null && date.isBefore(_endDate)) {
                                      setState(() {
                                        _startDate = date;
                                      });
                                      _updateDateRange();
                                    } else if (date != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('La date de début doit être avant la date de fin')),
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDatePicker(
                                  label: 'Date de fin',
                                  selectedDate: _endDate,
                                  onDateSelected: (date) {
                                    if (date != null && date.isAfter(_startDate)) {
                                      setState(() {
                                        _endDate = date;
                                      });
                                      _updateDateRange();
                                    } else if (date != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('La date de fin doit être après la date de début')),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Section des statistiques d'utilisateurs
            const Text(
              'Statistiques des inscriptions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            UserStatsChart(
              key: _userChartKey,
              initialStartDate: _startDate,
              initialEndDate: _endDate,
              showDateSelector: false,
            ),
            const SizedBox(height: 32),
            
            // Section des statistiques de posts
            const Text(
              'Statistiques des publications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            PostsChart(
              key: _postsChartKey,
              initialStartDate: _startDate,
              initialEndDate: _endDate,
              showDateSelector: false,
            ),
            const SizedBox(height: 32),
            
            // Section des statistiques de likes
            const Text(
              'Statistiques des likes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LikesChart(
              key: _likesChartKey,
              initialStartDate: _startDate,
              initialEndDate: _endDate,
              showDateSelector: false,
            ),
            const SizedBox(height: 32),
            
            // Section des statistiques de revenus
            const Text(
              'Statistiques des revenus',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            RevenueChart(
              key: _revenueChartKey,
              initialStartDate: _startDate,
              initialEndDate: _endDate,
              showDateSelector: false,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime selectedDate,
    required Function(DateTime?) onDateSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            onDateSelected(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                const Icon(Icons.calendar_today, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 