import 'package:flutter/material.dart';
import 'posts_chart.dart';

class PostsChartPage extends StatelessWidget {
  const PostsChartPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            PostsChart(),
          ],
        ),
      ),
    );
  }
} 