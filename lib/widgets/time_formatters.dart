enum TimerPrecision { centisecond, millisecond }

String formatDuration(
  Duration value, {
  TimerPrecision precision = TimerPrecision.millisecond,
}) {
  final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (precision == TimerPrecision.centisecond) {
    final centis = ((value.inMilliseconds.remainder(1000)) ~/ 10)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds.$centis';
  }
  final millis = (value.inMilliseconds.remainder(1000)).toString().padLeft(3, '0');
  return '$minutes:$seconds.$millis';
}
