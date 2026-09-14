// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'theme.dart';

// **************************************************************************
// TailorAnnotationsGenerator
// **************************************************************************

mixin _$AppColorsTailorMixin
    on ThemeExtension<AppColors>, DiagnosticableTreeMixin {
  ColorScheme get scheme;
  Color get readerBackground;
  Color get readerForeground;
  List<BoxShadow> get shadowSm;
  List<BoxShadow> get shadowMd;
  List<BoxShadow> get shadowLg;
  Color get success;
  Color get onSuccess;
  Color get warning;
  Color get onWarning;

  @override
  AppColors copyWith({
    ColorScheme? scheme,
    Color? readerBackground,
    Color? readerForeground,
    List<BoxShadow>? shadowSm,
    List<BoxShadow>? shadowMd,
    List<BoxShadow>? shadowLg,
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
  }) {
    return AppColors(
      scheme: scheme ?? this.scheme,
      readerBackground: readerBackground ?? this.readerBackground,
      readerForeground: readerForeground ?? this.readerForeground,
      shadowSm: shadowSm ?? this.shadowSm,
      shadowMd: shadowMd ?? this.shadowMd,
      shadowLg: shadowLg ?? this.shadowLg,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
    );
  }

  @override
  AppColors lerp(covariant ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this as AppColors;
    return AppColors(
      scheme: const ColorSchemeEncoder().lerp(scheme, other.scheme, t),
      readerBackground: Color.lerp(
        readerBackground,
        other.readerBackground,
        t,
      )!,
      readerForeground: Color.lerp(
        readerForeground,
        other.readerForeground,
        t,
      )!,
      shadowSm: const BoxShadowListEncoder().lerp(shadowSm, other.shadowSm, t),
      shadowMd: const BoxShadowListEncoder().lerp(shadowMd, other.shadowMd, t),
      shadowLg: const BoxShadowListEncoder().lerp(shadowLg, other.shadowLg, t),
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AppColors &&
            const DeepCollectionEquality().equals(scheme, other.scheme) &&
            const DeepCollectionEquality().equals(
              readerBackground,
              other.readerBackground,
            ) &&
            const DeepCollectionEquality().equals(
              readerForeground,
              other.readerForeground,
            ) &&
            const DeepCollectionEquality().equals(shadowSm, other.shadowSm) &&
            const DeepCollectionEquality().equals(shadowMd, other.shadowMd) &&
            const DeepCollectionEquality().equals(shadowLg, other.shadowLg) &&
            const DeepCollectionEquality().equals(success, other.success) &&
            const DeepCollectionEquality().equals(onSuccess, other.onSuccess) &&
            const DeepCollectionEquality().equals(warning, other.warning) &&
            const DeepCollectionEquality().equals(onWarning, other.onWarning));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(scheme),
      const DeepCollectionEquality().hash(readerBackground),
      const DeepCollectionEquality().hash(readerForeground),
      const DeepCollectionEquality().hash(shadowSm),
      const DeepCollectionEquality().hash(shadowMd),
      const DeepCollectionEquality().hash(shadowLg),
      const DeepCollectionEquality().hash(success),
      const DeepCollectionEquality().hash(onSuccess),
      const DeepCollectionEquality().hash(warning),
      const DeepCollectionEquality().hash(onWarning),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'AppColors'))
      ..add(DiagnosticsProperty('scheme', scheme))
      ..add(DiagnosticsProperty('readerBackground', readerBackground))
      ..add(DiagnosticsProperty('readerForeground', readerForeground))
      ..add(DiagnosticsProperty('shadowSm', shadowSm))
      ..add(DiagnosticsProperty('shadowMd', shadowMd))
      ..add(DiagnosticsProperty('shadowLg', shadowLg))
      ..add(DiagnosticsProperty('success', success))
      ..add(DiagnosticsProperty('onSuccess', onSuccess))
      ..add(DiagnosticsProperty('warning', warning))
      ..add(DiagnosticsProperty('onWarning', onWarning));
  }
}
