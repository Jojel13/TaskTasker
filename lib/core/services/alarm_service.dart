import 'dart:typed_data';
import 'package:flutter/material.dart' show Color;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../../shared/models/task.dart';
import '../../shared/models/enums.dart';
import '../utils/blue_cadence.dart';
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

    // Canais de alarme (Android). Canais são imutáveis após criados, por isso
    // o som de despertador exige um id novo (v2) em vez do antigo 'task_alarms'.
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    for (final channel in alarmChannels) {
      await android?.createNotificationChannel(channel);
    }
    // Remove o canal legado (som de notificação comum)
    await android?.deleteNotificationChannel(channelId: 'task_alarms');
  }

  static const String alarmChannelId = 'task_alarms_v2';
  static const String alarmSilentChannelId = 'task_alarms_silent_v2';

  /// Canais compartilhados com o [NotificationService] (fonte única).
  static final List<AndroidNotificationChannel> alarmChannels = [
    const AndroidNotificationChannel(
      alarmChannelId,
      '⏰ Alarme de Task',
      description: 'Alarmes individuais configurados para cada tarefa',
      importance: Importance.max,
      playSound: true,
      sound: UriAndroidNotificationSound('content://settings/system/alarm_alert'),
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    ),
    const AndroidNotificationChannel(
      alarmSilentChannelId,
      '⏰ Alarme de Task (silencioso)',
      description: 'Alarmes sem som (preferência "som do alarme" desativada)',
      importance: Importance.max,
      playSound: false,
      enableVibration: true,
    ),
  ];

  // ─── Agendar alarme ───────────────────────────────────────────────

  /// Agenda uma (ou três) notificação(ões) para a task.
  /// Chama [cancelAlarm] antes de agendar para evitar duplicatas.
  /// [soundEnabled] respeita a preferência do usuário (UserProfile.alarmSoundEnabled).
  static Future<void> scheduleAlarm(Task task, {bool soundEnabled = true}) async {
    if (task.alarmTime == null) return;

    await cancelAlarm(task.id);

    final alarmAt = task.alarmTime!;
    final now = DateTime.now();

    // Se o horário já passou, não agendar
    if (alarmAt.isBefore(now)) return;

    // Converter para TZDateTime no fuso local
    final tz.TZDateTime tzAlarm = tz.TZDateTime.from(alarmAt, tz.local);

    // ── Notificação principal ──────────────────────────────────────────────────────
    await _plugin.zonedSchedule(
      id: _notifId(task.id, 0),
      title: '⏰ ${task.text}',
      body: _body(task, 1),
      scheduledDate: tzAlarm,
      notificationDetails: _details(task, 1, soundEnabled: soundEnabled),
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
          notificationDetails: _details(task, i + 1, soundEnabled: soundEnabled),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'complete_task_${task.id}',
        );
      }
    }
  }

  // ─── Agendar Soneca ───────────────────────────────────────────────

  /// Soneca em slot dedicado (3): não altera o `alarmTime` persistido.
  /// [payload] permite manter o vínculo com um hábito (`habit_alarm_<id>`).
  static Future<void> scheduleSnooze(Task task, int minutes,
      {bool soundEnabled = true, String? payload}) async {
    final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
    final tzAlarm = tz.TZDateTime.from(snoozeTime, tz.local);

    await _plugin.zonedSchedule(
      id: _notifId(task.id, 3), // slot 3 para soneca
      title: '⏰ Soneca: ${task.text}',
      body: 'Toque para abrir o TaskTasker',
      scheduledDate: tzAlarm,
      notificationDetails: _details(task, 1, soundEnabled: soundEnabled),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload ?? 'complete_task_${task.id}',
    );
  }

  // ─── Cancelar alarme ──────────────────────────────────────────────

  /// Cancela os slots 0-2 (alarme + repetições) e 3 (soneca) de uma task.
  static Future<void> cancelAlarm(int taskId) async {
    for (int i = 0; i <= 3; i++) {
      await _plugin.cancel(id: _notifId(taskId, i));
    }
  }

  /// Cancela tudo de uma task: alarme, repetições, soneca e aviso das 8h.
  static Future<void> cancelAllForTask(int taskId) async {
    await cancelAlarm(taskId);
    await cancelRedTaskNotification(taskId);
  }

  // ─── Alarmes de hábito (independem da rotina do dia existir) ──────
  //
  // A rotina só é criada quando o usuário toca no "+". Para que o alarme de
  // uma task azul toque mesmo assim, pré-agendamos os próximos dias elegíveis
  // vinculados ao habitId. Quando a rotina do dia é criada, o slot do dia é
  // cancelado e substituído pelo alarme da cópia (com id de task real).

  static const int habitWindowDays = 7;

  static int _habitHash(String habitId) {
    // FNV-1a 32 bits: estável entre execuções (String.hashCode não é garantido)
    int h = 0x811c9dc5;
    for (final c in habitId.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h;
  }

  static int _habitNotifId(String habitId, DateTime day) {
    final dayIndex = DateTime.utc(day.year, day.month, day.day)
            .millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    return 300000000 + (_habitHash(habitId) % 1000000) * 10 + (dayIndex % 8);
  }

  static String habitPayload(String habitId) => 'habit_alarm_$habitId';

  /// Re-agenda a janela de [habitWindowDays] dias do hábito representado por
  /// [sample] (cópia mais recente). Se [includeToday] for false, o slot de hoje
  /// é apenas cancelado (a rotina de hoje já possui a cópia com alarme próprio).
  static Future<void> refreshHabitAlarms(
    Task sample, {
    required bool includeToday,
    bool soundEnabled = true,
  }) async {
    final habitId = sample.habitId;
    if (habitId == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int d = 0; d <= habitWindowDays; d++) {
      final day = today.add(Duration(days: d));
      final id = _habitNotifId(habitId, day);
      await _plugin.cancel(id: id);

      if (d == 0 && !includeToday) continue;
      if (sample.alarmTime == null || sample.color != TaskColor.blue) continue;
      if (!BlueCadence.isEligibleOn(sample, day)) continue;

      final at = DateTime(day.year, day.month, day.day,
          sample.alarmTime!.hour, sample.alarmTime!.minute);
      if (!at.isAfter(now)) continue;

      await _plugin.zonedSchedule(
        id: id,
        title: '⏰ ${sample.text}',
        body: 'Toque para abrir o TaskTasker',
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        notificationDetails: _details(sample, 1, soundEnabled: soundEnabled),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: habitPayload(habitId),
      );
    }
  }

  /// Cancela o pré-agendamento de um dia específico (ex.: hábito concluído hoje).
  static Future<void> cancelHabitAlarmForDay(String habitId, DateTime day) async {
    await _plugin.cancel(id: _habitNotifId(habitId, day));
  }

  /// Cancela toda a janela de pré-agendamento de um hábito (encerrado/sem alarme).
  static Future<void> cancelHabitAlarms(String habitId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (int d = -1; d <= habitWindowDays; d++) {
      await _plugin.cancel(id: _habitNotifId(habitId, today.add(Duration(days: d))));
    }
  }

  /// Agenda a notificação para a task vermelha às 8h da manhã na data agendada.
  /// [soundEnabled] respeita a preferência do usuário (UserProfile.alarmSoundEnabled).
  static Future<void> scheduleRedTaskNotification(Task task, {bool soundEnabled = true}) async {
    if (task.color != TaskColor.red || task.scheduledDate == null) return;

    final notifId = _notifId(task.id, 9); // slot 9 para task vermelha
    await cancelRedTaskNotification(task.id);

    // Escolha do usuário: a vermelha com alarme pontual recebe as duas — este
    // aviso das 8h (notificação comum) e depois o alarme no horário definido.

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
      notificationDetails: _redTaskDetails(task, soundEnabled: soundEnabled),
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

  /// ID \u00fanico por (taskId, slotIndex). Come\u00e7a em 100000 para
  /// n\u00e3o colidir com o NotificationService (que usa IDs baixos: 888, 998, 999, etc).
  /// F\u00f3rmula: 100000 + (taskId % 2000000) * 10 + slot
  /// Garante espa\u00e7o seguro at\u00e9 taskId ~200000 antes de qualquer risco de colis\u00e3o.
  static int _notifId(int taskId, int slot) =>
      (100000 + (taskId.abs() % 200000) * 10 + slot) % 2147483647;

  static String _body(Task task, int shot) {
    if (!task.alarmRepeat) return 'Toque para abrir o TaskTasker';
    return 'Disparo $shot/3 · ${shot < 3 ? "Próximo em 5 min" : "Último lembrete"}';
  }

  static NotificationDetails _details(Task task, int shot, {bool soundEnabled = true}) {
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
      soundEnabled ? alarmChannelId : alarmSilentChannelId,
      soundEnabled ? '⏰ Alarme de Task' : '⏰ Alarme de Task (silencioso)',
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
      playSound: soundEnabled,
      styleInformation: bigTextStyleInfo,
      fullScreenIntent: task.alarmFullScreen,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      // FLAG_INSISTENT=4
      additionalFlags: Int32List.fromList(<int>[4]),
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

  static NotificationDetails _redTaskDetails(Task task, {bool soundEnabled = true}) {
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
      playSound: soundEnabled,
      styleInformation: bigTextStyleInfo,
      ongoing: isToday,
      // O aviso das 8h é uma notificação comum; o despertador (tela cheia,
      // insistente) fica a cargo do alarme pontual da task, se configurado.
      category: AndroidNotificationCategory.reminder,
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
