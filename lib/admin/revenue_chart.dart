import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class RevenueData {
  final DateTime date;
  final int amount;
  final String label;

  RevenueData({
    required this.date,
    required this.amount,
    required this.label,
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

      setState(() {
        _totalRevenue = (response.data['total'] as int) ~/ 100;
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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                _buildDateRangeControls(),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error.isNotEmpty)
              Center(
                child: Text(
                  'Error: $_error',
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else
              _buildRevenueDisplay(),
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
            'From ${DateFormat('dd/MM/yyyy').format(_startDate)} to ${DateFormat('dd/MM/yyyy').format(_endDate)}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeControls() {
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
        ),
      ],
    );
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