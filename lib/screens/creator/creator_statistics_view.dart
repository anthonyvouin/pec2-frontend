import 'package:firstflutterapp/components/graph/pie_chart_graph.dart';
import 'package:firstflutterapp/components/subscriber/subscriberList.dart';
import 'package:firstflutterapp/interfaces/user_stats.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:firstflutterapp/services/toast_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';

class CreatorStatisticsView extends StatefulWidget {
  const CreatorStatisticsView({super.key});

  @override
  State<CreatorStatisticsView> createState() => _CreatorStatisticsViewState();
}

class _CreatorStatisticsViewState extends State<CreatorStatisticsView> {
  String _selectedOption = '7 derniers jours';
  DateTimeRange? _selectedRange;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  UserStats? _userStats;

  void _updateDateRange(String option) async {
    DateTime now = DateTime.now();

    if (option == '7 derniers jours') {
      DateTime end = DateTime(now.year, now.month, now.day);
      DateTime start = end.subtract(Duration(days: 6)); // 7 jours au total
      setState(() {
        _selectedRange = DateTimeRange(start: start, end: end);
      });
      ;
    } else if (option == 'Mois en cours') {
      DateTime start = DateTime(now.year, now.month, 1);
      DateTime end = DateTime(now.year, now.month + 1, 0);
      setState(() {
        _selectedRange = DateTimeRange(start: start, end: end);
      });
    } else if (option == 'Année en cours') {
      DateTime start = DateTime(now.year, 1, 1);
      DateTime end = DateTime(now.year, 12, 31);
      setState(() {
        _selectedRange = DateTimeRange(start: start, end: end);
      });
    } else if (option == 'Personnalisée') {
      DateTimeRange? picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        setState(() {
          _selectedRange = picked;
        });
      }
    }
  }

  Future<void> _getData() async {
    setState(() {
      _isLoading = true;
    });
    ApiResponse request = await _apiService.request(
      method: 'Get',
      endpoint: '/users/stats/creator',
    );
    if (request.success) {
      setState(() {
        _userStats = UserStats.fromJson(request.data);
      });
    }else{
      ToastService.showToast('Erreur lors de la récupération des données', ToastificationType.error);
    }
    setState(() {
      _isLoading = false;
    });
    print(request);
  }

  @override
  void initState() {
    super.initState();
    _updateDateRange(_selectedOption);
    _getData();
  }

  @override
  Widget build(BuildContext context) {
    String displayRange =
        _selectedRange == null
            ? 'Aucune plage sélectionnée'
            : '${DateFormat('dd MMMM yyyy', 'fr_FR').format(_selectedRange!.start)} '
                '→ ${DateFormat('dd MMMM yyyy', 'fr_FR').format(_selectedRange!.end)}';

    return Scaffold(
      appBar: AppBar(title: Text("Statistiques")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _periodSelector(displayRange),
            const SizedBox(height: 16),
            !_isLoading
                ? (_userStats != null
                ? _firstLine()
                : const Text("Aucune donnée"))
                : const Text("Chargement des données..."),
          ],
        ),
      ),
    );
  }

  void _showSubscriberModal(BuildContext context, bool showSubscriber) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: DefaultTabController(
            length: 2,
            initialIndex: 0,
            child: Column(
              children: [
                const TabBar(tabs: [Tab(text: 'Abonnés')]),
                Expanded(
                  child: TabBarView(
                    children: [
                      SubscribersList(subscribers: _userStats!.subscribers),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
            onChanged: (String? newValue) {
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

  Widget _firstLine() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: [
          SizedBox(width: 300, child: _getSubscribers()),
          SizedBox(width: 300, child: _genderGraph()),
          SizedBox(width: 300, child: _genderGraph()),
        ],
      ),
    );
  }

  Widget _getSubscribers() {
    return GestureDetector(
      onTap: () => _showSubscriberModal(context, true),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 16),
                    Text("Abonnés", style: TextStyle(fontSize: 20)),
                    SizedBox(height: 16),
                    Text(_userStats!.subscriberLength.toString()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _genderGraph() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Répartition des genres"),
            SizedBox(
              height: 250,
              child: PieChartGraph(genderData: _userStats!.gender),
            ),
          ],
        ),
      ),
    );
  }
}
