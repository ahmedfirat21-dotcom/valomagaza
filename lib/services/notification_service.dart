import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  static const _enabledKey = 'valo_magaza_notifications_enabled';
  static const _notificationPrefix = 'valo_magaza_last_notification_';
  static const _channelId = 'valo_store_channel';
  static const _channelName = 'Mağaza Bildirimleri';
  static const _channelDescription =
      'Uygulama açıldığında istek listenizle eşleşen mağaza teklifleri.';

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(settings: initSettings);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Notification initialization error: $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_enabledKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, enabled);
    } catch (_) {}
  }

  Future<void> clearLocalSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_enabledKey);
      final keys = prefs
          .getKeys()
          .where((key) => key.startsWith(_notificationPrefix))
          .toList(growable: false);
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }

  Future<void> showWishlistMatchNotification({
    required String puuid,
    required List<String> skinNames,
  }) async {
    final enabled = await isNotificationsEnabled();
    if (!enabled || skinNames.isEmpty) return;

    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final notificationKey = '$_notificationPrefix${puuid.toLowerCase()}';
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      if (prefs.getString(notificationKey) == date) return;
    } catch (_) {}

    await initialize();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const platformDetails = NotificationDetails(android: androidDetails);

    final title = skinNames.length == 1
        ? '🎉 İstek Listendeki Kaplama Mağazada!'
        : '🎉 İstek Listenden ${skinNames.length} Kaplama Mağazada!';

    final body =
        '${skinNames.join(', ')} bugün mağazana geldi! Fırsatı kaçırma.';

    try {
      await _plugin.show(
        id: 1001,
        title: title,
        body: body,
        notificationDetails: platformDetails,
      );
      await prefs?.setString(notificationKey, date);
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }
}
