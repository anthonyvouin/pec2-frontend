import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'dart:math' show max;

class LikeData {
  final DateTime date;
  final int count;
  final String label;

  LikeData({
    required this.date,
    required this.count,
    required this.label,
  });
}

class MostLikedPost {
  final String postId;
  final String postName;
  final int likeCount;
  final Color color;

  MostLikedPost({
    required this.postId,
    required this.postName,
    required this.likeCount,
    required this.color,
  });
}

class LikesChart extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final bool showDateSelector;

  const LikesChart({
    Key? key,
    this.initialStartDate,
    this.initialEndDate,
    this.showDateSelector = true,
  }) : super(key: key);

  @override
  LikesChartState createState() => LikesChartState();
}

class LikesChartState extends State<LikesChart> {
  bool _isLoading = false;
  late DateTime _startDate;
  late DateTime _endDate;
  int _totalLikes = 0;
  String _error = '';
  List<LikeData> _likesData = [];
  List<MostLikedPost> _mostLikedPosts = [];
  final List<Color> _postColors = [
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
    initializeDateFormatting('fr_FR', null).then((_) => _fetchLikesStatistics());
  }

  void updateDateRange(DateTime startDate, DateTime endDate) {
    setState(() {
      _startDate = startDate;
      _endDate = endDate;
    });
    _fetchLikesStatistics();
  }

  Future<void> _fetchLikesStatistics() async {
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
        endpoint: '/likes/statistics',
        withAuth: true,
        queryParams: queryParams,
      );

      if (!response.success) {
        throw Exception(response.error ?? 'Échec de la récupération des statistiques de likes');
      }

      if (response.data == null) {
        setState(() {
          _totalLikes = 0;
          _likesData = [];
          _mostLikedPosts = [];
          _isLoading = false;
        });
        return;
      }

      final int totalLikes = (response.data['total'] as int?) ?? 0;
      
      // Traitement des données quotidiennes
      final List<dynamic> dailyDataRaw = response.data['daily_data'] as List<dynamic>? ?? [];
      final List<LikeData> likesData = [];
      
      for (var data in dailyDataRaw) {
        final String dateStr = data['date'] as String;
        final DateTime date = DateTime.parse(dateStr);
        final int count = data['count'] as int;
        
        likesData.add(LikeData(
          date: date,
          count: count,
          label: DateFormat('d MMM', 'fr_FR').format(date),
        ));
      }
      final List<dynamic> mostLikedPostsRaw = response.data['most_liked_posts'] as List<dynamic>? ?? [];
      final List<MostLikedPost> mostLikedPosts = [];
      
      for (int i = 0; i < mostLikedPostsRaw.length; i++) {
        final data = mostLikedPostsRaw[i];
        final String postId = data['post_id'] as String;
        final String postName = data['post_name'] as String;
        final int likeCount = data['like_count'] as int;
        
        mostLikedPosts.add(MostLikedPost(
          postId: postId,
          postName: postName,
          likeCount: likeCount,
          color: _postColors[i % _postColors.length],
        ));
      }

      final List<LikeData> completeData = _fillMissingDates(_startDate, _endDate, likesData);

      setState(() {
        _totalLikes = totalLikes;
        _likesData = completeData;
        _mostLikedPosts = mostLikedPosts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      debugPrint('Erreur lors de la récupération des statistiques de likes: $e');
    }
  }

  List<LikeData> _fillMissingDates(DateTime start, DateTime end, List<LikeData> existingData) {
    final List<LikeData> result = [];
    final Map<String, LikeData> existingDataMap = {};
    
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
        result.add(LikeData(
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
                      'Statistiques des likes',
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
                      'Statistiques des likes',
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
                'Statistiques des likes',
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
                  _buildLikesDisplay(),
                  const SizedBox(height: 24),
                  _buildLikesChart(isSmallScreen),
                  const SizedBox(height: 32),
                  _buildMostLikedPostsChart(isSmallScreen),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikesDisplay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Total des likes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_totalLikes',
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

  Widget _buildLikesChart(bool isSmallScreen) {
    if (_likesData.isEmpty) {
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
        const Text(
          'Évolution des likes par jour',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: isSmallScreen ? 250 : 300,
          child: LineChart(
            LineChartData(
              minY: 0,
              minX: 0,
              maxX: (_likesData.length - 1).toDouble(),
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
                      if (index >= 0 && index < _likesData.length) {
                        final data = _likesData[index];
                        return LineTooltipItem(
                          '${data.label}\n${data.count} like${data.count > 1 ? 's' : ''}',
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
                      if (index < 0 || index >= _likesData.length) {
                        return const Text('');
                      }

                      final int daysTotal = _likesData.length;
                      int interval = (daysTotal / (isSmallScreen ? 3 : 6)).ceil(); 
                      interval = max(1, interval);
                      
                      if (index % interval == 0 || index == _likesData.length - 1) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            _likesData[index].label,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 8 : 10,
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
                  spots: _likesData.asMap().entries.map((entry) {
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
                      if (_likesData[index].count > 0) {
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
        ),
      ],
    );
  }

  Widget _buildMostLikedPostsChart(bool isSmallScreen) {
    if (_mostLikedPosts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('Aucun post liké durant cette période'),
        ),
      );
    }

    // Limiter à 5 posts maximum pour l'affichage
    final displayedPosts = _mostLikedPosts.length > 5 
        ? _mostLikedPosts.sublist(0, 5) 
        : _mostLikedPosts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Posts les plus likés',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: isSmallScreen ? 250 : 300,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _getMaxLikeCount() * 1.2,
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.shade200,
                  strokeWidth: 1,
                  dashArray: [5, 5],
                ),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.black87,
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${displayedPosts[groupIndex].postName}\n${displayedPosts[groupIndex].likeCount} like${displayedPosts[groupIndex].likeCount > 1 ? 's' : ''}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      final int index = value.toInt();
                      if (index < 0 || index >= displayedPosts.length) {
                        return const Text('');
                      }
                      
                      String postName = displayedPosts[index].postName;
                      if (postName.length > 10) {
                        postName = '${postName.substring(0, 7)}...';
                      }
                      
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          postName,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 8 : 10,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
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
              barGroups: displayedPosts.asMap().entries.map((entry) {
                final index = entry.key;
                final post = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: post.likeCount.toDouble(),
                      color: post.color,
                      width: isSmallScreen ? 15 : 25,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: _getMaxLikeCount() * 1.2,
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
      ],
    );
  }

  double _getMaxY() {
    if (_likesData.isEmpty) return 10;
    
    double maxValue = 0;
    for (var data in _likesData) {
      if (data.count > maxValue) {
        maxValue = data.count.toDouble();
      }
    }
    
    return maxValue > 0 ? maxValue * 1.2 : 10;
  }

  double _getMaxLikeCount() {
    if (_mostLikedPosts.isEmpty) return 10;
    
    double maxValue = 0;
    for (var post in _mostLikedPosts) {
      if (post.likeCount > maxValue) {
        maxValue = post.likeCount.toDouble();
      }
    }
    
    return maxValue > 0 ? maxValue : 10;
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
                _fetchLikesStatistics();
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
                _fetchLikesStatistics();
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
                _fetchLikesStatistics();
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
                _fetchLikesStatistics();
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