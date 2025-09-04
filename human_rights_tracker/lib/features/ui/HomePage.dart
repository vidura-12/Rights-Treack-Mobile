import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:human_rights_tracker/core/routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<bool> _sidebarSelections = List.filled(11, false);

  @override
  void initState() {
    super.initState();
    _sidebarSelections[0] = true; // Home selected by default
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        elevation: 0,
        iconTheme: const IconThemeData( // 👈 this controls the hamburger icon color
        color:  Color.fromARGB(255, 204, 204, 204),  // change to whatever color you want
        ),
          actions: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white),
          onPressed: () {},
        ),        
      ],
        title: Flexible( // ✅ prevents overflow
          child: Row(
            children: [
              Text(
                'RightsTrack',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded( // ✅ allows wrapping if too long
                child: Text(
                  'Justice Starts With Awareness',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    overflow: TextOverflow.ellipsis, // ✅ prevents overflow error
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
),

      drawer: _buildSidebar(), // ✅ keep sidebar as Drawer only
      body: _buildMainContent(), // ✅ Home content only here
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

Widget _buildSidebar() {
  return Drawer(
    backgroundColor: const Color(0xFF1A243A),
    child: SafeArea( // ✅ Prevent overflow at top and bottom
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile header
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: const Color(0xFF2D3748),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: Color(0xFFE53E3E),
                          child: Icon(Icons.person, color: Colors.white, size: 30),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Vidura NirmaI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'viduranirmai@gmail.com',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Divider(color: Colors.grey[700]),
                      ],
                    ),
                  ),
                  // Menu items
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        _buildSidebarItem(0, Icons.home, 'Home'),
                        _buildSidebarItem(1, Icons.person, 'Profile'),
                        _buildSidebarItem(2, Icons.photo_library, 'Media'),
                        _buildSidebarItem(3, Icons.contacts, 'Directory'),
                        _buildSidebarItem(4, Icons.track_changes, 'Case Tracker'),
                        _buildSidebarItem(5, Icons.people, 'Supporters'),
                        _buildSidebarItem(6, Icons.info, 'About Us'),
                        _buildSidebarItem(7, Icons.contact_mail, 'Contact Us'),
                        _buildSidebarItem(8, Icons.privacy_tip, 'Privacy Policy'),
                        _buildSidebarItem(9, Icons.help, 'FAQ'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Logout button at bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              },
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildSidebarItem(int index, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon,
          color:
              _sidebarSelections[index] ? const Color(0xFFE53E3E) : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color:
              _sidebarSelections[index] ? const Color(0xFFE53E3E) : Colors.white,
          fontWeight:
              _sidebarSelections[index] ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: _sidebarSelections[index],
      onTap: () {
        setState(() {
          for (int i = 0; i < _sidebarSelections.length; i++) {
            _sidebarSelections[i] = i == index;
          }
          _currentIndex = index;
        });
        Navigator.pop(context); // close drawer
      },
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
        children: [
          _buildFeatureTile('Report Abuse', Icons.report, const Color(0xFFE53E3E)),
          _buildFeatureTile('Case Tracker', Icons.track_changes, const Color(0xFF3182CE)),
          _buildFeatureTile('Directory', Icons.contacts, const Color(0xFF38A169)),
          _buildFeatureTile('Talk', Icons.chat, const Color(0xFFD69E2E)),
          _buildFeatureTile('Courses', Icons.school, const Color(0xFF805AD5)),
          _buildFeatureTile('Media', Icons.photo_library, const Color(0xFFDD6B20)),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(String title, IconData icon, Color color) {
    return Card(
      color: const Color(0xFF1A243A),
      elevation: 4,
      child: InkWell(
        onTap: () {
          print('$title tapped');
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF0A1628),
      selectedItemColor: const Color(0xFFE53E3E),
      unselectedItemColor: Colors.grey,
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
        if (index == 3) {
          Navigator.pushNamed(context, AppRoutes.support);
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Report'),
        BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Courses'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Talk'),
        BottomNavigationBarItem(icon: Icon(Icons.photo_library), label: 'Media'),
      ],
    );
  }
}
