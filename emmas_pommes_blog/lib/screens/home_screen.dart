import 'package:flutter/material.dart';
import 'map/map_screen.dart';
import 'news/news_screen.dart';
import 'ranking/ranking_screen.dart';
import 'profile/meine_besuche_screen.dart';
import 'profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _newsKey = GlobalKey<NewsScreenState>();
  final _rankingKey = GlobalKey<RankingScreenState>();
  final _besucheKey = GlobalKey<MeineBesucheScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const MapScreen(),
      NewsScreen(key: _newsKey),
      RankingScreen(key: _rankingKey),
      MeineBesucheScreen(key: _besucheKey),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) _newsKey.currentState?.reload();
          if (index == 2) _rankingKey.currentState?.reload();
          if (index == 3) _besucheKey.currentState?.reload();
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Karte',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper),
            label: 'News',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Ranking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Besuche',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
