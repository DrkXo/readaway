import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/routes/routes.dart';
import '../../../../../core/services/tts/tts_models.dart';
import '../../../../../router/router.dart';

/// An interactive, high-performance, accessible voice selection panel for the Full TTS Player.
///
/// Scalability features for large voice catalogs:
/// 1. Auto-scrolls directly to the currently selected voice when opened.
/// 2. Live search bar and language filter chips when more than 4 voices are installed.
/// 3. Bounded, high-performance scroll view with dedicated `ScrollController` avoiding UI jank.
/// 4. Instant 1-tap switching with tactile haptic feedback and active indicator.
/// 5. Clear empty states for no downloaded voices and no search results.
class TtsVoiceSelectionPanel extends StatefulWidget {
  const TtsVoiceSelectionPanel({
    required this.currentVoice,
    required this.availableVoices,
    required this.onVoiceSelected,
    this.onClose,
    super.key,
  });

  /// Currently active voice option.
  final TtsVoiceOption? currentVoice;

  /// List of local voice options available on the device.
  final List<TtsVoiceOption> availableVoices;

  /// Callback triggered when a voice option is tapped.
  final ValueChanged<TtsVoiceOption> onVoiceSelected;

  /// Optional callback to collapse or close the voice panel.
  final VoidCallback? onClose;

  @override
  State<TtsVoiceSelectionPanel> createState() => _TtsVoiceSelectionPanelState();
}

class _TtsVoiceSelectionPanelState extends State<TtsVoiceSelectionPanel> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedLanguageFilter;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToCurrentVoice(),
    );
  }

  @override
  void didUpdateWidget(TtsVoiceSelectionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentVoice != widget.currentVoice) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToCurrentVoice(),
      );
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query != _searchQuery) {
      setState(() => _searchQuery = query);
    }
  }

  void _scrollToCurrentVoice() {
    if (!_scrollController.hasClients || widget.currentVoice == null) return;
    final voices = _filteredVoices;
    final index = voices.indexWhere(
      (v) =>
          v == widget.currentVoice ||
          v.matchesKey(widget.currentVoice?.storageKey),
    );
    if (index > 0) {
      // Estimated item height (48dp height + 6dp gap = 54dp)
      final targetOffset = (index * 54.0).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  List<TtsVoiceOption> get _filteredVoices {
    return widget.availableVoices
        .where((v) {
          if (_selectedLanguageFilter != null &&
              _selectedLanguageFilter != 'ALL') {
            if ((v.languageCode?.toUpperCase() ?? '') !=
                _selectedLanguageFilter) {
              return false;
            }
          }
          if (_searchQuery.isNotEmpty) {
            final label = v.label.toLowerCase();
            final lang = (v.languageCode ?? '').toLowerCase();
            final id = v.id.toLowerCase();
            final speaker = v.sherpaSpeakerId != null
                ? 'speaker ${v.sherpaSpeakerId}'
                : '';
            return label.contains(_searchQuery) ||
                lang.contains(_searchQuery) ||
                id.contains(_searchQuery) ||
                speaker.contains(_searchQuery);
          }
          return true;
        })
        .toList(growable: false);
  }

  Set<String> get _availableLanguages {
    final langs = <String>{};
    for (final v in widget.availableVoices) {
      if (v.languageCode != null && v.languageCode!.isNotEmpty) {
        langs.add(v.languageCode!.toUpperCase());
      }
    }
    return langs;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final showSearchAndFilters = widget.availableVoices.length > 4;
    final languages = _availableLanguages;
    final filtered = _filteredVoices;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header: Icon, Title, Voice Count Tag, Settings Shortcut & Close Button
          Row(
            children: [
              Icon(
                LucideIcons.mic,
                size: 16,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Voice',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              // Voice count pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _searchQuery.isNotEmpty || _selectedLanguageFilter != null
                      ? '${filtered.length}/${widget.availableVoices.length}'
                      : '${widget.availableVoices.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              // Manage / Download more in settings button
              IconButton(
                tooltip: 'Manage voices in Settings',
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.all(8),
                ),
                onPressed: () {
                  appRouter.push('${appRoutes.settings.path}?tab=tts');
                },
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.settings,
                      size: 14,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onClose != null) ...[
                const SizedBox(width: 2),
                IconButton(
                  tooltip: 'Close voice settings',
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.all(8),
                  ),
                  onPressed: widget.onClose,
                  icon: Icon(
                    LucideIcons.x,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),

          // 2. Search & Language Filter Chips (Only rendered when many voices installed)
          if (showSearchAndFilters) ...[
            const SizedBox(height: 8),
            // Search Input
            SizedBox(
              height: 36,
              child: TextField(
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search voices or languages…',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  prefixIcon: Icon(
                    LucideIcons.search,
                    size: 15,
                    color: scheme.onSurfaceVariant,
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 32),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 14),
                          onPressed: () => _searchController.clear(),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(minWidth: 28),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: scheme.primary, width: 1.2),
                  ),
                ),
              ),
            ),

            // Language Filter Chips if multiple languages installed
            if (languages.length > 1) ...[
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildLangChip(
                      label: 'All',
                      isSelected: _selectedLanguageFilter == null,
                      onTap: () =>
                          setState(() => _selectedLanguageFilter = null),
                      scheme: scheme,
                    ),
                    for (final lang in languages)
                      _buildLangChip(
                        label: lang,
                        isSelected: _selectedLanguageFilter == lang,
                        onTap: () =>
                            setState(() => _selectedLanguageFilter = lang),
                        scheme: scheme,
                      ),
                  ],
                ),
              ),
            ],
          ],

          const SizedBox(height: 8),

          // 3. Voice Options List or Empty State
          if (widget.availableVoices.isEmpty)
            _buildEmptyState(context, scheme)
          else if (filtered.isEmpty)
            _buildNoSearchResults(context, scheme)
          else
            _buildVoiceList(context, scheme, filtered),
        ],
      ),
    );
  }

  Widget _buildLangChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme scheme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? scheme.primary
                : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.3),
              width: 0.8,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoSearchResults(BuildContext context, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.searchX,
            size: 24,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 6),
          Text(
            'No matching voices found',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your search terms or language filter.',
            style: TextStyle(
              fontSize: 11,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _selectedLanguageFilter = null;
              });
            },
            child: const Text('Reset filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.audioLines,
            size: 28,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            'No offline voices installed',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Download offline neural voices to use TTS reading.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: () {
              appRouter.push('${appRoutes.settings.path}?tab=tts');
            },
            icon: const Icon(LucideIcons.download, size: 15),
            label: const Text('Download Voices'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceList(
    BuildContext context,
    ColorScheme scheme,
    List<TtsVoiceOption> voices,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 210),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: voices.length > 3,
        child: ListView.separated(
          controller: _scrollController,
          shrinkWrap: false,
          physics: const BouncingScrollPhysics(),
          itemCount: voices.length,
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final voice = voices[index];
            final isSelected =
                widget.currentVoice == voice ||
                (widget.currentVoice != null &&
                    voice.matchesKey(widget.currentVoice!.storageKey));

            return InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onVoiceSelected(voice);
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                constraints: const BoxConstraints(minHeight: 46),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? scheme.primaryContainer.withValues(alpha: 0.35)
                      : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? scheme.primary
                        : scheme.outlineVariant.withValues(alpha: 0.35),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? LucideIcons.circleCheck : LucideIcons.circle,
                      size: 18,
                      color: isSelected
                          ? scheme.primary
                          : scheme.outlineVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            voice.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? scheme.primary
                                  : scheme.onSurface,
                            ),
                          ),
                          if (voice.languageCode != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: scheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: scheme.outlineVariant.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    voice.languageCode!.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                if (voice.sherpaSpeakerId != null) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    'Speaker ${voice.sherpaSpeakerId}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
