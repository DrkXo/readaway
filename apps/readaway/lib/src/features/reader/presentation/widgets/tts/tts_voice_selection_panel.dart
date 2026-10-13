import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/routes/routes.dart';
import '../../../../../core/services/tts/tts_models.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';
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
    final appColors = context.appColors;
    final theme = Theme.of(context);
    final showSearchAndFilters = widget.availableVoices.length > 4;
    final languages = _availableLanguages;
    final filtered = _filteredVoices;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: appColors.panelBackground,
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: appColors.panelBorder,
          width: 1.0,
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
                color: appColors.buttonBackground,
              ),
              const SizedBox(width: 8),
              Text(
                'voice',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: appColors.topbarForeground,
                ),
              ),
              const SizedBox(width: 8),
              // Voice count pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: appColors.panelBorder.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.zero,
                  border: Border.all(
                    color: appColors.panelBorder,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  _searchQuery.isNotEmpty || _selectedLanguageFilter != null
                      ? '${filtered.length}/${widget.availableVoices.length}'
                      : '${widget.availableVoices.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: appColors.topbarForeground.withValues(alpha: 0.8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              // Manage / Download more in settings button
              Tooltip(
                message: 'Manage voices in Settings',
                child: Semantics(
                  label: 'Manage voices in Settings',
                  button: true,
                  child: MetroPressable(
                    onTap: () {
                      appRouter.push('${appRoutes.settings.path}?tab=tts');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: appColors.panelBorder,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.settings,
                            size: 13,
                            color: appColors.buttonBackground,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'settings',
                            style: TextStyle(
                              fontSize: 12,
                              color: appColors.buttonBackground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.onClose != null) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Close voice settings',
                  child: Semantics(
                    label: 'Close voice settings',
                    button: true,
                    child: MetroPressable(
                      onTap: widget.onClose,
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Icon(
                          LucideIcons.x,
                          size: 18,
                          color: appColors.topbarForeground,
                        ),
                      ),
                    ),
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
                style: TextStyle(
                  fontSize: 13,
                  color: appColors.topbarForeground,
                ),
                decoration: InputDecoration(
                  hintText: 'search voices or languages…',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: appColors.topbarForeground.withValues(alpha: 0.5),
                  ),
                  prefixIcon: Icon(
                    LucideIcons.search,
                    size: 15,
                    color: appColors.topbarForeground.withValues(alpha: 0.6),
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
                  fillColor: appColors.panelBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      color: appColors.panelBorder,
                      width: 1.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      color: appColors.panelBorder,
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      color: appColors.buttonBackground,
                      width: 1.2,
                    ),
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
                      context: context,
                      label: 'All',
                      isSelected: _selectedLanguageFilter == null,
                      onTap: () =>
                          setState(() => _selectedLanguageFilter = null),
                    ),
                    for (final lang in languages)
                      _buildLangChip(
                        context: context,
                        label: lang,
                        isSelected: _selectedLanguageFilter == lang,
                        onTap: () =>
                            setState(() => _selectedLanguageFilter = lang),
                      ),
                  ],
                ),
              ),
            ],
          ],

          const SizedBox(height: 8),

          // 3. Voice Options List or Empty State
          if (widget.availableVoices.isEmpty)
            _buildEmptyState(context)
          else if (filtered.isEmpty)
            _buildNoSearchResults(context)
          else
            _buildVoiceList(context, filtered),
        ],
      ),
    );
  }

  Widget _buildLangChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final appColors = context.appColors;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Tooltip(
        message: 'Filter by $label',
        child: Semantics(
          label: 'Filter by $label',
          button: true,
          child: MetroPressable(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? appColors.buttonBackground
                    : appColors.panelBackground,
                borderRadius: BorderRadius.zero,
                border: Border.all(
                  color: isSelected
                      ? appColors.buttonBackground
                      : appColors.panelBorder,
                  width: 1,
                ),
              ),
              child: Text(
                label.toLowerCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? appColors.buttonForeground
                      : appColors.topbarForeground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoSearchResults(BuildContext context) {
    final appColors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.searchX,
            size: 24,
            color: appColors.topbarForeground.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 6),
          Text(
            'no matching voices found',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: appColors.topbarForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'try adjusting your search terms or language filter.',
            style: TextStyle(
              fontSize: 11,
              color: appColors.topbarForeground.withValues(alpha: 0.7),
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
            child: Text(
              'reset filters',
              style: TextStyle(color: appColors.buttonBackground),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final appColors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.audioLines,
            size: 28,
            color: appColors.topbarForeground.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            'no offline voices installed',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: appColors.topbarForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'download offline neural voices to use tts reading.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: appColors.topbarForeground.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          MetroPressable(
            onTap: () {
              appRouter.push('${appRoutes.settings.path}?tab=tts');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: appColors.buttonBackground,
                borderRadius: BorderRadius.zero,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.download,
                    size: 15,
                    color: appColors.buttonForeground,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'download voices',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: appColors.buttonForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceList(
    BuildContext context,
    List<TtsVoiceOption> voices,
  ) {
    final appColors = context.appColors;

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

            return MetroPressable(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onVoiceSelected(voice);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                constraints: const BoxConstraints(minHeight: 46),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? appColors.buttonBackground.withValues(alpha: 0.15)
                      : appColors.panelBackground,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(
                    color: isSelected
                        ? appColors.buttonBackground
                        : appColors.panelBorder,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? LucideIcons.squareCheck : LucideIcons.square,
                      size: 18,
                      color: isSelected
                          ? appColors.buttonBackground
                          : appColors.panelBorder,
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
                                  ? appColors.buttonBackground
                                  : appColors.topbarForeground,
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
                                    color: appColors.panelBorder.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.zero,
                                    border: Border.all(
                                      color: appColors.panelBorder,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    voice.languageCode!.toLowerCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: appColors.topbarForeground
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                                if (voice.sherpaSpeakerId != null) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    'speaker ${voice.sherpaSpeakerId}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: appColors.topbarForeground
                                          .withValues(alpha: 0.6),
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
                          color: appColors.buttonBackground,
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Text(
                          'active',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: appColors.buttonForeground,
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
