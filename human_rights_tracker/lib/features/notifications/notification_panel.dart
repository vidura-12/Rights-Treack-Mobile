import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationPanel extends StatefulWidget {
  final VoidCallback onMarkAllAsRead;
  final VoidCallback onClose;
  final bool isDarkTheme;

  const NotificationPanel({
    super.key,
    required this.onMarkAllAsRead,
    required this.onClose,
    required this.isDarkTheme,
  });

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  int _unreadCount = 0;
  bool _indexBuilding = false;

  // Theme colors
  Color get _backgroundColor => widget.isDarkTheme ? const Color(0xFF1A243A) : Colors.white;
  Color get _headerColor => widget.isDarkTheme ? const Color(0xFF0A1628) : const Color(0xFFF5F5F5);
  Color get _textColor => widget.isDarkTheme ? Colors.white : Colors.black87;
  Color get _secondaryTextColor => widget.isDarkTheme ? Colors.grey[400]! : Colors.grey[600]!;
  Color get _borderColor => widget.isDarkTheme ? Colors.grey[700]! : Colors.grey[300]!;
  Color get _progressColor => widget.isDarkTheme ? Colors.white : const Color(0xFFE53E3E);

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    if (_currentUser == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('reportedBy', isEqualTo: _currentUser.email)
          .where('read', isEqualTo: false)
          .get();

      setState(() {
        _unreadCount = snapshot.size;
        _indexBuilding = false;
      });
    } catch (e) {
      // Index might be building, use alternative count method
      _checkIndexStatus();
    }
  }

  void _checkIndexStatus() {
    setState(() {
      _indexBuilding = true;
    });
  }

  Future<void> _markAllAsRead() async {
    if (_currentUser == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('reportedBy', isEqualTo: _currentUser.email)
          .where('read', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
      await _loadUnreadCount();
      widget.onMarkAllAsRead();
    } catch (e) {
      _showError('Failed to mark notifications as read');
    }
  }

  Future<void> _markAsRead(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(docId)
          .update({'read': true});
      await _loadUnreadCount();
      widget.onMarkAllAsRead();
    } catch (e) {
      _showError('Failed to mark notification as read');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFD32F2F),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _headerColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                border: Border(bottom: BorderSide(color: _borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_unreadCount > 0 && !_indexBuilding)
                    GestureDetector(
                      onTap: _markAllAsRead,
                      child: Text(
                        'Mark all as read',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Notifications List
            Expanded(
              child: _indexBuilding 
                  ? _buildIndexBuildingMessage()
                  : _buildNotificationsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndexBuildingMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: _progressColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Setting up notifications...',
              style: TextStyle(color: _textColor),
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a few minutes',
              style: TextStyle(color: _secondaryTextColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _currentUser == null
          ? const Stream.empty()
          : FirebaseFirestore.instance
              .collection('notifications')
              .where('reportedBy', isEqualTo: _currentUser.email)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: _secondaryTextColor, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to load notifications',
                    style: TextStyle(color: _secondaryTextColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Index is being created',
                    style: TextStyle(color: _secondaryTextColor, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: _progressColor,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No notifications yet',
              style: TextStyle(color: _secondaryTextColor),
            ),
          );
        }

        // Manual sorting while index builds
        final notifications = snapshot.data!.docs;
        notifications.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['timestamp'] as Timestamp;
          final bTime = bData['timestamp'] as Timestamp;
          return bTime.compareTo(aTime); // Descending order
        });

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final document = notifications[index];
            final data = document.data() as Map<String, dynamic>;

            return NotificationItem(
              title: data['title'] ?? 'Notification',
              message: data['message'] ?? '',
              timestamp: data['timestamp'] as Timestamp,
              isRead: data['read'] == true,
              onTap: () => _markAsRead(document.id),
              isDarkTheme: widget.isDarkTheme,
            );
          },
        );
      },
    );
  }
}

class NotificationItem extends StatelessWidget {
  final String title;
  final String message;
  final Timestamp timestamp;
  final bool isRead;
  final VoidCallback onTap;
  final bool isDarkTheme;

  const NotificationItem({
    super.key,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.onTap,
    required this.isDarkTheme,
  });

  // Theme colors for notification item
  Color get _textColor => isDarkTheme ? Colors.white : Colors.black87;
  Color get _secondaryTextColor => isDarkTheme ? Colors.grey[400]! : Colors.grey[600]!;

  String _getTimeText(Timestamp timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp.toDate());

    if (difference.inMinutes < 1) {
      return "Just now";
    } else if (difference.inHours < 1) {
      return "${difference.inMinutes} min ago";
    } else if (difference.inDays < 1) {
      return "${difference.inHours} hours ago";
    } else {
      return "${difference.inDays} days ago";
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.notifications, color: Colors.deepPurple, size: 20),
      title: Text(
        title,
        style: TextStyle(
          color: _textColor,
          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(color: _secondaryTextColor, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _getTimeText(timestamp),
            style: TextStyle(fontSize: 10, color: _secondaryTextColor),
          ),
        ],
      ),
      trailing: isRead
          ? null
          : const Icon(Icons.circle, color: Colors.red, size: 8),
      onTap: onTap,
    );
  }
}