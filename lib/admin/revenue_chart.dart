import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'dart:math' show max;

class RevenueData {
  final DateTime date;
  final int amount;
  final String label;
  final int count;

  RevenueData({
    required this.date,
    required this.amount,
    required this.label,
    this.count = 0,
  });
}

class RevenueChart extends StatefulWidget {
  const RevenueChart({Key? key}) : super(key: key);

  @override
  _RevenueChartState createState() => _RevenueChartState();
}

class _RevenueChartState extends State<RevenueChart> {
  bool _isLoading = false;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  int _totalRevenue = 0;
  String _error = '';
  List<RevenueData> _revenueData = [];
  final currencyFormatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
  
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null).then((_) => _fetchRevenue());
  }

  Future<void> _fetchRevenue() async {
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
        endpoint: '/subscriptions/revenue',
        withAuth: true,
        queryParams: queryParams,
      );

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to retrieve revenue data');
      }

      if (response.data == null) {
        setState(() {
          _totalRevenue = 0;
          _revenueData = [];
          _isLoading = false;
        });
        return;
      }

      final int totalRevenue = (response.data['total'] as int?) ?? 0;
      final int revenueInEuros = totalRevenue ~/ 100;
      
      final List<dynamic> dailyDataRaw = response.data['daily_data'] as List<dynamic>? ?? [];
      final List<RevenueData> revenueData = [];
      
      for (var data in dailyDataRaw) {
        final String dateStr = data['date'] as String;
        final DateTime date = DateTime.parse(dateStr);
        final int amount = (data['amount'] as int) ~/ 100; 
        final int count = data['count'] as int;
        
        revenueData.add(RevenueData(
          date: date,
          amount: amount,
          count: count,
          label: DateFormat('d MMM', 'fr_FR').format(date),
        ));
      }

      final List<RevenueData> completeData = _fillMissingDates(_startDate, _endDate, revenueData);

      setState(() {
        _totalRevenue = revenueInEuros;
        _revenueData = completeData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      debugPrint('Error fetching revenue data: $e');
    }
  }

  List<RevenueData> _fillMissingDates(DateTime start, DateTime end, List<RevenueData> existingData) {
    final List<RevenueData> result = [];
    final Map<String, RevenueData> existingDataMap = {};
    
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
        result.add(RevenueData(
          date: currentDate,
          amount: 0,
          count: 0,
          label: DateFormat('d MMM', 'fr_FR').format(currentDate),
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
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSmallScreen)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistiques des revenus',
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
                    'Statistiques des revenus',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildDateRangeControls(isSmallScreen),
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
                  _buildRevenueDisplay(),
                  const SizedBox(height: 24),
                  _buildRevenueChart(isSmallScreen),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueDisplay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Total des revenus',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormatter.format(_totalRevenue),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
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

  Widget _buildRevenueChart(bool isSmallScreen) {
    if (_revenueData.isEmpty) {
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
          maxX: (_revenueData.length - 1).toDouble(),
          maxY: _getMaxY(),
          gridData: const FlGridData(show: true),
          clipData: const FlClipData.all(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: !isSmallScreen, 
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value >= 0 && value == value.roundToDouble()) {
                    return Text(
                      currencyFormatter.format(value).split(',')[0], 
                      style: const TextStyle(fontSize: 10),
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
                  if (index < 0 || index >= _revenueData.length) {
                    return const Text('');
                  }

                  final int daysTotal = _revenueData.length;
                  int interval = (daysTotal / (isSmallScreen ? 3 : 6)).ceil(); 
                  interval = max(1, interval);
                  
                  if (index % interval == 0 || index == _revenueData.length - 1) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        _revenueData[index].label,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 8 : 10,
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
              spots: _revenueData.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.amount.toDouble());
              }).toList(),
              isCurved: true,
              preventCurveOverShooting: true,
              color: Theme.of(context).primaryColor,
              barWidth: isSmallScreen ? 2 : 3,
              dotData: FlDotData(show: !isSmallScreen), 
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                cutOffY: 0,
                applyCutOffY: true,
              ),
            ),
          ],
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
                  if (index >= 0 && index < _revenueData.length) {
                    final data = _revenueData[index];
                    final String countText = data.count > 0 
                        ? '\n${data.count} transaction${data.count > 1 ? 's' : ''}' 
                        : '';
                    return LineTooltipItem(
                      '${data.label}\n${currencyFormatter.format(data.amount)}$countText',
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
        ),
      ),
    );
  }

  double _getMaxY() {
    if (_revenueData.isEmpty) return 10;
    
    double maxValue = 0;
    for (var data in _revenueData) {
      if (data.amount > maxValue) {
        maxValue = data.amount.toDouble();
      }
    }
    
    return maxValue > 0 ? maxValue * 1.2 : 10;
  }

  Widget _buildDateRangeControls(bool isSmallScreen) {
    if (isSmallScreen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDatePicker(
            label: 'Date de début',
            selectedDate: _startDate,
            onDateSelected: (date) {
              if (date != null && date.isBefore(_endDate)) {
                setState(() {
                  _startDate = date;
                });
                _fetchRevenue();
              } else if (date != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('La date de début doit être avant la date de fin')),
                );
              }
            },
            isSmallScreen: isSmallScreen,
          ),
          const SizedBox(height: 12),
          _buildDatePicker(
            label: 'Date de fin',
            selectedDate: _endDate,
            onDateSelected: (date) {
              if (date != null && date.isAfter(_startDate)) {
                setState(() {
                  _endDate = date;
                });
                _fetchRevenue();
              } else if (date != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('La date de fin doit être après la date de début')),
                );
              }
            },
            isSmallScreen: isSmallScreen,
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
                _fetchRevenue();
              } else if (date != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('La date de début doit être avant la date de fin')),
                );
              }
            },
            isSmallScreen: isSmallScreen,
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
                _fetchRevenue();
              } else if (date != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('La date de fin doit être après la date de début')),
                );
              }
            },
            isSmallScreen: isSmallScreen,
          ),
        ],
      );
    }
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime selectedDate,
    required Function(DateTime?) onDateSelected,
    required bool isSmallScreen,
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
            width: isSmallScreen ? double.infinity : null,
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