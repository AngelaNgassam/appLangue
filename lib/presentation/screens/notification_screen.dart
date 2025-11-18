import 'package:flutter/material.dart';
import 'package:KmerLingo/core/services/api_service.dart';
import '../../data/models/notification.dart';

class NotificationScreen extends StatefulWidget {
  final String userId;
  final VoidCallback? onReadChanged;

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
    _markAllAsRead();
  }

  Future<void> _markAllAsRead() async {
    final notifications = await api.fetchNotifications(widget.userId);
    for (var notif in notifications.where((n) => !n.isRead)) {
      await api.markNotificationAsRead(notif.id);
    }

    widget.onReadChanged?.call();

    setState(() {
      notificationsList =
          notifications.map((n) => n.copyWith(isRead: true)).toList();
      notificationsFuture = Future.value(notificationsList);
    });
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (!notification.isRead) {
      await api.markNotificationAsRead(notification.id);
      final index = notificationsList.indexOf(notification);

      if (index != -1) {
        setState(() {
          notificationsList[index] =
              notification.copyWith(isRead: true);
          notificationsFuture = Future.value(notificationsList);
        });
      }
      widget.onReadChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🌈 Dégradé background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFA726), // Orange clair
              Color(0xFFFF7043), // Orange foncé
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SafeArea(
          child: Column(
            children: [
              // 🔥 HEADER MODERNE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  children: [
                    const Icon(Icons.notifications, color: Colors.white, size: 30),
                    const SizedBox(width: 10),
                    const Text(
                      "Notifications",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          notificationsFuture =
                              api.fetchNotifications(widget.userId);
                        });
                      },
                    )
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(25)),
                  ),

                  child: FutureBuilder<List<AppNotification>>(
                    future: notificationsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.orange,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Erreur : ${snapshot.error}",
                            style: const TextStyle(
                                color: Colors.red, fontSize: 16),
                          ),
                        );
                      }

                      final notifications = snapshot.data ?? [];

                      if (notifications.isEmpty) {
                        return const Center(
                          child: Text(
                            "Aucune notification",
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.w500),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notif = notifications[index];

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: notif.isRead
                                  ? Colors.white
                                  : Colors.orange.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: notif.isRead
                                      ? Colors.grey.shade200
                                      : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(
                                  notif.isBroadcast
                                      ? Icons.campaign_rounded
                                      : Icons.notifications_active_rounded,
                                  color: notif.isRead
                                      ? Colors.grey
                                      : Colors.orange,
                                ),
                              ),

                              title: Text(
                                notif.message,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: notif.isRead
                                      ? FontWeight.w400
                                      : FontWeight.bold,
                                ),
                              ),

                              subtitle: Text(
                                "Reçue le ${notif.sentAt.toLocal()}",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),

                              onTap: () => _markAsRead(notif),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
