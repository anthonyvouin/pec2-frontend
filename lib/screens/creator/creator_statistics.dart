import 'package:firstflutterapp/screens/creator/advencedView.dart';
import 'package:firstflutterapp/screens/creator/general_statistic_view.dart';
import 'package:flutter/material.dart';


class CreatorStatView extends StatefulWidget {
  @override
  _CreatorStatViewState createState() => _CreatorStatViewState();
}

class _CreatorStatViewState extends State<CreatorStatView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              tabs: const [Tab(text: 'Général'), Tab(text: 'Avancé')],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Center(child: Text('Vue général')),
                GeneralStatisticView(),
               Advencedview()
              ],
            ),
          ),
        ],
      ),
    );
  }
}
