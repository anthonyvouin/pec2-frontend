import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'dart:math' show max;

class PostData {
  final DateTime date;
  final int count;
  final String label;

  PostData({
    required this.date,
    required this.count,
    required this.label,
  });
}

class CategoryData {
  final String id;
  final String name;
  final int count;
  final Color color;

  CategoryData({
    required this.id,
    required this.name,
    required this.count,
    required this.color,
  });
}

class PostsChart extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final bool showDateSelector;

  const PostsChart({
    Key? key,
    this.initialStartDate,
    this.initialEndDate,
    this.showDateSelector = true,
  }) : super(key: key);

  @override
  PostsChartState createState() => PostsChartState();
}

class PostsChartState extends State<PostsChart> {
  bool _isLoading = false;
  late DateTime _startDate;
  late DateTime _endDate;
  int _totalPosts = 0;
  String _error = '';
  List<PostData> _postsData = [];
  List<CategoryData> _categoryData = [];
  final List<Color> _categoryColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.indigo,
    Colors.cyan,
  ];
  
  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate ?? DateTime.now().subtract(const Duration(days: 30));
    _endDate = widget.initialEndDate ?? DateTime.now();
    initializeDateFormatting('fr_FR', null).then((_) => _fetchPostsStatistics());
  }

  void updateDateRange(DateTime startDate, DateTime endDate) {
    setState(() {
      _startDate = startDate;
      _endDate = endDate;
    });
    _fetchPostsStatistics();
  }

  Future<void> _fetchPostsStatistics() async {
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
        endpoint: '/posts/statistics',
        withAuth: true,
        queryParams: queryParams,
      );

      if (!response.success) {
        throw Exception(response.error ?? 'Échec de la récupération des statistiques de posts');
      }

      if (response.data == null) {
        setState(() {
          _totalPosts = 0;
          _postsData = [];
          _categoryData = [];
          _isLoading = false;
        });
        return;
      }

      final int totalPosts = (response.data['total'] as int?) ?? 0;
      
      final List<dynamic> dailyDataRaw = response.data['daily_data'] as List<dynamic>? ?? [];
      final List<PostData> postsData = [];
      
      for (var data in dailyDataRaw) {
        final String dateStr = data['date'] as String;
        final DateTime date = DateTime.parse(dateStr);
        final int count = data['count'] as int;
        
        postsData.add(PostData(
          date: date,
          count: count,
          label: DateFormat('d MMM', 'fr_FR').format(date),
        ));
      }

      final List<dynamic> categoryDataRaw = response.data['category_data'] as List<dynamic>? ?? [];
      final List<CategoryData> categoryData = [];
      
      for (int i = 0; i < categoryDataRaw.length; i++) {
        final data = categoryDataRaw[i];
        final String id = data['category_id'] as String;
        final String name = data['category_name'] as String;
        final int count = data['count'] as int;
        
        categoryData.add(CategoryData(
          id: id,
          name: name,
          count: count,
          color: _categoryColors[i % _categoryColors.length],
        ));
      }

      final List<PostData> completeData = _fillMissingDates(_startDate, _endDate, postsData);

      setState(() {
        _totalPosts = totalPosts;
        _postsData = completeData;
        _categoryData = categoryData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      debugPrint('Erreur lors de la récupération des statistiques de posts: $e');
    }
  }

  List<PostData> _fillMissingDates(DateTime start, DateTime end, List<PostData> existingData) {
    final List<PostData> result = [];
    final Map<String, PostData> existingDataMap = {};
    
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
        result.add(PostData(
          date: currentDate,
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
            if (widget.showDateSelector)
              if (isSmallScreen)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statistiques des posts',
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
                      'Statistiques des posts',
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
                'Statistiques des posts',
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
                  _buildPostsDisplay(),
                  const SizedBox(height: 24),
                  _buildPostsChart(isSmallScreen),
                  const SizedBox(height: 32),
                  _buildCategoriesBarChart(isSmallScreen),
                ],
              ),
          ],
        ),
      ),
    );
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
                _fetchPostsStatistics();
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
                _fetchPostsStatistics();
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
                _fetchPostsStatistics();
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
                _fetchPostsStatistics();
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

  Widget _buildPostsDisplay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Total des posts',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_totalPosts',
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

  Widget _buildPostsChart(bool isSmallScreen) {
    if (_postsData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('Aucune donnée disponible pour cette période'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: isSmallScreen ? 8.0 : 16.0, bottom: 8.0),
          child: const Text(
            'Posts par jour',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: isSmallScreen ? 250 : 300,
          child: LineChart(
            LineChartData(
              minY: 0,
              minX: 0,
              maxX: (_postsData.length - 1).toDouble(),
              maxY: _getMaxY(),
              gridData: const FlGridData(show: true),
              clipData: const FlClipData.all(),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: !isSmallScreen,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final int index = value.toInt();
                      if (index >= 0 && index < _postsData.length) {
                        int interval = isSmallScreen ? 7 : 5;
                        if (index % interval == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _postsData[index].label,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: isSmallScreen ? 10 : 12,
                              ),
                            ),
                          );
                        }
                      }
                      return const SizedBox.shrink();
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
                border: Border.all(color: Colors.grey.shade300),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: _postsData.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.count.toDouble());
                  }).toList(),
                  isCurved: true,
                  color: Theme.of(context).primaryColor,
                  barWidth: isSmallScreen ? 2 : 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: !isSmallScreen),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Colors.blueGrey.shade800,
                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      if (index >= 0 && index < _postsData.length) {
                        final data = _postsData[index];
                        return LineTooltipItem(
                          '${data.label}: ${data.count} posts',
                          const TextStyle(color: Colors.white),
                        );
                      }
                      return null;
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesBarChart(bool isSmallScreen) {
    if (_categoryData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('Aucune donnée de catégorie disponible'),
        ),
      );
    }

    List<CategoryData> displayedCategories = _categoryData;
    if (isSmallScreen && _categoryData.length > 5) {
      displayedCategories = List.from(_categoryData)
        ..sort((a, b) => b.count.compareTo(a.count))
        ..take(5).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: isSmallScreen ? 8.0 : 16.0, bottom: 16.0),
          child: const Text(
            'Posts par catégorie',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: isSmallScreen ? 250 : 300,
          child: Padding(
            padding: EdgeInsets.only(
              left: isSmallScreen ? 8.0 : 16.0, 
              right: isSmallScreen ? 16.0 : 32.0, 
              bottom: 16.0
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxCategoryCount() * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey.shade800,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final category = displayedCategories[groupIndex];
                      return BarTooltipItem(
                        '${category.name}\n${category.count} posts',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value >= displayedCategories.length) {
                          return const SizedBox.shrink();
                        }
                        
                        String categoryName = displayedCategories[value.toInt()].name;
                        int maxLength = isSmallScreen ? 6 : 10;
                        if (categoryName.length > maxLength) {
                          categoryName = categoryName.substring(0, maxLength - 2) + '...';
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            categoryName,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: isSmallScreen ? 9 : 11,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: !isSmallScreen,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == value.roundToDouble()) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
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
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                barGroups: displayedCategories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final category = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: category.count.toDouble(),
                        color: category.color,
                        width: isSmallScreen ? 15 : 25,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: _getMaxCategoryCount() * 1.2,
                          color: Colors.grey.shade100,
                        ),
                      ),
                    ],
                    showingTooltipIndicators: [0],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8.0 : 16.0, vertical: 8.0),
          child: Wrap(
            spacing: isSmallScreen ? 8.0 : 16.0,
            runSpacing: 8.0,
            children: displayedCategories.map((cat) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: cat.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${cat.name} (${cat.count})',
                    style: TextStyle(fontSize: isSmallScreen ? 10 : 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  double _getMaxY() {
    if (_postsData.isEmpty) return 10;
    
    int maxCount = _postsData.fold(0, (prev, curr) => max(prev, curr.count));
    
    return (maxCount + (maxCount * 0.2)).ceilToDouble();
  }

  double _getMaxCategoryCount() {
    if (_categoryData.isEmpty) return 10;
    
    int maxCount = _categoryData.fold(0, (prev, curr) => max(prev, curr.count));
    
    return maxCount.toDouble();
  }
} 