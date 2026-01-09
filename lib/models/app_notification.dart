enum NotificationKind { order, system, info } // Added NotificationKind enum

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;
  final DateTime expiryTime;
  final NotificationKind kind; // Added kind field

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    required this.expiryTime,
    this.kind = NotificationKind.info, // Default to info
  });

  // Convertir une notification en JSON pour le stockage local
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'expiryTime': expiryTime.toIso8601String(),
    'kind': kind.name, // Store enum name
  };

  // Créer une notification à partir du JSON
  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isRead: json['isRead'] as bool,
        expiryTime: DateTime.parse(json['expiryTime'] as String),
        kind: NotificationKind.values.firstWhere(
          (e) => e.name == json['kind'],
          orElse: () => NotificationKind.info,
        ), // Parse enum name
      );

  @override
  String toString() {
    return 'AppNotification(id: $id, title: $title, body: $body, timestamp: $timestamp, isRead: $isRead, expiryTime: $expiryTime, kind: $kind)';
  }
}
