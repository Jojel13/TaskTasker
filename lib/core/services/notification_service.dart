import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart' hide TaskStatus;
import 'package:path_provider/path_provider.dart';
import 'package:isar/isar.dart';
import '../../shared/models/routine.dart';
import '../../shared/models/routine_day.dart';
import '../../shared/models/task.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/models/xp_event.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final notifService = NotificationService.instance;
      
      // Init ISAR in background isolate
      final dir = await getApplicationDocumentsDirectory();
      final isar = await Isar.open(
        [RoutineSchema, RoutineDaySchema, TaskSchema, UserProfileSchema, XPEventSchema],
        directory: dir.path,
        name: 'tasktasker_db',
      );
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Find today's routine
      final routine = await isar.routines.filter().dateEqualTo(today).findFirst();
      if (routine != null) {
        // Load days
        await routine.days.load();
        
        bool hasEminentRedTask = false;
        bool hasPendingYellow = false;
        
        for (final day in routine.days) {
          await day.tasks.load();
          for (final t in day.tasks) {
            if (t.status != TaskStatus.completed) {
              if (t.color == TaskColor.red) hasEminentRedTask = true;
              if (t.color == TaskColor.yellow) hasPendingYellow = true;
            }
          }
        }
        
        String title = 'Resumo da Rotina';
        String body = 'Você tem tarefas para hoje.';
        
        if (hasEminentRedTask) {
           title = '⚠️ Compromisso Eminente!';
           body = 'Você tem tasks inadiáveis marcadas para hoje.';
        } else if (hasPendingYellow) {
           title = 'Atenção às Pendências';
           body = 'Você possui tasks acumuladas. Vamos resolvê-las?';
        }
        
        await notifService.showNotification(
           id: now.day,
           title: title,
           body: body,
        );
      }
      
      await isar.close();
    } catch (e) {
      debugPrint('Error in background task: $e');
    }
    return Future.value(true);
  });
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized || kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      // iOS: DarwinInitializationSettings(...)
    );
    
    await _flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);
    
    if (Platform.isAndroid) {
       _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
         AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    }
    
    Workmanager().initialize(
        callbackDispatcher,
    );
    
    _initialized = true;
    _schedulePeriodicChecks();
  }
  
  void _schedulePeriodicChecks() {
    Workmanager().registerPeriodicTask(
      "tasktasker_daily_checks",
      "check_routines_and_notify",
      frequency: const Duration(hours: 6), // Check every 6 hours
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );
  }

  Future<void> showNotification({required int id, required String title, required String body}) async {
    if (!_initialized) return;
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'tasktasker_channel', 
      'TaskTasker Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
        
    await _flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }
}
