import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/theme_config.dart';
/// Campo de input para adicionar tasks/subtasks/mini-tasks.
///
/// Quando [collapsed] = true (padrão), exibe apenas um botão
/// "+ Adicionar" sutil. Ao tocar, expande para o campo de texto
/// com autofocus. Ao enviar ou perder foco, colapsa de volta.
class TaskInputField extends ConsumerStatefulWidget {
  final String placeholder;
  final Function(String) onSubmit;

  /// Quando true, inicia colapsado como um botão "+ Adicionar".
  /// Quando false, sempre exibe o campo de texto expandido.
  final bool collapsed;

  /// Cor do ícone e da borda quando ativo. Padrão: AppColors.primary.
  final Color? accentColor;

  const TaskInputField({
    super.key,
    required this.onSubmit,
    this.placeholder = 'Nova task...',
    this.collapsed = false,
    this.accentColor,
  });

  @override
  ConsumerState<TaskInputField> createState() => _TaskInputFieldState();
}

class _TaskInputFieldState extends ConsumerState<TaskInputField> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _expanded = false;

  // Se não for colapsável, começa expandido
  bool get _isCollapsable => widget.collapsed;

  Color _getAccent(AppThemeData theme) => widget.accentColor ?? theme.primary;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      // Colapsa quando perde o foco e o campo está vazio
      if (!_focus.hasFocus && _ctrl.text.isEmpty && _isCollapsable) {
        setState(() => _expanded = false);
      }
    });
  }

  void _expand() {
    setState(() => _expanded = true);
    // Pequeno delay para aguardar o widget ser construído antes de focar
    Future.microtask(() => _focus.requestFocus());
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isNotEmpty) {
      HapticFeedback.selectionClick();
      widget.onSubmit(text);
      _ctrl.clear();
    }
    _focus.unfocus();
    if (_isCollapsable) setState(() => _expanded = false);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final accent = _getAccent(theme);

    // ── Modo colapsado: botão "+ Adicionar" ─────────────────────
    if (_isCollapsable && !_expanded) {
      return GestureDetector(
        onTap: _expand,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 14, color: accent.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text(
                _collapsedLabel,
                style: theme.fontStyleBase(TextStyle(
                  color: accent.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                )),
              ),
            ],
          ),
        ),
      );
    }

    // ── Modo expandido: campo de texto ──────────────────────────
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: BorderRadius.circular(theme.borderRadius > 10 ? 10 : theme.borderRadius),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(children: [
        Icon(Icons.add_rounded, size: 16, color: accent),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            onSubmitted: (_) => _submit(),
            textInputAction: TextInputAction.done,
            style: theme.fontStyleBase(TextStyle(color: theme.textPrimary, fontSize: 13)),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: widget.placeholder,
              hintStyle: theme.fontStyleBase(TextStyle(color: theme.textMuted, fontSize: 13)),
            ),
          ),
        ),
        GestureDetector(
          onTap: _submit,
          child: Container(
            padding: const EdgeInsets.all(4),
            child: Icon(Icons.send_rounded, size: 16, color: accent),
          ),
        ),
        if (_isCollapsable)
          GestureDetector(
            onTap: () {
              _ctrl.clear();
              _focus.unfocus();
              setState(() => _expanded = false);
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close_rounded,
                  size: 14, color: theme.textMuted),
            ),
          ),
      ]),
    );
  }

  /// Label do botão colapsado baseado no placeholder
  String get _collapsedLabel {
    if (widget.placeholder.contains('subtask')) return 'Adicionar subtask';
    if (widget.placeholder.contains('mini')) return 'Adicionar mini-task';
    return 'Adicionar';
  }
}
