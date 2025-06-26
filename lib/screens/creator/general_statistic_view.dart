import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import '../../components/graph/pie_chart_graph.dart';
import '../../components/subscriber/subscriberList.dart';
import '../../components/title/title_onlyflick.dart';
import '../../interfaces/user_stats.dart';
import '../../notifiers/userNotififers.dart';
import '../../services/api_service.dart';
import '../../services/toast_service.dart';

class GeneralStatisticView extends StatefulWidget {
  const GeneralStatisticView({super.key});

  @override
  State<GeneralStatisticView> createState() => _GeneralStatisticViewState();
}

class _GeneralStatisticViewState extends State<GeneralStatisticView> {
  bool _isCreator = false;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  CreatorGeneralStats? _userStatsGeneral;
  String _selectedFollowOrSubscriber = 'Abonnés';

  @override
  void initState() {
    super.initState();
    _getData();
  }

  Future<void> _getData() async {
    setState(() {
      _isLoading = true;
    });
    ApiResponse request = await _apiService.request(
      method: 'Get',
      endpoint:
      '/content-creators/stats-general/creator?isSubscriberSearch=${_selectedFollowOrSubscriber == "Abonnés" ? true : false}',
    );
    if (request.success) {
      setState(() {
        _userStatsGeneral = CreatorGeneralStats.fromJson(request.data);
        print(_userStatsGeneral);
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
                        subscribers: _userStatsGeneral!.subscribersOrFollowers,
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


  Widget _content() {
    final userNotifier = Provider.of<UserNotifier>(context);
    _isCreator = userNotifier.user?.role == "CONTENT_CREATOR" ;
    if (_isLoading) {
      return Text('Chargement des données');
    }

    return Column(
      children: [
        if(_isCreator)
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
        SizedBox(height: 8),
        _secondLine()
      ],
    );
  }

  Widget _secondLine(){
    if(_userStatsGeneral!.threeLastPost.isEmpty){
      return Text("Vous n'avez rien posté");
    }
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: [
          SizedBox(width: 300, child: _mostLiked()),
          SizedBox(width: 300, child: _mostCommented()),
          SizedBox(width: 300, child: _threeLastPost()),
        ],
      ),
    );
  }

  Widget _mostLiked (){
    return Card(
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 341,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 16),
                TitleOnlyFlick(text: 'Le post plus aimé', fontSize: 20),
                SizedBox(height: 16),
                if(_userStatsGeneral!.mostLiked.likeCount == 0)
                  Text("Aucuns post n'est le plus aimé"),

                if(_userStatsGeneral!.mostLiked.likeCount > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _userStatsGeneral!.mostLiked.pictureUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(_userStatsGeneral!.mostLiked.name),
                      Text(_userStatsGeneral!.mostLiked.description),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.favorite_border, color: Colors.red),
                          Text('${_userStatsGeneral!.mostLiked.likeCount.toString()} likes'),
                        ],
                      ),
                    ],
                  )

              ],
            ),
          )


      ),
    );
  }

  Widget _threeLastPost() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            TitleOnlyFlick(text: 'Les 3 derniers posts', fontSize: 20),
            const SizedBox(height: 16),

            if (_userStatsGeneral!.threeLastPost.isEmpty)
              const Text("Aucun post"),

            if (_userStatsGeneral!.threeLastPost.isNotEmpty)
              SizedBox(
                height: 280,
                child: Column(
                  children: _userStatsGeneral!.threeLastPost.map((post) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          // Image du post
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              post.pictureUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Nom du post
                          Expanded(
                            child: Text(
                              post.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              )

          ],
        ),
      ),
    );
  }

  Widget _mostCommented (){
    return Card(
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 341,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 16),
                TitleOnlyFlick(text: 'Le post plus commenté', fontSize: 20),
                SizedBox(height: 16),
                if(_userStatsGeneral!.mostCommented.commentCount == 0)
                  Text("Aucuns post n'est le plus aimé"),

                if(_userStatsGeneral!.mostCommented.commentCount > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _userStatsGeneral!.mostCommented.pictureUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(_userStatsGeneral!.mostCommented.name),
                      Text(_userStatsGeneral!.mostCommented.description),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.message),
                          SizedBox(width: 8),
                          Text('${_userStatsGeneral!.mostCommented.commentCount.toString()} commentaires'),
                        ],
                      ),
                    ],
                  )

              ],
            ),
          )


      ),
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
                    Text(_userStatsGeneral!.subscriberLength.toString()),
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
              height: 200,
              child: PieChartGraph(genderData: _userStatsGeneral!.gender),
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
              height: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_userStatsGeneral!.age.under18 > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Moins de 18 ans : "),
                        Text("${_userStatsGeneral!.age.under18}%"),
                      ],
                    ),
                    SizedBox(height: 8),
                  ],
                  if (_userStatsGeneral!.age.between18And25 > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Entre 18 et 25 ans : "),
                        Text("${_userStatsGeneral!.age.between18And25}%"),
                      ],
                    ),
                    SizedBox(height: 8),
                  ],
                  if (_userStatsGeneral!.age.between26And40 > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Entre 26 et 40 ans : "),
                        Text("${_userStatsGeneral!.age.between26And40}%"),
                      ],
                    ),
                    SizedBox(height: 8),
                  ],
                  if (_userStatsGeneral!.age.over40 > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Plus de 40 ans : "),
                        Text("${_userStatsGeneral!.age.over40}%"),
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
    if(_userStatsGeneral!.subscriberLength == 0){
      return Text("Vous n'avez pas de $_selectedFollowOrSubscriber");
    }
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

  @override
  Widget build(BuildContext context) {
    return _generalStats();
  }
}
