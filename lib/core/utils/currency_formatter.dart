import 'package:intl/intl.dart';

/// Tiện ích định dạng tiền tệ Việt Nam (VNĐ)
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  static String format(double amount) {
    return _formatter.format(amount).trim();
  }
}

