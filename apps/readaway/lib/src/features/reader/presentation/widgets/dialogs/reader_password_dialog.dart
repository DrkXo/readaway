import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:readaway/src/core/theme/theme.dart';

/// Modal dialog prompting the user to enter a password for encrypted documents.
class ReaderPasswordDialog extends StatefulWidget {
  const ReaderPasswordDialog({
    super.key,
    required this.fileName,
    required this.isInvalidPassword,
    required this.onUnlock,
    required this.onCancel,
  });

  final String fileName;
  final bool isInvalidPassword;
  final ValueChanged<String> onUnlock;
  final VoidCallback onCancel;

  /// Convenience method to display the password dialog as an adaptive modal.
  static Future<void> show({
    required BuildContext context,
    required String fileName,
    required bool isInvalidPassword,
    required ValueChanged<String> onUnlock,
    required VoidCallback onCancel,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ReaderPasswordDialog(
        fileName: fileName,
        isInvalidPassword: isInvalidPassword,
        onUnlock: onUnlock,
        onCancel: onCancel,
      ),
    );
  }

  @override
  State<ReaderPasswordDialog> createState() => _ReaderPasswordDialogState();
}

class _ReaderPasswordDialogState extends State<ReaderPasswordDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text;
    if (text.isNotEmpty) {
      widget.onUnlock(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Dialog(
      backgroundColor: appColors.sheetBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: appColors.borderSubtle, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.lock,
                      size: 20,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password Protected',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: appColors.sidebarTitleForeground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: appColors.sidebarForeground.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'This document is encrypted. Please enter the password to unlock it.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: appColors.sidebarForeground.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                obscureText: _obscureText,
                autocorrect: false,
                enableSuggestions: false,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter password',
                  errorText: widget.isInvalidPassword ? 'Incorrect password. Please try again.' : null,
                  prefixIcon: const Icon(LucideIcons.keyRound, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? LucideIcons.eye : LucideIcons.eyeOff,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Unlock'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
