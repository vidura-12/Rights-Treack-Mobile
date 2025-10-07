import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:human_rights_tracker/core/routes.dart';
import 'report_case_page.dart';
import 'media.dart';
import 'text.dart';
import 'case_list_page.dart';
import 'package:human_rights_tracker/features/notifications/notification_panel.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final List<bool> _sidebarSelections = List.filled(11, false);
  bool _showNotifications = false;
  int _unreadNotifications = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isDarkTheme = true; 

  // Theme colors
  final Color _darkBackground = const Color(0xFF0A1628);
  final Color _darkCard = const Color(0xFF1A243A);
  final Color _darkAppBar = const Color(0xFF0A1628);
  final Color _accentColor = const Color(0xFFE53E3E);
  final Color _lightBackground = Color.fromARGB(255, 255, 255, 255);
  final Color _lightCard = Color.fromARGB(255, 250, 250, 250);
  final Color _lightAppBar = Color.fromARGB(255, 255, 255, 255);

  // Pages for bottom navigation
  final List<Widget> _pages = [
    const HomeContent(),
    const ReportCasePage(),
    const PlaceholderWidget(title: 'Courses Page'),
    const UserSupportPage(),
    const MediaPage(),
  ];

  @override
  void initState() {
    super.initState();
    _sidebarSelections[0] = true; // Home selected by default
    
    // Animation controller for smooth notification panel
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _loadUnreadNotificationsCount();
  }

  Future<void> _loadUnreadNotificationsCount() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('reportedBy', isEqualTo: user.email)
        .where('read', isEqualTo: false)
        .get();

    setState(() {
      _unreadNotifications = snapshot.size;
    });
  }

  void _toggleNotifications() {
    setState(() {
      _showNotifications = !_showNotifications;
      if (_showNotifications) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkTheme = !_isDarkTheme;
    });
  }

  void _onMarkAllAsRead() {
    _loadUnreadNotificationsCount();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Get current theme colors
  Color get _backgroundColor => _isDarkTheme ? _darkBackground : _lightBackground;
  Color get _cardColor => _isDarkTheme ? _darkCard : _lightCard;
  Color get _appBarColor => _isDarkTheme ? _darkAppBar : _lightAppBar;
  Color get _textColor => _isDarkTheme ? Colors.white : Colors.black87;
  Color get _secondaryTextColor => _isDarkTheme ? Colors.grey[400]! : Colors.grey[600]!;
  Color get _iconColor => _isDarkTheme ? Colors.white : Colors.black87;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _appBarColor,
        elevation: 0,
        iconTheme: IconThemeData(color: _iconColor),
        actions: [
          // Theme Toggle Button
          IconButton(
            icon: Icon(
              _isDarkTheme ? Icons.light_mode : Icons.dark_mode,
              color: _iconColor,
            ),
            onPressed: _toggleTheme,
          ),
          // Notifications Button
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications, color: _iconColor),
                onPressed: _toggleNotifications,
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
              Text(
                'RightsTrack',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Justice Starts With Awareness',
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 12,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 2,
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
          
          // Notification Panel with smooth animation
          if (_showNotifications)
            Positioned(
              top: kToolbarHeight -30,
              right: 22,
              child: SizeTransition(
                sizeFactor: _animation,
                axisAlignment: -0.5,
                child: NotificationPanel(
                  onMarkAllAsRead: _onMarkAllAsRead,
                  onClose: _toggleNotifications,
                  isDarkTheme: _isDarkTheme,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildSidebar() {
    return Drawer(
      backgroundColor: _cardColor,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      color: _isDarkTheme ? const Color(0xFF2D3748) : Colors.grey[200],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundColor: Color(0xFFE53E3E),
                            child: Icon(Icons.person, color: Colors.white, size: 30),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Vidura NirmaI',
                            style: TextStyle(
                              color: _textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'viduranirmai@gmail.com',
                            style: TextStyle(color: _secondaryTextColor, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          Divider(color: _isDarkTheme ? Colors.grey[700] : Colors.grey[400]),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          _buildSidebarItem(0, Icons.home, 'Home'),
                          _buildSidebarItem(1, Icons.person, 'Profile', onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ProfilePage()),
                            );
                          }),
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: IconButton(
                icon: Icon(Icons.logout, color: _textColor),
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

  Widget _buildSidebarItem(int index, IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(
        icon,
        color: _sidebarSelections[index] ? _accentColor : _textColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _sidebarSelections[index] ? _accentColor : _textColor,
          fontWeight: _sidebarSelections[index] ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: _sidebarSelections[index],
      onTap: () {
        setState(() {
          for (int i = 0; i < _sidebarSelections.length; i++) {
            _sidebarSelections[i] = i == index;
          }
        });
        Navigator.pop(context);
        
        if (onTap != null) {
          onTap();
        } else if (title == 'Media') {
          setState(() {
            _currentIndex = 4;
          });
        } else if (title == 'Case Tracker') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CaseListPage()),
          );
        }
      },
    );
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: _isDarkTheme ? const Color(0xFF0A1628) : Colors.white,
      selectedItemColor: _accentColor,
      unselectedItemColor: _isDarkTheme ? Colors.grey : Colors.grey[600],
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
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

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkTheme ? const Color(0xFF0A1628) : Colors.white;
    final textColor = isDarkTheme ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
        children: [
          _buildFeatureTile(
            'Report Abuse',
            Icons.report,
            const Color(0xFFFFCDD2),
            const Color(0xFFD32F2F),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportCasePage()),
              );
            },
          ),
          _buildFeatureTile(
            'Case Tracker',
            Icons.track_changes,
            const Color(0xFFC5CAE9),
            const Color(0xFF303F9F),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CaseListPage()),
              );
            },
          ),
          _buildFeatureTile(
            'Directory',
            Icons.contacts,
            const Color(0xFFC8E6C9),
            const Color(0xFF388E3C),
          ),
          _buildFeatureTile(
            'Talk',
            Icons.chat,
            const Color(0xFFC5CAE9),
            const Color(0xFF303F9F),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserSupportPage()),
              );
            },
          ),
          _buildFeatureTile(
            'Courses',
            Icons.school,
            const Color(0xFFE1BEE7),
            const Color(0xFF7B1FA2),
          ),
          _buildFeatureTile(
            'Media',
            Icons.photo_library,
            const Color(0xFFC5CAE9),
            const Color(0xFF303F9F),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MediaPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(String title, IconData icon, Color bgColor, Color iconColor, {VoidCallback? onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
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

class PlaceholderWidget extends StatelessWidget {
  final String title;
  const PlaceholderWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkTheme ? Colors.white : Colors.black87;

    return Center(
      child: Text(
        title,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }
}