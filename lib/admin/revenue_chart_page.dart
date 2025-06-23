import 'package:flutter/material.dart';
import 'revenue_chart.dart';

class RevenueChartPage extends StatelessWidget {
  const RevenueChartPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            RevenueChart(),
          ],
        ),
      ),
    );
  }
} 