import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../error/failures.dart';

/// Contextual full-page or contained error view driven by a domain [Failure].
///
/// Automatically determines the appropriate icon, title, description, and
/// recovery actions using Dart 3 pattern matching over [Failure] subtypes.
class FailureView extends StatefulWidget {
  const FailureView({
    super.key,
    required this.failure,
    this.onRetry,
    this.retryLabel = 'Try Again',
    this.onSecondaryAction,
    this.secondaryActionLabel,
    this.compact = false,
  });

  final Failure failure;
  final VoidCallback? onRetry;
  final String retryLabel;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionLabel;
  final bool compact;

  @override
  State<FailureView> createState() => _FailureViewState();
}

class _FailureViewState extends State<FailureView> {
  bool _showDetails = false;

  ({
    IconData icon,
    String title,
    String description,
    String? suggestedSecondaryLabel,
  }) _resolvePresentation(Failure failure) {
    return switch (failure) {
      DocumentNotFoundFailure() => (
        icon: LucideIcons.fileX,
        title: 'Document Not Found',
        description:
            'The requested file could not be found or has been moved.',
        suggestedSecondaryLabel: 'Open Another File',
      ),
      UnsupportedDocumentFormatFailure(:final format) => (
        icon: LucideIcons.fileQuestion,
        title: 'Unsupported Format ($format)',
        description:
            'This document format is not supported. Supported formats include PDF, EPUB, FB2, CBZ, XPS, and TXT.',
        suggestedSecondaryLabel: 'Choose Another File',
      ),
      CorruptDocumentFailure() => (
        icon: LucideIcons.fileWarning,
        title: 'Corrupt Document',
        description:
            'Unable to parse or read this document file. It may be incomplete or corrupted.',
        suggestedSecondaryLabel: 'Choose Another File',
      ),
      DocumentParseFailure() => (
        icon: LucideIcons.codeXml,
        title: 'Parsing Error',
        description:
            'Failed to render the document contents into reader elements.',
        suggestedSecondaryLabel: null,
      ),
      DocumentCancelledFailure() => (
        icon: LucideIcons.file,
        title: 'No Document Selected',
        description: 'Document selection was cancelled.',
        suggestedSecondaryLabel: 'Select Document',
      ),
      StorageReadFailure() || StorageWriteFailure() || StorageResetFailure() => (
        icon: LucideIcons.database,
        title: 'Storage Error',
        description:
            'Failed to read or write local data. Storage might be restricted or full.',
        suggestedSecondaryLabel: 'Reset Preferences',
      ),
      NoInternetFailure() => (
        icon: LucideIcons.wifiOff,
        title: 'No Internet Connection',
        description:
            'An internet connection is required to complete this request.',
        suggestedSecondaryLabel: null,
      ),
      NetworkTimeoutFailure() => (
        icon: LucideIcons.clockAlert,
        title: 'Connection Timed Out',
        description:
            'The remote server took too long to respond. Please check your connection and try again.',
        suggestedSecondaryLabel: null,
      ),
      ServerFailure(:final statusCode) => (
        icon: LucideIcons.serverCrash,
        title: 'Server Error${statusCode != null ? ' ($statusCode)' : ''}',
        description:
            'The remote service returned an error. Please try again later.',
        suggestedSecondaryLabel: null,
      ),
      TtsModelNotFoundFailure(:final modelId) => (
        icon: LucideIcons.botOff,
        title: 'Voice Model Missing',
        description: 'Voice model "$modelId" is not installed or available.',
        suggestedSecondaryLabel: 'Open Voice Settings',
      ),
      TtsDownloadFailure() => (
        icon: LucideIcons.downloadCloud,
        title: 'Voice Download Failed',
        description:
            'Failed to download the selected voice model. Please check your connection.',
        suggestedSecondaryLabel: 'Try Again',
      ),
      TtsSynthesisFailure() || TtsWorkerFailure() => (
        icon: LucideIcons.speech,
        title: 'Speech Engine Error',
        description:
            'Text-to-speech synthesis failed. Ensure a voice model is selected and ready.',
        suggestedSecondaryLabel: 'Voice Settings',
      ),
      AudioPlaybackFailure() || AudioDeviceFailure() => (
        icon: LucideIcons.volumeX,
        title: 'Audio Playback Error',
        description: 'Unable to route or play audio through device speakers.',
        suggestedSecondaryLabel: null,
      ),
      StoragePermissionDeniedFailure() || NotificationPermissionDeniedFailure() => (
        icon: LucideIcons.shieldAlert,
        title: 'Permission Denied',
        description:
            'App permissions are required to perform this action. Please check your system settings.',
        suggestedSecondaryLabel: 'Settings',
      ),
      _ => (
        icon: LucideIcons.alertTriangle,
        title: 'Unexpected Error',
        description: failure.message.isNotEmpty
            ? failure.message
            : 'An unexpected issue occurred.',
        suggestedSecondaryLabel: null,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final info = _resolvePresentation(widget.failure);

    final secondaryLabel =
        widget.secondaryActionLabel ?? info.suggestedSecondaryLabel;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(widget.compact ? 16 : 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error Icon Badge
                Container(
                  padding: EdgeInsets.all(widget.compact ? 12 : 18),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    info.icon,
                    size: widget.compact ? 28 : 40,
                    color: scheme.error,
                  ),
                ),
                SizedBox(height: widget.compact ? 12 : 20),

                // Title
                Text(
                  info.title,
                  textAlign: TextAlign.center,
                  style: (widget.compact
                          ? Theme.of(context).textTheme.titleMedium
                          : Theme.of(context).textTheme.titleLarge)
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  info.description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),

              // Actions
              if (widget.onRetry != null || widget.onSecondaryAction != null) ...[
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (widget.onRetry != null)
                      FilledButton.icon(
                        onPressed: widget.onRetry,
                        icon: const Icon(LucideIcons.refreshCw, size: 16),
                        label: Text(widget.retryLabel),
                      ),
                    if (widget.onSecondaryAction != null && secondaryLabel != null)
                      OutlinedButton(
                        onPressed: widget.onSecondaryAction,
                        child: Text(secondaryLabel),
                      ),
                  ],
                ),
              ],

              // Technical Details Collapsible (for debug / troubleshooting)
              if (widget.failure.cause != null || kDebugMode) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => _showDetails = !_showDetails),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _showDetails ? 'Hide Diagnostics' : 'View Diagnostics',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Icon(
                        _showDetails
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
                if (_showDetails)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: SelectableText(
                      '${widget.failure}\n'
                      '${widget.failure.stackTrace != null ? '\nStack Trace:\n${widget.failure.stackTrace}' : ''}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
}
