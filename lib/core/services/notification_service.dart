import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color, ValueNotifier;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart' hide TaskStatus;
import 'package:path_provider/path_provider.dart';
import 'package:isar/isar.dart';
import '../database/isar_service.dart';
import '../../shared/models/routine.dart';
import '../../shared/models/routine_day.dart';
import '../../shared/models/task.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/models/xp_event.dart';

/// P3: Notifier global que comunica ao UI qual taskId foi tocado na notificação.
/// Quando o usuário toca no corpo da notificação (não no botão inline),
/// este notifier recebe o ID. O [MainWrapper] escuta e navega para a task.
/// O valor é null quando não há navegação pendente.
final ValueNotifier<int?> pendingTaskIdNotifier = ValueNotifier<int?>(null);

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  if (response.actionId == 'action_complete_task' && response.payload != null) {
    final taskIdStr = response.payload!.replaceFirst('complete_task_', '');
    final taskId = int.tryParse(taskIdStr);
    if (taskId != null) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final isar = await Isar.open(
          [RoutineSchema, RoutineDaySchema, TaskSchema, UserProfileSchema, XPEventSchema],
          directory: dir.path,
          name: 'tasktasker_db',
        );
        
        final task = await isar.tasks.get(taskId);
        if (task != null && task.status != TaskStatus.completed) {
          await isar.writeTxn(() async {
            task.status = TaskStatus.completed;
            task.completedOnDate = DateTime.now();
            await isar.tasks.put(task);
            
            final profile = await isar.userProfiles.get(1);
            if (profile != null) {
              int xpGained = 10;
              if (task.color == TaskColor.red) {
                xpGained = 20;
              } else if (task.color == TaskColor.yellow) {
                xpGained = 15;
              }
              
              profile.totalXP += xpGained;
              int nextLevelXp = profile.currentLevel * 100;
              while (profile.totalXP >= nextLevelXp) {
                profile.totalXP -= nextLevelXp;
                profile.currentLevel++;
                nextLevelXp = profile.currentLevel * 100;
              }
              await isar.userProfiles.put(profile);
              
              final xpEvent = XPEvent()
                ..amount = xpGained
                ..description = 'Concluiu task via notificação: ${task.text}'
                ..earnedAt = DateTime.now();
              await isar.xPEvents.put(xpEvent);
            }
          });
        }
        await isar.close();
      } catch (e) {
        debugPrint('Error in notificationTapBackground: $e');
      }
    }
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final notifService = NotificationService.instance;
      await notifService.initializeForBackground();
      
      // Init ISAR in background isolate
      final dir = await getApplicationDocumentsDirectory();
      final isar = await Isar.open(
        [RoutineSchema, RoutineDaySchema, TaskSchema, UserProfileSchema, XPEventSchema],
        directory: dir.path,
        name: 'tasktasker_db',
      );
      
      final profile = await isar.userProfiles.get(1);
      if (profile != null && !profile.notifEnabled) {
        await isar.close();
        return Future.value(true);
      }

      if (task == "weekly_summary_task") {
        await notifService.showWeeklySummaryNotification();
        final delay = calculateDelayUntilNextMonday9AM(DateTime.now());
        await Workmanager().registerOneOffTask(
          "tasktasker_weekly_summary_task",
          "weekly_summary_task",
          initialDelay: delay,
          existingWorkPolicy: ExistingWorkPolicy.replace,
        );
        await isar.close();
        return Future.value(true);
      }
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Find today's routine
      final routine = await isar.routines.filter().dateEqualTo(today).findFirst();
      if (routine != null) {
        await routine.days.load();
        
        int totalRemaining = 0;
        int urgentCount = 0;
        List<String> activeTaskTexts = [];
        TaskColor dominantColor = TaskColor.standard;
        
        for (final day in routine.days) {
          await day.tasks.load();
          for (final t in day.tasks) {
            if (t.status != TaskStatus.completed) {
              totalRemaining++;
              if (t.color == TaskColor.red) {
                urgentCount++;
                dominantColor = TaskColor.red;
              } else if (t.color == TaskColor.yellow) {
                if (dominantColor != TaskColor.red) {
                  dominantColor = TaskColor.yellow;
                }
              } else if (t.color == TaskColor.blue) {
                if (dominantColor != TaskColor.red && dominantColor != TaskColor.yellow) {
                  dominantColor = TaskColor.blue;
                }
              }
              
              if (activeTaskTexts.length < 3) {
                activeTaskTexts.add('• ${t.text}');
              }
            }
          }
        }
        
        if (totalRemaining > 0) {
          Color ledColor;
          switch (dominantColor) {
            case TaskColor.red:
              ledColor = const Color(0xFFFF3B30);
              break;
            case TaskColor.yellow:
              ledColor = const Color(0xFFFFCC00);
              break;
            case TaskColor.blue:
            case TaskColor.standard:
              ledColor = const Color(0xFF007AFF);
              break;
          }
          
          String periodStr = 'dia';
          if (now.hour >= 6 && now.hour < 12) {
            periodStr = 'manhã';
          } else if (now.hour >= 12 && now.hour < 18) {
            periodStr = 'tarde';
          } else {
            periodStr = 'noite';
          }
          
          String title = 'Como está sua rotina nesta $periodStr?';
          String summary = '$totalRemaining tasks restantes • $urgentCount urgentes';
          if (urgentCount == 0) {
            summary = '$totalRemaining tasks restantes';
          }
          
          await notifService.showRichDailyNotification(
            id: now.hour * 60 + now.minute,
            title: title,
            summary: summary,
            lines: activeTaskTexts,
            ledColor: ledColor,
          );
        }
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
  FlutterLocalNotificationsPlugin get plugin => _flutterLocalNotificationsPlugin;
  bool _initialized = false;
  
  Future<void> initializeForBackground() async {
    if (_initialized || kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        _handleForegroundNotificationResponse(response);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Configurar Canais Separados (Android)
    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
            
    if (androidPlugin != null) {
      const List<AndroidNotificationChannel> channels = [
        AndroidNotificationChannel(
          'tasktasker_routine',
          'Lembretes de Rotina',
          description: 'Notificações diárias sobre sua rotina',
          importance: Importance.high,
          playSound: true,
        ),
        AndroidNotificationChannel(
          'task_alarms',
          '⏰ Alarme de Task',
          description: 'Alarmes individuais configurados para cada tarefa',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
        AndroidNotificationChannel(
          'task_red_alert',
          '🔴 Compromisso Urgente',
          description: 'Notificações para tarefas vermelhas inadiáveis',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
        AndroidNotificationChannel(
          'weekly_summary',
          '📊 Resumo Semanal',
          description: 'Recapitulação semanal do seu desempenho',
          importance: Importance.defaultImportance,
          playSound: false,
        ),
      ];

      for (final channel in channels) {
        await androidPlugin.createNotificationChannel(channel);
      }
    }

    _initialized = true;
  }

  /// P3: Handler para respostas de notificações em foreground.
  /// - Boto inline 'action_complete_task' → delega para [notificationTapBackground]
  /// - Toque genérico (sem actionId) → sinaliza [pendingTaskIdNotifier] para navegação
  void _handleForegroundNotificationResponse(NotificationResponse response) {
    if (response.actionId == 'action_complete_task') {
      // Completar task via botão inline (comportamento original)
      notificationTapBackground(response);
      return;
    }

    // Toque genérico no corpo da notificação: navegar para a task
    if (response.payload != null && response.payload!.startsWith('complete_task_')) {
      final taskIdStr = response.payload!.replaceFirst('complete_task_', '');
      final taskId = int.tryParse(taskIdStr);
      if (taskId != null) {
        pendingTaskIdNotifier.value = taskId;
      }
    }
  }

  /// P3: Verifica se há task pendente de navegação ao abrir o app (cold start).
  /// Deve ser chamado no [SplashScreen] após o carregamento do Isar.
  Future<int?> checkLaunchNotification() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return null;
    final details = await _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp == true && details?.notificationResponse?.payload != null) {
      final payload = details!.notificationResponse!.payload!;
      if (payload.startsWith('complete_task_')) {
        final taskIdStr = payload.replaceFirst('complete_task_', '');
        return int.tryParse(taskIdStr);
      }
    }
    return null;
  }

  Future<void> initialize() async {
    if (_initialized || kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    await initializeForBackground();
    
    Workmanager().initialize(
      callbackDispatcher,
    );
    
    _initialized = true;
    
    final isar = IsarService.instance;
    final profile = await isar.userProfiles.get(1);
    final hours = profile?.notificationFrequencyHours ?? 6;
    
    updatePeriodicChecks(hours);
    _scheduleWeeklySummaryTask();
  }
  
  void updatePeriodicChecks(int hours) {
    Workmanager().registerPeriodicTask(
      "tasktasker_daily_checks",
      "check_routines_and_notify",
      frequency: Duration(hours: hours),
      constraints: Constraints(
        requiresBatteryNotLow: true,
      ),
    );
  }

  void _scheduleWeeklySummaryTask() {
    final now = DateTime.now();
    final delay = calculateDelayUntilNextMonday9AM(now);
    Workmanager().registerOneOffTask(
      "tasktasker_weekly_summary_task",
      "weekly_summary_task",
      initialDelay: delay,
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }

  Future<void> showWeeklySummaryNotification() async {
    if (!_initialized) return;

    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'weekly_summary',
      '📊 Resumo Semanal',
      channelDescription: 'Recapitulação semanal do seu desempenho',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: 888,
      title: '📊 Resumo Semanal Disponível!',
      body: 'Seu resumo da semana passada está pronto. Veja o que você conquistou! 🐸',
      notificationDetails: platformChannelSpecifics,
    );
  }

  /// Exibe uma notificação de teste imediata (usada pelo botão "Testar Notificação"
  /// nas Configurações). Usa o canal [tasktasker_routine] já registrado formalmente.
  Future<void> showTestNotification({required int id, required String title, required String body}) async {
    if (!_initialized) return;
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'tasktasker_routine',
      'Lembretes de Rotina',
      channelDescription: 'Notificações diárias sobre sua rotina',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
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

  Future<void> showRichDailyNotification({
    required int id,
    required String title,
    required String summary,
    required List<String> lines,
    required Color ledColor,
  }) async {
    if (!_initialized) return;

    final inboxStyle = InboxStyleInformation(
      lines,
      contentTitle: title,
      summaryText: summary,
    );

    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'tasktasker_routine',
      'Lembretes de Rotina',
      channelDescription: 'Notificações diárias sobre sua rotina',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: ledColor,
      enableLights: true,
      ledColor: ledColor,
      ledOnMs: 1000,
      ledOffMs: 500,
      styleInformation: inboxStyle,
    );

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: summary,
      notificationDetails: platformChannelSpecifics,
    );
  }
}

Duration calculateDelayUntilNextMonday9AM(DateTime now) {
  int daysUntilNextMonday = (DateTime.monday - now.weekday) % 7;
  if (daysUntilNextMonday == 0 && now.hour >= 9) {
    daysUntilNextMonday = 7;
  }
  
  final nextMonday = DateTime(now.year, now.month, now.day)
      .add(Duration(days: daysUntilNextMonday));
      
  final targetTime = DateTime(nextMonday.year, nextMonday.month, nextMonday.day, 9, 0);
  return targetTime.difference(now);
}
