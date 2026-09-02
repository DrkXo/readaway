part of '../core_widgets.dart';

/// Semantic text variants used across the app.
enum AppTextVariant {
  /// Large display heading.
  display,

  /// Section heading.
  heading,

  /// Subheading / emphasis.
  title,

  /// Standard body text.
  body,

  /// Slightly larger body text (reader-friendly).
  bodyLarge,

  /// Small caption / meta text.
  caption,

  /// Label for controls / buttons.
  label,
}

/// Theme-aware text widget.
///
/// Resolves color, size, weight, and line height from [AppColors] and the
/// current [AppTextVariant]. Use this instead of raw `Text` + hardcoded
/// styles so typography stays consistent and theme-driven.
class AppText extends StatelessWidget {
  const AppText(
    this.data, {
    super.key,
    this.variant = AppTextVariant.body,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.height,
    this.letterSpacing,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.style,
  });

  final String data;
  final AppTextVariant variant;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double? height;
  final double? letterSpacing;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final scheme = appColors.scheme;
    final textTheme = Theme.of(context).textTheme;

    final base = switch (variant) {
      AppTextVariant.display => textTheme.displaySmall,
      AppTextVariant.heading => textTheme.headlineSmall,
      AppTextVariant.title => textTheme.titleMedium,
      AppTextVariant.body => textTheme.bodyMedium,
      AppTextVariant.bodyLarge => textTheme.bodyLarge,
      AppTextVariant.caption => textTheme.bodySmall,
      AppTextVariant.label => textTheme.labelMedium,
    };

    final defaultColor = switch (variant) {
      AppTextVariant.caption => scheme.onSurfaceVariant,
      AppTextVariant.label => scheme.onSurfaceVariant,
      _ => scheme.onSurface,
    };

    return Text(
      data,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      style: (base ?? const TextStyle())
          .merge(style)
          .copyWith(
            color: color ?? defaultColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height,
            letterSpacing: letterSpacing,
          ),
    );
  }
}

/// A heading with consistent theme-driven styling.
class AppHeading extends StatelessWidget {
  const AppHeading(
    this.data, {
    super.key,
    this.level = 1,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String data;
  final int level;
  final Color? color;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final variant = switch (level) {
      1 => AppTextVariant.display,
      2 => AppTextVariant.heading,
      _ => AppTextVariant.title,
    };
    return AppText(
      data,
      variant: variant,
      color: color,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}

/// A small caption / meta text.
class AppCaption extends StatelessWidget {
  const AppCaption(
    this.data, {
    super.key,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String data;
  final Color? color;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return AppText(
      data,
      variant: AppTextVariant.caption,
      color: color,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}
