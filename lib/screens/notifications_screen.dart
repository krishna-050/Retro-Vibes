import 'package:flutter/material.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class RetroNotification {
  final String id;
  final String title;
  final String message;
  final String time;
  final IconData icon;
  bool isRead;

  RetroNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    this.isRead = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<RetroNotification> _notifications = [
    RetroNotification(
      id: '1',
      title: 'New 70s Road Trip Mix Added!',
      message: 'Explore timeless classics from Eagles, Queen, and more in the 70s collection.',
      time: '10 mins ago',
      icon: Icons.album,
      isRead: false,
    ),
    RetroNotification(
      id: '2',
      title: 'Daily Retro Vibe Ready',
      message: 'Your personalized throwback mix of 80s Hits is waiting for you.',
      time: '2 hours ago',
      icon: Icons.headphones,
      isRead: false,
    ),
    RetroNotification(
      id: '3',
      title: 'Ultra High Quality Streaming',
      message: 'Enjoy your retro tracks at crystal-clear 320kbps streaming quality.',
      time: 'Yesterday',
      icon: Icons.high_quality,
      isRead: true,
    ),
    RetroNotification(
      id: '4',
      title: 'Welcome to Retro Vibes!',
      message: 'Thank you for joining our community of music lovers. Start streaming today.',
      time: '3 days ago',
      icon: Icons.celebration,
      isRead: true,
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
  }

  void _clearAll() {
    setState(() {
      _notifications.clear();
    });
  }

  void _toggleRead(RetroNotification notification) {
    setState(() {
      notification.isRead = !notification.isRead;
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.white),
          onPressed: () => Navigator.pop(context, unreadCount),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          if (_notifications.isNotEmpty) ...[
            IconButton(
              icon: Icon(Icons.done_all, color: AppTheme.yellow300),
              tooltip: 'Mark all as read',
              onPressed: _markAllAsRead,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Clear all',
              onPressed: _clearAll,
            ),
          ],
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: AppTheme.white38,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      color: AppTheme.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We will notify you when new retro tracks drop!',
                    style: TextStyle(
                      color: AppTheme.white38,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return Dismissible(
                  key: Key(notification.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    setState(() {
                      _notifications.removeAt(index);
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: notification.isRead
                          ? AppTheme.cardBackground.withValues(alpha: 0.6)
                          : AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: notification.isRead
                            ? Colors.transparent
                            : AppTheme.yellow300.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.yellow300.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          notification.icon,
                          color: AppTheme.yellow300,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                color: AppTheme.white,
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppTheme.yellow300,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            notification.message,
                            style: TextStyle(
                              color: AppTheme.white38,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notification.time,
                            style: TextStyle(
                              color: AppTheme.yellow300.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _toggleRead(notification),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
