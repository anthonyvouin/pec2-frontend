import 'package:firstflutterapp/screens/creator/advencedView.dart';

class Revenues {
  final String month;
  final double total;

  Revenues({required this.month, required this.total});

  factory Revenues.fromJson(Map<String, dynamic> json) {
    return Revenues(
      month: json['month'] as String,
      total: (json['total'] as num).toDouble(),
    );
  }
}

class CreatorAdvencedStats {
  final List<Revenues> payments;
  CreatorAdvencedStats({required this.payments});

  factory CreatorAdvencedStats.fromJson(Map<String, dynamic> json) {
    return CreatorAdvencedStats(
      payments:
      json['monthlyRevenue'] != null
          ? (json['monthlyRevenue'] as List)
          .map((e) => Revenues.fromJson(e))
          .toList()
          : [],
    );
  }
}