import 'package:KmerLingo/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:KmerLingo/core/services/api_service.dart';
import '../../data/models/notification.dart';

class NotificationScreen extends StatefulWidget {
  final String userId;
  final VoidCallback? onReadChanged; // callback pour notifier MainScreen

  const NotificationScreen({
    Key? key,
    required this.userId,
    this.onReadChanged,
  }) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ApiService api = ApiService();
  late Future<List<AppNotification>> notificationsFuture;
  List<AppNotification> notificationsList = [];

  @override
  void initState() {
    super.initState();
    notificationsFuture = api.fetchNotifications(widget.userId);
    _markAllAsRead(); // Marquer toutes les notifications comme lues dès l'ouverture
  }

  Future<void> _markAllAsRead() async {
    final notifications = await api.fetchNotifications(widget.userId);
    for (var notif in notifications.where((n) => !n.isRead)) {
      await api.markNotificationAsRead(notif.id);
    }
    widget.onReadChanged?.call();
    setState(() {
      notificationsList = notifications.map((n) => n.copyWith(isRead: true)).toList();
      notificationsFuture = Future.value(notificationsList);
    });
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (!notification.isRead) {
      await api.markNotificationAsRead(notification.id);
      final index = notificationsList.indexOf(notification);
      if (index != -1) {
        setState(() {
          notificationsList[index] = notification.copyWith(isRead: true);
          notificationsFuture = Future.value(notificationsList);
        });
      }
      widget.onReadChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: AppColors.warning,
      ),
      body: FutureBuilder<List<AppNotification>>(
        future: notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erreur : ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return const Center(child: Text("Aucune notification"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return Card(
                color: notif.isRead ? Colors.white : Colors.orange[50],
                child: ListTile(
                  leading: Icon(
                    notif.isBroadcast
                        ? Icons.campaign_rounded
                        : Icons.notifications_rounded,
                    color: notif.isRead ? Colors.grey : Colors.orange,
                  ),
                  title: Text(
                    notif.message,
                    style: TextStyle(
                      fontWeight:
                          notif.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "Reçue le ${notif.sentAt.toLocal()}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () => _markAsRead(notif),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
