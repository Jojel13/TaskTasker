import 'dart:typed_data';
import 'package:flutter/material.dart' show Color;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../../shared/models/task.dart';
import '../../shared/models/enums.dart';
import 'notification_service.dart';

/// Serviço de alarmes individuais por task (Fase 3)
///
/// Usa flutter_local_notifications v21+ com timezone para agendar
/// notificações pontuais. Suporta "repetir 3x a cada 5 min".
class AlarmService {
  static FlutterLocalNotificationsPlugin get _plugin =>
      NotificationService.instance.plugin;

  static bool _initialized = false;

  // ─── Inicialização ────────────────────────────────────────────────

  /// Deve ser chamado em main(), após [NotificationService.initialize()].
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Inicializar dados de timezone
    tz_data.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (e) {
      debugPrint('Error setting local timezone: $e');
    }

    // Criar canal de alta importância no Android
    const androidChannel = AndroidNotificationChannel(
      'task_alarms',
      'Alarmes de Tasks',
      description: 'Alarmes individuais do TaskTasker',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // ─── Agendar alarme ───────────────────────────────────────────────

  /// Agenda uma (ou três) notificação(ões) para a task.
  /// Chama [cancelAlarm] antes de agendar para evitar duplicatas.
  static Future<void> scheduleAlarm(Task task) async {
    if (task.alarmTime == null) return;

    await cancelAlarm(task.id);

    final alarmAt = task.alarmTime!;
    final now = DateTime.now();

    // Se o horário já passou, não agendar
    if (alarmAt.isBefore(now)) return;

    // Converter para TZDateTime no fuso local
    final tz.TZDateTime tzAlarm = tz.TZDateTime.from(alarmAt, tz.local);

    // ── Notificação principal ───────────────────────────────────────
    await _plugin.zonedSchedule(
      id: _notifId(task.id, 0),
      title: '⏰ ${task.text}',
      body: _body(task, 1),
      scheduledDate: tzAlarm,
      notificationDetails: _details(task, 1),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'complete_task_${task.id}',
    );

    // ── Notificações repetidas (2 disparos extras a +5 e +10 min) ──
    if (task.alarmRepeat) {
      for (int i = 1; i <= 2; i++) {
        final tz.TZDateTime tzRepeat = tzAlarm.add(Duration(minutes: 5 * i));
        await _plugin.zonedSchedule(
          id: _notifId(task.id, i),
          title: '⏰ ${task.text} (${i + 1}/3)',
          body: _body(task, i + 1),
          scheduledDate: tzRepeat,
          notificationDetails: _details(task, i + 1),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'complete_task_${task.id}',
        );
      }
    }
  }

  // ─── Cancelar alarme ──────────────────────────────────────────────

  /// Cancela todas as notificações pendentes de uma task (até 3 slots).
  static Future<void> cancelAlarm(int taskId) async {
    for (int i = 0; i <= 2; i++) {
      await _plugin.cancel(id: _notifId(taskId, i));
    }
  }

  /// Agenda a notificação para a task vermelha às 8h da manhã na data agendada
  static Future<void> scheduleRedTaskNotification(Task task) async {
    if (task.color != TaskColor.red || task.scheduledDate == null) return;

    final notifId = _notifId(task.id, 9); // slot 9 para task vermelha
    await cancelRedTaskNotification(task.id);

    final scheduledDay = task.scheduledDate!;
    // Criar a data agendada para 8:00 AM no timezone local
    final alarmAt = DateTime(
      scheduledDay.year,
      scheduledDay.month,
      scheduledDay.day,
      8,
      0,
    );

    final now = DateTime.now();
    if (alarmAt.isBefore(now)) return; // Se já passou, não agendar

    final tzAlarm = tz.TZDateTime.from(alarmAt, tz.local);

    await _plugin.zonedSchedule(
      id: notifId,
      title: '⚠️ Compromisso Eminente!',
      body: 'Compromisso hoje: ${task.text}',
      scheduledDate: tzAlarm,
      notificationDetails: _redTaskDetails(task),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'complete_task_${task.id}',
    );
  }

  /// Cancela a notificação de task vermelha (slot 9)
  static Future<void> cancelRedTaskNotification(int taskId) async {
    await _plugin.cancel(id: _notifId(taskId, 9));
  }

  // ─── Solicitar permissão (Android 13+) ───────────────────────────

  static Future<bool> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  // ─── Helpers ─────────────────────────────────────────────────────

  /// ID único por (taskId, slotIndex). Começa em 10000 para
  /// não colidir com o NotificationService (que usa IDs baixos).
  static int _notifId(int taskId, int slot) =>
      (10000 + (taskId * 10 + slot).abs()) % 2147483647;

  static String _body(Task task, int shot) {
    if (!task.alarmRepeat) return 'Toque para abrir o TaskTasker';
    return 'Disparo $shot/3 · ${shot < 3 ? "Próximo em 5 min" : "Último lembrete"}';
  }

  static NotificationDetails _details(Task task, int shot) {
    Color ledColor;
    if (shot > 1) {
      ledColor = const Color(0xFFFF9500); // Âmbar para repetições
    } else {
      switch (task.color) {
        case TaskColor.red:
          ledColor = const Color(0xFFFF2D55);
          break;
        case TaskColor.yellow:
          ledColor = const Color(0xFFFFCC00);
          break;
        case TaskColor.blue:
        case TaskColor.standard:
          ledColor = const Color(0xFF007AFF);
          break;
      }
    }

    final Int64List vibrationPattern = Int64List.fromList([0, 500, 200, 500]);
    final timeStr = task.alarmTime != null 
        ? '${task.alarmTime!.hour.toString().padLeft(2, '0')}:${task.alarmTime!.minute.toString().padLeft(2, '0')}' 
        : '';

    final bigTextStyleInfo = BigTextStyleInformation(
      'Compromisso: ${task.text}\nHorário: $timeStr\nStatus: Pendente',
      htmlFormatBigText: false,
      contentTitle: shot > 1 ? '⏰ Alarme (Repetição $shot/3)' : '⏰ Alarme de Task',
      htmlFormatContentTitle: false,
      summaryText: 'TaskTasker Alarme',
      htmlFormatSummaryText: false,
    );

    final androidDetails = AndroidNotificationDetails(
      'task_alarms',
      '⏰ Alarme de Task',
      channelDescription: 'Alarmes individuais configurados para cada tarefa',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: ledColor,
      enableLights: true,
      ledColor: ledColor,
      ledOnMs: 1000,
      ledOffMs: 500,
      vibrationPattern: vibrationPattern,
      playSound: true,
      styleInformation: bigTextStyleInfo,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'action_complete_task',
          '✓ Concluir',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  static NotificationDetails _redTaskDetails(Task task) {
    final Int64List vibrationPattern = Int64List.fromList([0, 800, 300, 800, 300, 800]);
    
    final now = DateTime.now();
    final isToday = task.scheduledDate != null &&
        task.scheduledDate!.year == now.year &&
        task.scheduledDate!.month == now.month &&
        task.scheduledDate!.day == now.day;
        
    final dateFormatted = task.scheduledDate != null
        ? '${task.scheduledDate!.day.toString().padLeft(2, '0')}/${task.scheduledDate!.month.toString().padLeft(2, '0')}/${task.scheduledDate!.year}'
        : '';

    final bigTextStyleInfo = BigTextStyleInformation(
      'Compromisso para hoje: $dateFormatted\nEsta é uma tarefa urgente e inadiável. Conclua hoje!',
      htmlFormatBigText: false,
      contentTitle: '⚠️ ${task.text}',
      htmlFormatContentTitle: false,
      summaryText: 'Compromisso Urgente',
      htmlFormatSummaryText: false,
    );

    final androidDetails = AndroidNotificationDetails(
      'task_red_alert',
      '🔴 Compromisso Urgente',
      channelDescription: 'Notificações para tarefas vermelhas inadiáveis',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFFF3B30),
      enableLights: true,
      ledColor: const Color(0xFFFF3B30),
      ledOnMs: 1000,
      ledOffMs: 500,
      vibrationPattern: vibrationPattern,
      playSound: true,
      styleInformation: bigTextStyleInfo,
      ongoing: isToday,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'action_complete_task',
          '✓ Concluir',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }
}
