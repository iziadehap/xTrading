import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/modern_home_screen.dart';
import 'services/settings_service.dart';
import 'services/update_service.dart';
import 'widgets/update_dialog.dart';

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📩 Background message received: ${message.messageId}');
  print('📩 Title: ${message.notification?.title}');
  print('📩 Body: ${message.notification?.body}');
}

// 🔴 أضف هذه الدالة الجديدة للاشتراك في التوبيك
Future<void> subscribeToTopic(String topic) async {
  try {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    print('✅ Successfully subscribed to topic: $topic');
  } catch (e) {
    print('❌ Failed to subscribe to topic $topic: $e');
  }
}

// 🔴 أضف هذه الدالة لطباعة التوكن
Future<void> printFCMToken() async {
  try {
    String? token = await FirebaseMessaging.instance.getToken();
    print('📱 ========================================');
    print('📱 YOUR FCM TOKEN:');
    print('📱 $token');
    print('📱 ========================================');
  } catch (e) {
    print('❌ Failed to get token: $e');
  }
}

// 🔴 أضف هذه الدالة لطلب الإذن (مهم جداً في iOS)
Future<void> requestNotificationPermission() async {
  NotificationSettings settings = await FirebaseMessaging.instance
      .requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false, // iOS: لا تستخدم الإذن المؤقت
      );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('✅ Notification permission granted');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('✅ Provisional notification permission granted');
  } else {
    print('❌ Notification permission denied');
  }
}

// 🔴 أضف هذه الدالة لمعالجة الرسائل عندما يكون التطبيق في المقدمة
void setupForegroundMessageHandler() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📩 Foreground message received:');
    print('   Title: ${message.notification?.title}');
    print('   Body: ${message.notification?.body}');

    // هنا يمكنك عرض snackbar أو dialog
  });
}

// 🔴 أضف هذه الدالة لمعالجة عندما يفتح المستخدم الإشعار
void setupMessageOpenHandler() {
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('📱 App opened from notification:');
    print('   Title: ${message.notification?.title}');
    // هنا يمكنك التنقل لشاشة معينة حسب محتوى الإشعار
  });
}

// Check for app updates
Future<void> checkForUpdates() async {
  try {
    final updateInfo = await UpdateService.instance.check();
    if (updateInfo != null) {
      print('🔄 Update available: ${updateInfo.latestVersion}');
      // Note: You'll need to pass context to show the dialog
      // This should be called from your home screen with proper context
    } else {
      print('✅ App is up to date');
    }
  } catch (e) {
    print('❌ Failed to check for updates: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize settings service
  await SettingsService().init();

  // 🔴 طلب إذن الإشعارات
  await requestNotificationPermission();

  // 🔴 اشترك في التوبيك فور بدء التطبيق
  await subscribeToTopic('egx_signals'); // تأكد أن الاسم مطابق لما في .env

  // 🔴 طباعة التوكن للتصحيح
  await printFCMToken();

  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 🔴 إعداد معالجات الرسائل
  setupForegroundMessageHandler();
  setupMessageOpenHandler();

  // Check for updates (non-blocking)
  checkForUpdates();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'X Trading',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const ModernHomeScreen(),
    );
  }
}
