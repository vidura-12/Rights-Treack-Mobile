import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:human_rights_tracker/core/routes.dart';
//import 'package:human_rights_tracker/widgets/app_footer.dart';
import 'report_case_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<bool> _sidebarSelections = List.filled(11, false);
  bool _showNotifications = false;
  int _unreadNotifications = 0;

  // Pages for bottom navigation
  final List<Widget> _pages = [
    const HomeContent(),
    const ReportCasePage(),
    const PlaceholderWidget(title: 'Courses Page'),
    const PlaceholderWidget(title: 'Talk Page'),
    const PlaceholderWidget(title: 'Media Page'),
  ];

  @override
  void initState() {
    super.initState();
    _sidebarSelections[0] = true; // Home selected by default
    _loadUnreadNotificationsCount();
  }

  Future<void> _loadUnreadNotificationsCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    setState(() {
      _unreadNotifications = snapshot.size;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 204, 204, 204)),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _showNotifications = !_showNotifications;
                  });
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 3,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotifications.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
        title: Flexible(
          child: Row(
            children: [
              const Text(
                'RightsTrack',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Justice Starts With Awareness',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: _buildSidebar(),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _pages[_currentIndex],
              ),
             
            ],
          ),
          if (_showNotifications) _buildNotificationsPanel(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildNotificationsPanel() {
    return Positioned(
      top: 3,
      right: 18,
      width: MediaQuery.of(context).size.width * 0.8,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: const Color(0xFF1A243A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1628),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  border: Border(bottom: BorderSide(color: Colors.grey[700]!)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Mark all as read',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No notifications yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView(
                      children: snapshot.data!.docs.map((DocumentSnapshot document) {
                        Map<String, dynamic> data = document.data() as Map<String, dynamic>;

                        // Format timestamp
                        String timeText = "Recently";
                        if (data['timestamp'] != null) {
                          final timestamp = data['timestamp'] as Timestamp;
                          final now = DateTime.now();
                          final difference = now.difference(timestamp.toDate());

                          if (difference.inMinutes < 1) {
                            timeText = "Just now";
                          } else if (difference.inHours < 1) {
                            timeText = "${difference.inMinutes} min ago";
                          } else if (difference.inDays < 1) {
                            timeText = "${difference.inHours} hours ago";
                          } else {
                            timeText = "${difference.inDays} days ago";
                          }
                        }

                        return ListTile(
                          leading: const Icon(Icons.notifications, color: Colors.deepPurple, size: 20),
                          title: Text(
                            data['title'] ?? 'Notification',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: data['read'] == true ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['message'] ?? '',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timeText,
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: data['read'] == true
                              ? null
                              : const Icon(Icons.circle, color: Colors.red, size: 8),
                          onTap: () {
                            // Mark as read when tapped
                            document.reference.update({'read': true});
                            _loadUnreadNotificationsCount();
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Drawer(
      backgroundColor: const Color(0xFF1A243A),
      child: SafeArea(
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
      leading: Icon(
        icon,
        color: _sidebarSelections[index] ? const Color(0xFFE53E3E) : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _sidebarSelections[index] ? const Color(0xFFE53E3E) : Colors.white,
          fontWeight: _sidebarSelections[index] ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: _sidebarSelections[index],
      onTap: () {
        setState(() {
          for (int i = 0; i < _sidebarSelections.length; i++) {
            _sidebarSelections[i] = i == index;
          }
          _currentIndex = 0; // Reset to home when using sidebar
        });
        Navigator.pop(context); // close drawer
        // Navigate to Media page if Media is tapped
        if (title == 'Media') {
          Navigator.pushNamed(context, AppRoutes.media);
        }
        // ...you can add similar navigation for other sidebar items if needed...

        // Navigate to ReportCasePage when Case Tracker is tapped
        if (index == 4) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportCasePage()),
          );
        }
      },
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

// HomeContent moved outside
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
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
          // Pass onTap only for Media tile
          _buildFeatureTile(
            'Media',
            Icons.photo_library,
            const Color(0xFFDD6B20),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.media);
            },
          ),
        ],
      ),
    );
  }

  // Update _buildFeatureTile to accept an optional onTap callback
  Widget _buildFeatureTile(String title, IconData icon, Color color, {VoidCallback? onTap}) {

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to ReportCasePage if Case Tracker or Report Abuse
          if (title == 'Case Tracker' || title == 'Report Abuse') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportCasePage()),
            );
          }
          debugPrint('$title tapped');
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: bgColor,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 30),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
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
        // Navigate to Media page if Media is tapped
        if (index == 4) {
          Navigator.pushNamed(context, AppRoutes.media);
        }
        // ...you can add similar navigation for other bottom nav items if needed...
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Report'),
        BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Courses'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Talk'),
        BottomNavigationBarItem(icon: Icon(Icons.photo_library), label: 'Media'),
      ],
// Placeholder widget for other pages
class PlaceholderWidget extends StatelessWidget {
  final String title;

  const PlaceholderWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
