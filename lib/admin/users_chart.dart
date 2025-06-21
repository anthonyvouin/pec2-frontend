import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'dart:math' show max;

class _UserStatsResponse {
  final String period;
  final int count;
  final String label;
  final DateTime date;

  _UserStatsResponse({
    required this.period,
    required this.count,
    required this.label,
    required this.date,
  });

  factory _UserStatsResponse.fromJson(Map<String, dynamic> json) {
    final period = json['period'] as String;
    final DateTime date = DateTime.parse(period);
    
    // Formater correctement le label de date
    String formattedLabel;
    if (period.length <= 7) { // Format YYYY-MM pour les données annuelles
      formattedLabel = DateFormat('MMM', 'fr_FR').format(date).capitalize();
    } else { // Format YYYY-MM-DD pour les données mensuelles
      formattedLabel = DateFormat('d MMM', 'fr_FR').format(date).capitalize();
    }
    
    return _UserStatsResponse(
      period: period,
      count: json['count'] as int,
      label: formattedLabel,
      date: date,
    );
  }
}

class UserStatsChart extends StatefulWidget {
  const UserStatsChart({Key? key}) : super(key: key);

  @override
  _UserStatsChartState createState() => _UserStatsChartState();
}

class _UserStatsChartState extends State<UserStatsChart> {
  bool _isLoading = false;
  String _selectedFilter = 'month';
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  List<_UserStatsResponse> _statsData = [];
  String _error = '';

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
        'filter': _selectedFilter,
        'year': _selectedYear.toString(),
      };

      if (_selectedFilter == 'month') {
        queryParams['month'] = _selectedMonth.toString();
      }

      final response = await ApiService().request(
        method: 'GET',
        endpoint: '/users/statistics',
        withAuth: true,
        queryParams: queryParams,
      );

      if (!response.success) {
        throw Exception(response.error ?? 'Échec de la récupération des statistiques');
      }

      final List<dynamic> data = response.data as List<dynamic>;
      
      // Convertir les données et éliminer les doublons par date
      final Map<String, _UserStatsResponse> uniqueDataMap = {};
      for (var item in data) {
        final stat = _UserStatsResponse.fromJson(item as Map<String, dynamic>);
        final dateKey = DateFormat('yyyy-MM-dd').format(stat.date);
        uniqueDataMap[dateKey] = stat;
      }
      
      // Si on est en vue mensuelle, s'assurer d'avoir tous les jours du mois
      List<_UserStatsResponse> processedData = [];
      if (_selectedFilter == 'month') {
        final firstDay = DateTime(_selectedYear, _selectedMonth, 1);
        final lastDay = DateTime(_selectedYear, _selectedMonth + 1, 0); // Dernier jour du mois
        
        // Créer une entrée pour chaque jour du mois
        for (int day = 1; day <= lastDay.day; day++) {
          final currentDate = DateTime(_selectedYear, _selectedMonth, day);
          final dateKey = DateFormat('yyyy-MM-dd').format(currentDate);
          
          if (uniqueDataMap.containsKey(dateKey)) {
            processedData.add(uniqueDataMap[dateKey]!);
          } else {
            // Ajouter une entrée avec count=0 pour les jours sans données
            processedData.add(_UserStatsResponse(
              period: dateKey,
              count: 0,
              label: DateFormat('d MMM', 'fr_FR').format(currentDate).capitalize(),
              date: currentDate,
            ));
          }
        }
      } else {
        // Pour les données annuelles, utiliser les données uniques
        processedData = uniqueDataMap.values.toList();
      }
      
      setState(() {
        // Trier les données par date
        processedData.sort((a, b) => a.date.compareTo(b.date));
        _statsData = processedData;
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
                _buildFilterControls(),
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
            else if (_statsData.isEmpty)
              const Center(
                child: Text('Aucune donnée disponible pour cette période'),
              )
            else
              SizedBox(
                height: 300,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    minX: 0,
                    maxY: _getMaxY(),
                    maxX: (_statsData.length - 1).toDouble(),
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
                            if (index >= 0 && index < _statsData.length) {
                              return LineTooltipItem(
                                '${_statsData[index].label}\n${_statsData[index].count} utilisateurs',
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
                          interval: 1, // Chaque point a une position distincte
                          getTitlesWidget: (value, meta) {
                            final int index = value.toInt();
                            if (index < 0 || index >= _statsData.length) {
                              return const Text('');
                            }

                            // Logique pour déterminer quelles dates afficher
                            if (_selectedFilter == 'month') {
                              // Pour les mois, afficher le 1er, 6e, 11e, 16e, 21e, 26e et dernier jour
                              final int day = _statsData[index].date.day;
                              
                              // Afficher uniquement certains jours spécifiques pour éviter les doublons
                              final List<int> daysToShow = [1, 6, 11, 16, 21, 26];
                              final bool isLastDay = index == _statsData.length - 1;
                              
                              if (daysToShow.contains(day) || isLastDay) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    _statsData[index].label,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }
                            } else {
                              // Pour les années, afficher janvier, avril, juillet, octobre et décembre
                              final int month = _statsData[index].date.month;
                              final List<int> monthsToShow = [1, 4, 7, 10, 12];
                              
                              if (monthsToShow.contains(month) || index == _statsData.length - 1) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    _statsData[index].label,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }
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
                        spots: _statsData.asMap().entries.map((entry) {
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButton<String>(
          value: _selectedFilter,
          items: const [
            DropdownMenuItem(value: 'month', child: Text('Par mois')),
            DropdownMenuItem(value: 'year', child: Text('Par année')),
          ],
          onChanged: (value) {
            if (value != null && value != _selectedFilter) {
              setState(() {
                _selectedFilter = value;
              });
              _fetchStats();
            }
          },
        ),
        const SizedBox(width: 16),
        DropdownButton<int>(
          value: _selectedYear,
          items: List.generate(5, (index) {
            final year = DateTime.now().year - index;
            return DropdownMenuItem(value: year, child: Text(year.toString()));
          }),
          onChanged: (value) {
            if (value != null && value != _selectedYear) {
              setState(() {
                _selectedYear = value;
              });
              _fetchStats();
            }
          },
        ),
        if (_selectedFilter == 'month') ...[
          const SizedBox(width: 16),
          DropdownButton<int>(
            value: _selectedMonth,
            items: List.generate(12, (index) {
              return DropdownMenuItem(
                value: index + 1,
                child: Text(
                  DateFormat('MMMM', 'fr_FR')
                    .format(DateTime(2024, index + 1))
                    .capitalize(),
                ),
              );
            }),
            onChanged: (value) {
              if (value != null && value != _selectedMonth) {
                setState(() {
                  _selectedMonth = value;
                });
                _fetchStats();
              }
            },
          ),
        ],
      ],
    );
  }

  double _getMaxY() {
    if (_statsData.isEmpty) return 10;
    
    double maxValue = 0;
    for (var stat in _statsData) {
      if (stat.count > maxValue) {
        maxValue = stat.count.toDouble();
      }
    }
    
    return maxValue * 1.2;
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
