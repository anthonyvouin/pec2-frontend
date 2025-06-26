import 'package:flutter/material.dart';
import 'users_chart.dart';
import 'posts_chart.dart';
import 'revenue_chart.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
   
            const SizedBox(height: 24),
            
            // Section des statistiques d'utilisateurs
    
            const SizedBox(height: 16),
            const UserStatsChart(),
            const SizedBox(height: 32),
            
        
            const SizedBox(height: 16),
            const PostsChart(),
            const SizedBox(height: 32),
            
         
            const SizedBox(height: 16),
            const RevenueChart(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
} 