import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/services/tts/importer/custom_tts_model_importer_service.dart';
import '../../../../../core/services/tts/tts_models.dart';
import '../../bloc/settings/settings_bloc.dart';

class CustomTtsImportDialog extends StatefulWidget {
  const CustomTtsImportDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CustomTtsImportDialog(),
    );
  }

  @override
  State<CustomTtsImportDialog> createState() => _CustomTtsImportDialogState();
}

class _CustomTtsImportDialogState extends State<CustomTtsImportDialog> {
  final _importer = GetIt.instance<CustomTtsModelImporterService>();
  final _nameController = TextEditingController();
  final _langCodeController = TextEditingController(text: 'en-US');
  final _langLabelController = TextEditingController(text: 'English');

  CustomModelInspectionResult? _inspection;
  SherpaTtsModelType? _selectedType;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _langCodeController.dispose();
    _langLabelController.dispose();
    if (_inspection != null) {
      _importer.cleanupInspection(_inspection!);
    }
    super.dispose();
  }

  Future<void> _pickArchive() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'tar', 'bz2', 'gz', 'tgz', 'tbz2'],
      );
      if (result.isEmpty || result.first.path == null) return;
      await _inspect(result.first.path!);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to select file: $e');
    }
  }

  Future<void> _pickFolder() async {
    try {
      final dirPath = await FilePicker.getDirectoryPath();
      if (dirPath == null) return;
      await _inspect(dirPath);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to select folder: $e');
    }
  }

  Future<void> _inspect(String path) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final inspection = await _importer.inspectSource(path);
      setState(() {
        _inspection = inspection;
        _selectedType = inspection.detectedType;
        _nameController.text = inspection.suggestedDisplayName;
        _langCodeController.text = inspection.suggestedLanguageCode;
        _langLabelController.text = inspection.suggestedLanguageLabel;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _confirmImport() {
    if (_inspection == null) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please provide a voice name.');
      return;
    }

    final inspection = _inspection!;
    _inspection = null; // Ownership transferred to BLoC

    context.read<SettingsBloc>().add(
      SettingsEvent.importCustomTtsModel(
        inspection: inspection,
        displayName: name,
        languageCode: _langCodeController.text.trim(),
        languageLabel: _langLabelController.text.trim(),
        typeOverride: _selectedType,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(LucideIcons.fileAudio, size: 22),
          SizedBox(width: 10),
          Text('Import Custom TTS Voice'),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_inspection == null && !_isLoading) ...[
                Text(
                  'Import custom Sherpa-ONNX voice models (.tar.bz2, .zip, or folder containing .onnx and tokens.txt).',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(LucideIcons.fileArchive, size: 18),
                        label: const Text('Pick Archive'),
                        onPressed: _pickArchive,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(LucideIcons.folder, size: 18),
                        label: const Text('Pick Folder'),
                        onPressed: _pickFolder,
                      ),
                    ),
                  ],
                ),
              ],
              if (_isLoading) ...[
                const SizedBox(height: 32),
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Inspecting and validating model files…'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
              if (_inspection != null && !_isLoading) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.checkCircle2,
                            size: 16,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Valid Model Detected',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Architecture: ${_selectedType?.name.toUpperCase()} • Size: ${_inspection!.approxSizeMb} MB',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        'ONNX Models: ${_inspection!.onnxFiles.join(", ")}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Voice Display Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _langLabelController,
                        decoration: const InputDecoration(
                          labelText: 'Language Label',
                          hintText: 'English',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _langCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Language Code',
                          hintText: 'en-US',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<SherpaTtsModelType>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Model Architecture',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: SherpaTtsModelType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedType = val);
                  },
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.alertTriangle,
                        size: 16,
                        color: scheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (_inspection != null)
          FilledButton.icon(
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Import Voice'),
            onPressed: _confirmImport,
          ),
      ],
    );
  }
}
