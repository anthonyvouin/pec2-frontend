import 'package:flutter/material.dart';

import '../../components/categories/categories-list.dart';
import '../../components/free-feed/container.dart';
import '../../components/header/container.dart';
import '../../components/search-bar/search-bar.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            children: [
              SizedBox(height: 24),
              Header(),
              // SizedBox(height: 24),
              // SearchBarOnlyFlic(),
              // SizedBox(height: 24),
              // CategoriesList(),
              SizedBox(height: 32),
              FreeFeed(currentUser: false, isFree: true, homeFeed: true),
            ],
          ),
        ),
      ),
    );
  }
}
