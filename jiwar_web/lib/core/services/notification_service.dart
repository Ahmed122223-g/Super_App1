import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jiwar_web/core/services/api_service.dart';
import 'package:jiwar_web/firebase_options.dart';

// Top-level function for background handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } else {
    await Firebase.initializeApp();
  }
  debugPrint('Handling a background message ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();
  
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Set background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    debugPrint('User granted permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get token and save to backend
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        // Do not register token here. It will be registered after login/profile load.
      }
      
      // Listen for token refresh
      _messaging.onTokenRefresh.listen((token) {
        debugPrint('FCM Token Refreshed: $token');
        // Token refresh logic should arguably also check for auth before sending
      });
      
      // Foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification}');
          // TODO: Show in-app notification/dialog
          // For now we just log it, or rely on UI updates
        }
      });
      
      // Message opened app
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('A new onMessageOpenedApp event was published!');
        _handleNotificationClick(message);
      });
    }
    
    _isInitialized = true;
  }
  
  void _handleNotificationClick(RemoteMessage message) {
    // Navigate based on data
    final data = message.data;
    final type = data['type'];
    final action = data['action'];
    
    debugPrint("Notification Clicked: Type=$type, Action=$action");
    
    // Implementation dependent on navigation setup (GoRouter context needed)
    // We can use a GlobalKey<NavigatorState> if available, or a stream
  }
}
