import 'package:firstflutterapp/components/title/title_onlyflick.dart';
import 'package:firstflutterapp/interfaces/creator_advenced_stats.dart';
import 'package:firstflutterapp/theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';
import '../../services/api_service.dart';
import '../../services/toast_service.dart';

class Advencedview extends StatefulWidget {
  const Advencedview({super.key});

  @override
  State<Advencedview> createState() => _AdvencedviewState();
}

class _AdvencedviewState extends State<Advencedview> {
  String _selectedOption = '7 derniers jours';
  DateTimeRange? _selectedRange;
  bool _isLoading = false;
  CreatorAdvencedStats? _userStats;
  final ApiService _apiService = ApiService();
  bool _isGroupingByDay = true;

  getDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _updateDateRange(_selectedOption);
  }

  Future<void> _getData() async {
    setState(() {
      _isLoading = true;
    });
    ApiResponse request = await _apiService.request(
      method: 'Get',
      endpoint:
          '/content-creators/stats-advenced/creator?start=${getDate(_selectedRange!.start)}&end=${getDate(_selectedRange!.end)}',
    );
    if (request.success) {
      setState(() {
        _userStats = CreatorAdvencedStats.fromJson(request.data);
      });
    } else {
      ToastService.showToast(
        'Erreur lors de la récupération des données',
        ToastificationType.error,
      );
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _updateDateRange(String option) async {
    DateTime now = DateTime.now();

    DateTime start;
    DateTime end;

    if (option == '7 derniers jours') {
      end = DateTime(now.year, now.month, now.day);
      start = end.subtract(Duration(days: 6));
      _isGroupingByDay = true;
    } else if (option == 'Mois en cours') {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0);
      _isGroupingByDay = true;
    } else if (option == 'Année en cours') {
      start = DateTime(now.year, 1, 1);
      end = DateTime(now.year, 12, 31);
      _isGroupingByDay = false;
    } else if (option == 'Personnalisée') {
      DateTimeRange? picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        start = picked.start;
        end = picked.end;
        _isGroupingByDay = end.difference(start).inDays <= 32;
      } else {
        return;
      }
    } else {
      end = DateTime(now.year, now.month, now.day);
      start = end.subtract(Duration(days: 6));
      _isGroupingByDay = true;
    }

    setState(() {
      _selectedRange = DateTimeRange(start: start, end: end);
    });
    _getData();
  }

  Widget _periodSelector(displayRange) {
    return Center(
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          DropdownButton<String>(
            value: _selectedOption,
            items:
                <String>[
                  '7 derniers jours',
                  'Mois en cours',
                  'Année en cours',
                  'Personnalisée',
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
            onChanged: (String? newValue) async {
              if (newValue != null) {
                setState(() {
                  _selectedOption = newValue;
                });
                _updateDateRange(newValue);
              }
            },
          ),
          SizedBox(width: 16),
          Text(displayRange),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String displayRange =
        _selectedRange == null
            ? 'Aucune plage sélectionnée'
            : '${DateFormat('dd MMMM yyyy', 'fr_FR').format(_selectedRange!.start)} '
                '→ ${DateFormat('dd MMMM yyyy', 'fr_FR').format(_selectedRange!.end)}';
    if (_userStats != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _periodSelector(displayRange),
            const SizedBox(height: 16),
            !_isLoading
                ? (_userStats != null
                    ? _containerStats()
                    : const Text("Vous n'avez pas d'abonnés"))
                : const Text("Chargement des données..."),
          ],
        ),
      );
    } else {
      return Text('chargement des donnees');
    }
  }

  Widget _containerStats() {
    return Column(children: [_graph(_userStats!.payments, 'Revenues')]);
  }

  List<FlSpot> _convertToSpots(List<Revenues> data) {
    return data.asMap().entries.map((entry) {
      int index = entry.key;
      double value = entry.value.total;
      return FlSpot(index.toDouble(), value);
    }).toList();
  }

  Widget _graph(List<Revenues> data, String title) {
    final spots = _convertToSpots(data);

    final double maxY = spots
        .map((e) => e.y)
        .fold(0, (prev, e) => e > prev ? e : prev);

    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              TitleOnlyFlick(text: title),
              SizedBox(
                height: 300,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: maxY + 10,
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index < 0 || index >= data.length)
                              return Container();

                            String label = data[index].month;

                            if (_isGroupingByDay) {
                              DateTime date =
                                  DateTime.tryParse(label) ?? DateTime.now();
                              label = DateFormat(
                                'dd MMM',
                                'fr_FR',
                              ).format(date);
                            } else {
                              DateTime date =
                                  DateTime.tryParse("$label-01") ??
                                  DateTime.now();
                              label = DateFormat(
                                'MMM yyyy',
                                'fr_FR',
                              ).format(date);
                            }

                            return Text(label, style: TextStyle(fontSize: 10));
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 10,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}€',
                              style: TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: false,
                        color: AppTheme.darkColor,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
