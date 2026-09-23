import 'package:flutter/material.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../settings/domain/entity/reader_preferences.dart';

/// Persistent top header (Running Header) displaying chapter title or book title.
class ReaderRunningHeader extends StatelessWidget {
  const ReaderRunningHeader({
    super.key,
    required this.title,
    this.alignment = ReaderHeaderAlignment.left,
    this.fontSize = 11.0,
    this.height = 24.0,
    this.horizontalPadding = 16.0,
    this.color,
  });

  final String title;
  final ReaderHeaderAlignment alignment;
  final double fontSize;
  final double height;
  final double horizontalPadding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (title.isEmpty) return SizedBox(height: height);

    final resolvedColor = color ??
        context.appColors.readerForeground.withValues(alpha: 0.55);

    final align = switch (alignment) {
      ReaderHeaderAlignment.left => Alignment.centerLeft,
      ReaderHeaderAlignment.center => Alignment.center,
      ReaderHeaderAlignment.right => Alignment.centerRight,
    };

    final textAlign = switch (alignment) {
      ReaderHeaderAlignment.left => TextAlign.left,
      ReaderHeaderAlignment.center => TextAlign.center,
      ReaderHeaderAlignment.right => TextAlign.right,
    };

    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Align(
          alignment: align,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
            style: TextStyle(
              fontSize: fontSize,
              color: resolvedColor,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
