import 'package:intl/intl.dart';

class Formatters {
  // Formato de moneda para Colombia (COP)
  static final NumberFormat currency = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  // Formato de número con separadores de miles
  static final NumberFormat number = NumberFormat('#,##0', 'es_CO');

  // Formato de fecha corta
  static final DateFormat dateShort = DateFormat('dd/MM/yyyy');

  // Formato de fecha larga
  static final DateFormat dateLong = DateFormat('EEEE, dd MMMM yyyy', 'es_ES');

  // Formato de fecha y hora
  static final DateFormat dateTime = DateFormat('dd/MM/yyyy HH:mm');

  // Formatear precio
  static String formatPrice(double price) {
    return currency.format(price);
  }

  // Formatear número entero
  static String formatNumber(int number) {
    return Formatters.number.format(number);
  }

  // Formatear fecha
  static String formatDate(DateTime date) {
    return dateShort.format(date);
  }

  // Formatear fecha y hora
  static String formatDateTime(DateTime dateTime) {
    return Formatters.dateTime.format(dateTime);
  }

  // Validar email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Capitalizar primera letra
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
