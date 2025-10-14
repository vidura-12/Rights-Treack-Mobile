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
import 'SupportersLoginPage .dart';
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


  // Modern theme colors
  final Color _darkBackground = const Color(0xFF0F1419);
  final Color _darkCard = const Color(0xFF1C2128);
  final Color _darkAppBar = const Color(0xFF0F1419);
  final Color _accentColor = const Color(0xFF6366F1);
  final Color _accentLight = const Color(0xFF818CF8);
  final Color _lightBackground = const Color(0xFFF8FAFC);
  final Color _lightCard = const Color(0xFFFFFFFF);
  final Color _lightAppBar = const Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _sidebarSelections[0] = true;

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

  Color get _backgroundColor => _isDarkTheme ? _darkBackground : _lightBackground;
  Color get _cardColor => _isDarkTheme ? _darkCard : _lightCard;
  Color get _appBarColor => _isDarkTheme ? _darkAppBar : _lightAppBar;
  Color get _textColor => _isDarkTheme ? Colors.white : Colors.black87;
  Color get _secondaryTextColor => _isDarkTheme ? Colors.grey[400]! : Colors.grey[600]!;
  Color get _iconColor => _isDarkTheme ? Colors.white : Colors.black87;

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return HomeContent(isDarkTheme: _isDarkTheme);
      case 1:
        return ReportCasePage(isDarkTheme: _isDarkTheme);
      case 2:
        return UserSupportPage(isDarkTheme: _isDarkTheme);
      case 3:
        return MediaPage(isDarkTheme: _isDarkTheme);
      default:
        return HomeContent(isDarkTheme: _isDarkTheme);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _appBarColor,
        elevation: 0,
        iconTheme: IconThemeData(color: _iconColor),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isDarkTheme ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _isDarkTheme ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: _iconColor,
                size: 20,
              ),
            ),
            onPressed: _toggleTheme,
          ),
          Stack(
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isDarkTheme ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.notifications_outlined, color: _iconColor, size: 20),
                ),
                onPressed: _toggleNotifications,
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _unreadNotifications > 9 ? '9+' : _unreadNotifications.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        title: Row(
          children: [
            
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'rightstracker',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Justice Starts With Awareness',
                    style: TextStyle(
                      color: _secondaryTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      drawer: _buildSidebar(),
      body: Stack(
        children: [
          _getCurrentPage(),
          if (_showNotifications)
            Positioned(
              top: 0,
              right: 16,
              child: SizeTransition(
                sizeFactor: _animation,
                axisAlignment: -1,
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
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildSidebarItem(0, Icons.home_outlined, 'Home'),
                  _buildSidebarItem(1, Icons.person_outline, 'Profile', onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProfilePage(isDarkTheme: _isDarkTheme)),
                    );
                  }),
                  _buildSidebarItem(2, Icons.photo_library_outlined, 'Media', onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MediaPage(isDarkTheme: _isDarkTheme)),
                    );
                  }),
                  _buildSidebarItem(3, Icons.track_changes, 'Case Tracker', onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CaseListPage()),
                    );
                  }),
                  _buildSidebarItem(4, Icons.chat_outlined, 'Talk', onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => UserSupportPage(isDarkTheme: _isDarkTheme)),
                    );
                  }),
                  const Divider(height: 32),
                 _buildSidebarItem(5, Icons.people_outline, 'Supporters', onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SupportersLoginPage(isDarkTheme: _isDarkTheme),
                      ),
                    );
                  }),
                  _buildSidebarItem(6, Icons.info_outline, 'About Us'),
                  _buildSidebarItem(7, Icons.mail_outline, 'Contact Us'),
                  _buildSidebarItem(8, Icons.privacy_tip_outlined, 'Privacy Policy'),
                  _buildSidebarItem(9, Icons.help_outline, 'FAQ'),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String title, {VoidCallback? onTap}) {
    final isSelected = _sidebarSelections[index];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? _accentColor.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? _accentColor : _textColor,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? _accentColor : _textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 15,
          ),
        ),
        selected: isSelected,
        onTap: () {
          setState(() {
            for (int i = 0; i < _sidebarSelections.length; i++) {
              _sidebarSelections[i] = i == index;
            }
          });
          Navigator.pop(context);
          if (onTap != null) {
            onTap();
          }
        },
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
              _buildNavItem(1, Icons.report_outlined, Icons.report, 'Report'),
              _buildNavItem(2, Icons.chat_outlined, Icons.chat, 'Talk'),
              _buildNavItem(3, Icons.photo_library_outlined, Icons.photo_library, 'Media'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlinedIcon, IconData filledIcon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _accentColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? filledIcon : outlinedIcon,
              color: isSelected ? _accentColor : _secondaryTextColor,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: _accentColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final bool isDarkTheme;

  const HomeContent({super.key, required this.isDarkTheme});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDarkTheme ? const Color(0xFF0F1419) : const Color(0xFFF8FAFC);
    final cardColor = isDarkTheme ? const Color(0xFF1C2128) : Colors.white;
    final textColor = isDarkTheme ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkTheme ? Colors.grey[400]! : Colors.grey[600]!;

    return Container(
      color: backgroundColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Actions',
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildModernFeatureCard(
                context,
                'Report a Case',
                'Document and report human rights violations',
                Icons.report_outlined,
                const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                ),
                cardColor,
                textColor,
                secondaryTextColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) =>  ReportCasePage(isDarkTheme: isDarkTheme)),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildCompactCard(
                      context,
                      'Track Cases',
                      Icons.track_changes,
                      const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                      ),
                      cardColor,
                      textColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CaseListPage()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCompactCard(
                      context,
                      'Get AI Support',
                      Icons.chat_outlined,
                      const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      cardColor,
                      textColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => UserSupportPage(isDarkTheme: isDarkTheme)),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildModernFeatureCard(
                context,
                'Media Library',
                'Access educational resources and documentation',
                Icons.photo_library_outlined,
                const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                ),
                cardColor,
                textColor,
                secondaryTextColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MediaPage(isDarkTheme: isDarkTheme)),
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                'Resources',
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                'Emergency Hotline',
                '119 - Available 24/7',
                Icons.phone_in_talk,
                const Color(0xFFEF4444),
                cardColor,
                textColor,
                secondaryTextColor,
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                'Legal Support',
                'Free consultation available',
                Icons.gavel,
                const Color(0xFF6366F1),
                cardColor,
                textColor,
                secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernFeatureCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Gradient gradient,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    {VoidCallback? onTap}
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: secondaryTextColor,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard(
    BuildContext context,
    String title,
    IconData icon,
    Gradient gradient,
    Color cardColor,
    Color textColor,
    {VoidCallback? onTap}
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String subtitle,
    IconData icon,
    Color accentColor,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
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