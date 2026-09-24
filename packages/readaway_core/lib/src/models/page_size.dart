part of 'models.dart';

/// Dimensions of a fixed-layout document page (in points or pixels).
@freezed
sealed class PageSize with _$PageSize {
  const PageSize._();

  const factory PageSize({required double width, required double height}) =
      _PageSize;

  factory PageSize.fromJson(Map<String, dynamic> json) => PageSize(
    width: (json['width'] as num?)?.toDouble() ?? 0.0,
    height: (json['height'] as num?)?.toDouble() ?? 0.0,
  );

  @override
  Map<String, dynamic> toJson() => {'width': width, 'height': height};

  /// Width-to-height aspect ratio of the page.
  double get aspectRatio => height > 0 ? width / height : 1.0;
}
