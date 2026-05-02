import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

// Notification Service Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Last Message Provider
final lastMessageProvider = StateProvider<String>((ref) => 'No messages yet');

// FCM Token Provider
final fcmTokenProvider = StateProvider<String?>((ref) => null);

// Initialize Notifications Provider
final initializeNotificationsProvider = FutureProvider<void>((ref) async {
  final service = ref.read(notificationServiceProvider);

  await service.initialize(
    onMessageReceived: (RemoteMessage message) {
      final title = message.notification?.title ?? 'New Signal';
      final body = message.notification?.body ?? '';
      ref.read(lastMessageProvider.notifier).state = '$title\n$body';
    },
  );

  ref.read(fcmTokenProvider.notifier).state = service.fcmToken;
});
