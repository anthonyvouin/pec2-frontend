import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'legend_item.dart';

class PieChartGraph extends StatelessWidget {
  final Map<String, double> genderData;

  const PieChartGraph({super.key, required this.genderData});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'femme': Colors.pink,
      'homme': Colors.blue,
      'autre': Colors.grey,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 210,
          child: PieChart(
            PieChartData(
              sections: _buildSections(genderData, colors),
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          children: colors.entries.map((entry) {
            return LegendItem(
              color: entry.value,
              label: entry.key[0].toUpperCase() + entry.key.substring(1),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(Map<String, double> data, Map<String, Color> colors) {
    return data.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value,
        title: '${entry.value.toStringAsFixed(1)}%',
        color: colors[entry.key] ?? Colors.black,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}
