/// Formats minor currency units (e.g. paise) as INR for display.
String formatInrMinor(int minor) {
  final rupees = minor / 100.0;
  final s = rupees == rupees.roundToDouble()
      ? rupees.toStringAsFixed(0)
      : rupees.toStringAsFixed(2);
  return '₹$s';
}
