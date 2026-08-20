part of 'theme.dart';

@module
abstract class ThemeModule {
  @lazySingleton
  AppColors get appColors => AppColors.light;
}
