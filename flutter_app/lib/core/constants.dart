import 'package:intl/intl.dart';

class AppConstants {
  static const List<String> roles = ['member', 'manager', 'committee', 'auditor'];

  static const List<String> paymentModes = ['cash', 'upi', 'bank'];

  static const List<String> relationTypes = ['Owner', 'Family', 'Tenant', 'Partner'];
}

/// Format helpers
String formatCurrency(num amount) {
  if (amount >= 10000000) return '${(amount / 10000000).toStringAsFixed(1)}Cr';
  if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
  if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
  return amount.toStringAsFixed(0);
}

String formatFullCurrency(num amount) {
  final f = NumberFormat('#,##,###', 'en_IN');
  return 'Rs.${f.format(amount)}';
}

String formatDate(String? isoDate) {
  if (isoDate == null || isoDate.isEmpty) return '-';
  try {
    final dt = DateTime.parse(isoDate);
    return DateFormat('dd MMM yyyy').format(dt);
  } catch (_) {
    return isoDate.length >= 10 ? isoDate.substring(0, 10) : isoDate;
  }
}

String timeAgo(String? isoDate) {
  if (isoDate == null) return '';
  try {
    final dt = DateTime.parse(isoDate);
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(dt);
  } catch (_) {
    return '';
  }
}
