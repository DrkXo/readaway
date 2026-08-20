part of 'theme.dart';

@singleton
class AppTheme {
  ThemeData get lightTheme => _buildTheme(AppColors.light);
  ThemeData get darkTheme => _buildTheme(AppColors.dark);

  ThemeData _buildTheme(AppColors colors) {
    return ThemeData(
      colorScheme: colors.scheme,
      extensions: [colors],
      useMaterial3: true,
    );
  }
}
