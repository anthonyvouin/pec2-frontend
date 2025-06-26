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
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final bool showDateSelector;

  const UserStatsChart({
    Key? key, 
    this.initialStartDate,
    this.initialEndDate,
    this.showDateSelector = true,
  }) : super(key: key);

  @override
  UserStatsChartState createState() => UserStatsChartState();
}

class UserStatsChartState extends State<UserStatsChart> {
  bool _isLoading = false;
  late DateTime _startDate;
  late DateTime _endDate;
  int _totalUsers = 0;
  String _error = '';
  List<UserData> _userData = [];
  
  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate ?? DateTime.now().subtract(const Duration(days: 30));
    _endDate = widget.initialEndDate ?? DateTime.now();
    initializeDateFormatting('fr_FR', null).then((_) => _fetchStats());
  }

  void updateDateRange(DateTime startDate, DateTime endDate) {
    setState(() {
      _startDate = startDate;
      _endDate = endDate;
    });
    _fetchStats();
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

      if (response.data == null) {
        setState(() {
          _totalUsers = 0;
          _userData = [];
          _isLoading = false;
        });
        return;
      }

      final int totalUsers = (response.data['total'] as int?) ?? 0;
      
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
    
    for (var data in existingData) {
      final String dateKey = DateFormat('yyyy-MM-dd').format(data.date);
      existingDataMap[dateKey] = data;
    }
    
    for (int i = 0; i <= end.difference(start).inDays; i++) {
      final DateTime currentDate = start.add(Duration(days: i));
      final String dateKey = DateFormat('yyyy-MM-dd').format(currentDate);
      
      if (existingDataMap.containsKey(dateKey)) {
        result.add(existingDataMap[dateKey]!);
      } else {
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
    final bool isSmallScreen = MediaQuery.of(context).size.width < 900;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showDateSelector)
              if (isSmallScreen)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statistiques des inscriptions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDateRangeControls(isSmallScreen),
                  ],
                )
              else
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
                    _buildDateRangeControls(isSmallScreen),
                  ],
                ),
            if (!widget.showDateSelector)
              const Text(
                'Statistiques des inscriptions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
                  _buildUserChart(isSmallScreen),
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

  Widget _buildUserChart(bool isSmallScreen) {
    if (_userData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('Aucune donnée disponible pour cette période'),
        ),
      );
    }

    return SizedBox(
      height: isSmallScreen ? 250 : 300,
      child: LineChart(
        LineChartData(
          minY: 0,
          minX: 0,
          maxX: (_userData.length - 1).toDouble(),
          maxY: _getMaxY(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: !isSmallScreen, 
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ),
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
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    );
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

                  final int daysTotal = _userData.length;
                  int interval = isSmallScreen 
                      ? (daysTotal / 4).ceil() 
                      : (daysTotal / 6).ceil(); 
                  interval = max(1, interval);
                  
                  if (index % interval == 0 || index == _userData.length - 1) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        _userData[index].label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
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
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  if (_userData[index].count > 0) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: const Color(0xFF6C3FFE),
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  }
                  return FlDotCirclePainter(
                    radius: 0,
                    color: Colors.transparent,
                    strokeWidth: 0,
                    strokeColor: Colors.transparent,
                  );
                },
              ),
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
    
    return maxValue > 0 ? maxValue * 1.2 : 10;
  }

  Widget _buildDateRangeControls(bool isSmallScreen) {
    if (isSmallScreen) {
      return Column(
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
                _fetchStats();
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
    } else {
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
