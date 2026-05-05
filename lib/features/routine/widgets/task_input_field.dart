import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TaskInputField extends StatefulWidget {
  final String placeholder;
  final Function(String) onSubmit;

  const TaskInputField({
    super.key,
    required this.onSubmit,
    this.placeholder = 'Nova task...',
  });

  @override
  State<TaskInputField> createState() => _TaskInputFieldState();
}

class _TaskInputFieldState extends State<TaskInputField> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _active = false;

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isNotEmpty) {
      widget.onSubmit(text);
      _ctrl.clear();
    }
    _focus.unfocus();
    setState(() => _active = false);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _active = true);
        _focus.requestFocus();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _active ? AppColors.surfaceVariant : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _active
                ? AppColors.primary.withOpacity(0.4)
                : AppColors.border.withOpacity(0.4),
            width: 0.5,
          ),
        ),
        child: Row(children: [
          Icon(Icons.add, size: 16,
              color: _active ? AppColors.primary : AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              onTap: () => setState(() => _active = true),
              onSubmitted: (_) => _submit(),
              textInputAction: TextInputAction.done,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: widget.placeholder,
                hintStyle: const TextStyle(
                    color: AppColors.textMuted, fontSize: 14),
              ),
            ),
          ),
          if (_active)
            GestureDetector(
              onTap: _submit,
              child: const Icon(Icons.send_rounded,
                  size: 18, color: AppColors.primary),
            ),
        ]),
      ),
    );
  }
}
