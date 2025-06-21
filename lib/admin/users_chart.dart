import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'dart:math' show max;

class UserData {
  final DateTime date;
  final int count;
  final String label;

  UserData({
    required this.date,
    required this.count,
    required this.label,
  });
}

class UserStatsChart extends StatefulWidget {
  const UserStatsChart({Key? key}) : super(key: key);

  @override
  _UserStatsChartState createState() => _UserStatsChartState();
}

class _UserStatsChartState extends State<UserStatsChart> {
  bool _isLoading = false;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  int _totalUsers = 0;
  String _error = '';
  List<UserData> _userData = [];
  
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null).then((_) => _fetchStats());
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final Map<String, String> queryParams = {
        'start_date': DateFormat('yyyy-MM-dd').format(_startDate),
        'end_date': DateFormat('yyyy-MM-dd').format(_endDate),
      };

      final response = await ApiService().request(
        method: 'GET',
        endpoint: '/users/statistics',
        withAuth: true,
        queryParams: queryParams,
      );

      if (!response.success) {
        throw Exception(response.error ?? 'Échec de la récupération des statistiques');
      }

      // Vérifier si les données sont nulles
      if (response.data == null) {
        setState(() {
          _totalUsers = 0;
          _userData = [];
          _isLoading = false;
        });
        return;
      }

      final int totalUsers = (response.data['total'] as int?) ?? 0;
      
      // Traiter les données journalières
      final List<dynamic> dailyDataRaw = response.data['daily_data'] as List<dynamic>? ?? [];
      final List<UserData> userData = [];
      
      for (var data in dailyDataRaw) {
        final String dateStr = data['date'] as String;
        final DateTime date = DateTime.parse(dateStr);
        final int count = data['count'] as int;
        
        userData.add(UserData(
          date: date,
          count: count,
          label: DateFormat('d MMM', 'fr_FR').format(date).capitalize(),
        ));
      }

      // Ajouter des jours sans utilisateurs pour compléter le graphique
      final List<UserData> completeData = _fillMissingDates(_startDate, _endDate, userData);

      setState(() {
        _totalUsers = totalUsers;
        _userData = completeData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      debugPrint('Erreur lors de la récupération des statistiques: $e');
    }
  }

  List<UserData> _fillMissingDates(DateTime start, DateTime end, List<UserData> existingData) {
    final List<UserData> result = [];
    final Map<String, UserData> existingDataMap = {};
    
    // Créer un map des données existantes pour faciliter la recherche
    for (var data in existingData) {
      final String dateKey = DateFormat('yyyy-MM-dd').format(data.date);
      existingDataMap[dateKey] = data;
    }
    
    // Ajouter une entrée pour chaque jour de la période
    for (int i = 0; i <= end.difference(start).inDays; i++) {
      final DateTime currentDate = start.add(Duration(days: i));
      final String dateKey = DateFormat('yyyy-MM-dd').format(currentDate);
      
      if (existingDataMap.containsKey(dateKey)) {
        // Utiliser les données existantes
        result.add(existingDataMap[dateKey]!);
      } else {
        // Créer une entrée avec count 0
        result.add(UserData(
          date: currentDate,
          count: 0,
          label: DateFormat('d MMM', 'fr_FR').format(currentDate).capitalize(),
        ));
      }
    }
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Statistiques des inscriptions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildDateRangeControls(),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error.isNotEmpty)
              Center(
                child: Text(
                  'Erreur: $_error',
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else
              Column(
                children: [
                  _buildUserDisplay(),
                  const SizedBox(height: 24),
                  _buildUserChart(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDisplay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Total des inscriptions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_totalUsers',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF6C3FFE),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Du ${DateFormat('dd/MM/yyyy').format(_startDate)} au ${DateFormat('dd/MM/yyyy').format(_endDate)}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserChart() {
    if (_userData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('Aucune donnée disponible pour cette période'),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          minY: 0,
          minX: 0,
          maxX: (_userData.length - 1).toDouble(),
          maxY: _getMaxY(),
          gridData: const FlGridData(show: true),
          clipData: const FlClipData.all(),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.black87,
              tooltipRoundedRadius: 8,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((touchedSpot) {
                  final index = touchedSpot.x.toInt();
                  if (index >= 0 && index < _userData.length) {
                    final data = _userData[index];
                    return LineTooltipItem(
                      '${data.label}\n${data.count} utilisateur${data.count > 1 ? 's' : ''}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                  return null;
                }).toList();
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value >= 0 && value == value.roundToDouble()) {
                    return Text(value.toInt().toString());
                  }
                  return const Text('');
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final int index = value.toInt();
                  if (index < 0 || index >= _userData.length) {
                    return const Text('');
                  }

                  // Afficher seulement certaines dates pour éviter l'encombrement
                  final int daysTotal = _userData.length;
                  int interval = (daysTotal / 6).ceil(); // Environ 6 étiquettes
                  interval = max(1, interval);
                  
                  if (index % interval == 0 || index == _userData.length - 1) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        _userData[index].label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              left: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: _userData.asMap().entries.map((entry) {
                final count = entry.value.count < 0 ? 0 : entry.value.count;
                return FlSpot(entry.key.toDouble(), count.toDouble());
              }).toList(),
              isCurved: true,
              preventCurveOverShooting: true,
              color: const Color(0xFF6C3FFE),
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF6C3FFE).withOpacity(0.2),
                cutOffY: 0,
                applyCutOffY: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getMaxY() {
    if (_userData.isEmpty) return 10;
    
    double maxValue = 0;
    for (var data in _userData) {
      if (data.count > maxValue) {
        maxValue = data.count.toDouble();
      }
    }
    
    // Ajouter un peu d'espace au-dessus de la valeur maximale
    return maxValue > 0 ? maxValue * 1.2 : 10;
  }

  Widget _buildDateRangeControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDatePicker(
          label: 'Date de début',
          selectedDate: _startDate,
          onDateSelected: (date) {
            if (date != null && date.isBefore(_endDate)) {
              setState(() {
                _startDate = date;
              });
              _fetchStats();
            } else if (date != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('La date de début doit être avant la date de fin')),
              );
            }
          },
        ),
        const SizedBox(width: 16),
        _buildDatePicker(
          label: 'Date de fin',
          selectedDate: _endDate,
          onDateSelected: (date) {
            if (date != null && date.isAfter(_startDate)) {
              setState(() {
                _endDate = date;
              });
              _fetchStats();
            } else if (date != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('La date de fin doit être après la date de début')),
              );
            }
          },
        ),
      ],
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
            child: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
          ),
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
