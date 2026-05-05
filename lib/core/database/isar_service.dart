import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../shared/models/routine.dart';
import '../../shared/models/routine_day.dart';
import '../../shared/models/task.dart';
import '../../shared/models/mini_task.dart';
import '../../shared/models/subtask.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/models/xp_event.dart';

/// Serviço singleton de acesso ao ISAR
class IsarService {
  IsarService._();

  static late Isar _isar;

  static Isar get instance => _isar;

  /// Inicializa o banco de dados — deve ser chamado antes do app iniciar
  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();

    _isar = await Isar.open(
      [
        RoutineSchema,
        RoutineDaySchema,
        TaskSchema,
        UserProfileSchema,
        XPEventSchema,
      ],
      directory: dir.path,
      name: 'tasktasker_db',
    );

    // Garante que o UserProfile singleton existe
    await _ensureUserProfile();
  }

  static Future<void> _ensureUserProfile() async {
    final existing = await _isar.userProfiles.get(1);
    if (existing == null) {
      await _isar.writeTxn(() async {
        await _isar.userProfiles.put(UserProfile());
      });
    }
  }

  static Future<void> close() async {
    await _isar.close();
  }
}
