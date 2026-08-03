import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/theme_config.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/routine.dart';
import '../../shared/models/routine_day.dart';
import '../../shared/widgets/xp_bar.dart';
import 'widgets/division_section.dart';
import 'widgets/routine_export_widget.dart';

class RoutineScreen extends ConsumerStatefulWidget {
  final Routine routine;
  /// Se informado, a tela fará scroll até o card da task com esse ID após carregar.
  final int? scrollToTaskId;

  const RoutineScreen({super.key, required this.routine, this.scrollToTaskId});

  @override
  ConsumerState<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends ConsumerState<RoutineScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _taskKeys = {};
  bool _hasScrolled = false; // A17: flag para scroll único
  final GlobalKey _exportBoundaryKey = GlobalKey();

  Future<void> _exportAsImage(AppThemeData theme, List<RoutineDay> days) async {
    // BUG-04: capturar theme localmente no início para evitar uso stale no catch
    final localTheme = theme;
    try {
      final boundary = _exportBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/routine_${widget.routine.id}.png').create();
      await file.writeAsBytes(pngBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Confira minha rotina de hoje no TaskTasker! 🐸',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar imagem: $e', style: localTheme.fontStyleBase(const TextStyle(color: Colors.white))),
            backgroundColor: localTheme.taskRed,
          ),
        );
      }
    }
  }

  bool get _isToday {
    final now = DateTime.now();
    return widget.routine.date.year == now.year &&
        widget.routine.date.month == now.month &&
        widget.routine.date.day == now.day;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTask(int taskId) {
    if (_hasScrolled) return; // A17: só executa uma vez
    _hasScrolled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _taskKeys[taskId];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.3,
        );
      }
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isToday) return;
    if (!ref.read(isDraggingTaskProvider)) return;

    final screenHeight = MediaQuery.of(context).size.height;
    final y = event.position.dy;
    
    // Limite de 120 pixels para começar a rolar
    const threshold = 120.0;
    
    if (y < threshold) {
      final speed = ((threshold - y) / threshold * 15).clamp(2.0, 15.0);
      if (_scrollController.hasClients) {
        final target = (_scrollController.offset - speed).clamp(0.0, _scrollController.position.maxScrollExtent);
        _scrollController.jumpTo(target);
      }
    } else if (y > screenHeight - threshold) {
      final speed = ((y - (screenHeight - threshold)) / threshold * 15).clamp(2.0, 15.0);
      if (_scrollController.hasClients) {
        final target = (_scrollController.offset + speed).clamp(0.0, _scrollController.position.maxScrollExtent);
        _scrollController.jumpTo(target);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = ref.watch(currentThemeProvider);
    final daysAsync = ref.watch(routineDaysProvider(widget.routine.id));
    final dateStr = DateFormat("EEEE, dd 'de' MMMM", 'pt_BR').format(widget.routine.date);

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(children: [
          // ── AppBar ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 20, color: theme.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.routine.name,
                          style: theme.fontStyleBase(AppTextStyles.titleLarge),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.primary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'HOJE',
                            style: theme.fontStyleMono(TextStyle(
                              color: theme.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            )),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(dateStr,
                      style: theme.fontStyleBase(AppTextStyles.labelSmall)
                          .copyWith(color: theme.textMuted)),
                ]),
              ),
              IconButton(
                icon: Icon(Icons.share_rounded, color: theme.primary, size: 20),
                onPressed: () async {
                  final daysState = ref.read(routineDaysProvider(widget.routine.id));
                  if (daysState.hasValue) {
                    await _exportAsImage(theme, daysState.value!);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Carregando dados da rotina...', style: theme.fontStyleBase(const TextStyle(color: Colors.white))),
                        backgroundColor: theme.taskYellow,
                      ),
                    );
                  }
                },
              ),
              if (!_isToday) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.secondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: theme.secondary.withValues(alpha: 0.25)),
                  ),
                  child: Text('Histórico',
                      style: theme.fontStyleBase(TextStyle(
                          color: theme.secondary, fontSize: 11))),
                ),
              ],
            ]),
          ),

          // ── XP Bar ─────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: XpBar(),
          ),

          // ── Content ─────────────────────────────────────────
          Expanded(
            child: Listener(
              onPointerMove: _onPointerMove,
              child: Stack(
                children: [
                  if (daysAsync.hasValue)
                    Positioned(
                      left: -9999,
                      top: -9999,
                      child: RepaintBoundary(
                        key: _exportBoundaryKey,
                        child: SizedBox(
                          width: 360,
                          child: RoutineExportWidget(
                            routine: widget.routine,
                            days: daysAsync.value!,
                            theme: theme,
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: daysAsync.when(
                      loading: () => Center(
                          child: CircularProgressIndicator(color: theme.secondary)),
                      error: (e, _) => Center(
                          child: Text('Erro: $e',
                              style: theme.fontStyleBase(TextStyle(color: theme.taskRed)))),
                      data: (days) {
                        // A18: remover keys obsoletas de tasks que não existem mais
                        final currentTaskIds = days.expand((d) => d.tasks.map((t) => t.id)).toSet();
                        _taskKeys.removeWhere((id, _) => !currentTaskIds.contains(id));
  
                        // A17: scroll automático apenas na primeira carga
                        if (widget.scrollToTaskId != null) {
                          _scrollToTask(widget.scrollToTaskId!);
                        }
                        return ListView(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          children: days.map((day) => DivisionSection(
                            routine: widget.routine,
                            day: day,
                            isToday: _isToday,
                            taskKeys: _taskKeys,
                          )).toList(),
                        );
                      },
                    ),
                  ),
                  
                  // Efeito Glass para Histórico (rotinas antigas)
                  if (!_isToday)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ClipRect(
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                            child: Container(
                              color: theme.background.withValues(alpha: 0.15),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
