import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
void postureServiceCallback() {
  FlutterForegroundTask.setTaskHandler(PostureTaskHandler());
}

class PostureTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }

  @override
  void onNotificationDismissed() {}
}

class TrackingService {
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'posture_connection',
        channelName: 'Posture connection',
        channelDescription:
            'Keeps the posture trainer connected while your phone is locked.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  static Future<void> start(String text) async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Posture Trainer',
        notificationText: text,
      );
      return;
    }
    await FlutterForegroundTask.startService(
      serviceTypes: const [ForegroundServiceTypes.connectedDevice],
      serviceId: 274,
      notificationTitle: 'Posture Trainer',
      notificationText: text,
      callback: postureServiceCallback,
    );
  }

  static Future<void> update(String text) => start(text);

  static Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}

class DisconnectAlerts {
  final _plugin = FlutterLocalNotificationsPlugin();
  var _ready = false;

  Future<void> init() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _ready = true;
  }

  Future<void> showDisconnected(String name) async {
    if (!_ready) return;
    final who = name.isEmpty ? 'The posture trainer' : name;
    await _plugin.show(
      id: 42,
      title: 'Posture trainer disconnected',
      body: '$who disconnected. It will reconnect when it is nearby.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'posture_alerts',
          'Posture alerts',
          channelDescription: 'Alerts when the posture trainer disconnects.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
