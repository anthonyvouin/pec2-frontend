import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../components/graph/pie_chart_graph.dart';
import '../../components/subscriber/subscriberList.dart' show SubscribersList;
import '../../components/title/title_onlyflick.dart';
import '../../interfaces/user_stats.dart';
import '../../services/api_service.dart';
import '../../services/toast_service.dart';

class CreatorStatView extends StatefulWidget {
  @override
  _CreatorStatViewState createState() => _CreatorStatViewState();
}

class _CreatorStatViewState extends State<CreatorStatView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedOption = '7 derniers jours';
  DateTimeRange? _selectedRange;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  UserStats? _userStats;
  String _selectedFollowOrSubscriber = 'Abonnés';

  @override
  void initState() {
    super.initState();
    _getData();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getData() async {
    setState(() {
      _isLoading = true;
    });
    ApiResponse request = await _apiService.request(
      method: 'Get',
      endpoint:
          '/content-creators/stats/creator?isSubscriberSearch=${_selectedFollowOrSubscriber == "Abonnés" ? true : false}',
    );
    if (request.success) {
      setState(() {
        _userStats = UserStats.fromJson(request.data);
        print(_userStats);
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
    print(request);
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
                TabBar(tabs: [Tab(text: _selectedFollowOrSubscriber)]),
                Expanded(
                  child: TabBarView(
                    children: [
                      SubscribersList(
                        subscribers: _userStats!.subscribersOrFollowers,
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.black54,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: const [Tab(text: 'Général'), Tab(text: 'Revenue')],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Center(child: Text('Vue général')),
                _generalStats(),
                Center(child: Text('Vue revenue')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    if (_isLoading) {
      return Text('Chargement des données');
    }

    return Column(
      children: [
        Row(
          children: [
            DropdownButton<String>(
              value: _selectedFollowOrSubscriber,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedFollowOrSubscriber = newValue!;
                });
                _getData();
              },
              items:
                  <String>[
                    'Abonnés',
                    'Followers',
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
            ),
          ],
        ),

        SizedBox(height: 16),
        _firstLine(),
      ],
    );
  }

  Widget _getSubscribersOrFollowers() {
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
                    TitleOnlyFlick(
                      text: _selectedFollowOrSubscriber,
                      fontSize: 20,
                    ),
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
            SizedBox(height: 16),
            TitleOnlyFlick(text: 'Genres', fontSize: 20),
            SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: PieChartGraph(genderData: _userStats!.gender),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subscriberAge() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
            TitleOnlyFlick(text: 'Âges', fontSize: 20),
            SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_userStats!.age.under18 > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Moins de 18 ans : "),
                        Text("${_userStats!.age.under18}%"),
                      ],
                    ),
                    SizedBox(height: 8),
                  ],
                  if (_userStats!.age.between18And25 > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Entre 18 et 25 ans : "),
                        Text("${_userStats!.age.between18And25}%"),
                      ],
                    ),
                    SizedBox(height: 8),
                  ],
                  if (_userStats!.age.between26And40 > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Entre 26 et 40 ans : "),
                        Text("${_userStats!.age.between26And40}%"),
                      ],
                    ),
                    SizedBox(height: 8),
                  ],
                  if (_userStats!.age.over40 > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Plus de 40 ans : "),
                        Text("${_userStats!.age.over40}%"),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
          SizedBox(width: 300, child: _getSubscribersOrFollowers()),
          SizedBox(width: 300, child: _genderGraph()),
          SizedBox(width: 300, child: _subscriberAge()),
        ],
      ),
    );
  }

  Widget _generalStats() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(children: [_content()]),
    );
  }
}
