/// Recurring animation durations (excluding local choreographies such as splash).
abstract final class AppDurations {
  static const Duration press = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration snappy = Duration(milliseconds: 160);
  static const Duration quick = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration emphasize = Duration(milliseconds: 450);

  static const Duration tooltipWait = Duration(milliseconds: 350);
  static const Duration pageIn = Duration(milliseconds: 320);
  static const Duration pageOut = Duration(milliseconds: 260);
}
