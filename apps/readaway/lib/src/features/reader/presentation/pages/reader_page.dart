import 'dart:developer' as dev;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get_it/get_it.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:readaway/src/core/services/services.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  // --- Document state ---
  List<String?>? _htmlPages;
  int _pageCount = 0;
  int _currentPage = 0;
  final Set<int> _loadingPages = {};

  // --- UI state ---
  String? _fileName;
  String? _error;
  bool _loading = false;

  // Drives PageView programmatically so the nav buttons and the
  // swipe gesture stay in sync.
  final PageController _pageController = PageController();

  /// MuPDF's fixed-layout HTML export pins each page's outer container(s)
  /// to the PDF page's exact height. If a referenced font (e.g. DogmaBold,
  /// Futura) isn't installed and Flutter falls back to a substitute with
  /// different metrics, the real content can be taller than that fixed
  /// height — causing a RenderFlex overflow. This walks the parsed DOM and
  /// strips any `height` (inline style property or raw attribute) from
  /// every element, regardless of unit (px/pt/in/whatever), so each
  /// page's layout can size itself to its actual content instead.
  String? _sanitizeHtml(String? raw) {
    if (raw == null || raw.isEmpty) return raw;

    final document = html_parser.parse(raw);

    for (final element in document.querySelectorAll('*')) {
      _stripHeight(element);
    }

    return document.outerHtml;
  }

  void _stripHeight(dom.Element element) {
    element.attributes.remove('height');

    final style = element.attributes['style'];
    if (style == null || style.isEmpty) return;

    final keptDeclarations = style.split(';').map((decl) => decl.trim()).where((
      decl,
    ) {
      if (decl.isEmpty) return false;
      final prop = decl.split(':').first.trim().toLowerCase();
      return prop != 'height';
    }).toList();

    if (keptDeclarations.isEmpty) {
      element.attributes.remove('style');
    } else {
      element.attributes['style'] = '${keptDeclarations.join('; ')};';
    }
  }

  // ---------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------

  void _goToPreviousPage() {
    if (_currentPage <= 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _goToNextPage() {
    if (_currentPage >= _pageCount - 1) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  // ---------------------------------------------------------------------
  // File handling & Lazy loading
  // ---------------------------------------------------------------------

  Future<void> _pickAndOpen() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'xps', 'epub'],
    );

    if (result.isEmpty) {
      dev.log('File picker cancelled or empty', name: 'mupdf');
      return;
    }

    final file = result.first;
    final path = file.path;
    if (path == null) {
      dev.log('Selected file has no path', name: 'mupdf');
      setState(() => _error = 'Selected file has no path');
      return;
    }

    dev.log('Opening: $path', name: 'mupdf');

    setState(() {
      _error = null;
      _fileName = file.name;
      _loading = true;
      _htmlPages = null;
      _loadingPages.clear();
    });

    try {
      final service = GetIt.instance<DocumentParserService>();
      await service.openDocument(path);

      final count = await service.getPageCount();
      final reflowable = await service.isReflowable();
      dev.log(
        'Loaded: $count pages, reflowable=$reflowable',
        name: 'mupdf',
      );

      if (!mounted) return;

      setState(() {
        _pageCount = count;
        _htmlPages = List<String?>.filled(count, null);
        _currentPage = 0;
        _loading = false;
      });

      // Snap the controller back to page 0 for the newly opened doc
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }

      // Start pre-caching pages 0 and 1
      _precachePages(0);
    } catch (e, st) {
      dev.log(
        'Failed to open document',
        name: 'mupdf',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _loadPage(int index) async {
    if (_htmlPages == null || index < 0 || index >= _pageCount) return;
    if (_htmlPages![index] != null || _loadingPages.contains(index)) return;

    _loadingPages.add(index);

    try {
      final service = GetIt.instance<DocumentParserService>();
      final rawHtml = await service.extractPageHtml(index);
      final html = _sanitizeHtml(rawHtml) ?? '';

      if (mounted) {
        setState(() {
          _htmlPages![index] = html;
          _loadingPages.remove(index);
        });
      }
    } catch (e) {
      dev.log('Failed to load page $index', name: 'mupdf', error: e);
      if (mounted) {
        setState(() {
          _htmlPages![index] = '<p>Error loading page: $e</p>';
          _loadingPages.remove(index);
        });
      }
    }
  }

  void _precachePages(int currentIndex) {
    if (_htmlPages == null) return;

    // Precache current page
    if (_htmlPages![currentIndex] == null) {
      _loadPage(currentIndex);
    }
    // Precache next page
    if (currentIndex + 1 < _pageCount &&
        _htmlPages![currentIndex + 1] == null) {
      _loadPage(currentIndex + 1);
    }
    // Precache previous page
    if (currentIndex - 1 >= 0 && _htmlPages![currentIndex - 1] == null) {
      _loadPage(currentIndex - 1);
    }
  }

  void _disposeDoc() {
    GetIt.instance<DocumentParserService>().closeDocument();
    _htmlPages = null;
    _pageCount = 0;
    _currentPage = 0;
    _loadingPages.clear();
  }

  @override
  void dispose() {
    _disposeDoc();
    _pageController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_fileName ?? 'MuPDF Test'),
        actions: [_buildPageCounter()],
      ),
      body: _buildBody(),
      bottomNavigationBar: _htmlPages != null ? _buildNavBar() : null,
      floatingActionButton: FloatingActionButton(
        onPressed: _loading ? null : _pickAndOpen,
        child: const Icon(Icons.file_open),
      ),
    );
  }

  Widget _buildPageCounter() {
    if (_htmlPages == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Center(
        child: Text(
          '${_currentPage + 1} / $_pageCount',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildNavBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton.filledTonal(
              onPressed: _currentPage > 0 ? _goToPreviousPage : null,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous page',
            ),
            Text(
              'Page ${_currentPage + 1} of $_pageCount',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            IconButton.filledTonal(
              onPressed: _currentPage < _pageCount - 1 ? _goToNextPage : null,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next page',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError(_error!);
    }

    if (_htmlPages == null) {
      return const Center(child: Text('Tap + to open a document'));
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: _pageCount,
      onPageChanged: (i) {
        setState(() => _currentPage = i);
        _precachePages(i);
      },
      itemBuilder: _buildPage,
    );
  }

  Widget _buildPage(BuildContext context, int index) {
    final html = _htmlPages![index];

    if (html == null) {
      _loadPage(index);
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          clipBehavior: Clip.none,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 32,
            ),
            child: SizedBox(
              width: double.infinity,
              child: HtmlWidget(
                html,
                renderMode: RenderMode.column,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
