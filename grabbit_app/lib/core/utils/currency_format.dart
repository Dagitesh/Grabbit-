/// Format numbers as Ethiopian Birr.
String formatBirr(double value) {
  return 'Br ${value.toStringAsFixed(2)}';
}

@Deprecated('Use formatBirr for Ethiopian Birr')
String formatBRL(double value) => formatBirr(value);
