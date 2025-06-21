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
          children: [
            const Text(
              'Aperçu des revenus',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Suivez les revenus de votre plateforme au fil du temps',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            const RevenueChart(),
            const SizedBox(height: 24),
            const Text(
              'Instructions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Sélectionnez une période pour voir les revenus pour cette période\n'
              '• Les revenus sont calculés à partir de tous les paiements de souscription réussis\n'
              '• Les données sont affichées dans votre devise locale',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
} 