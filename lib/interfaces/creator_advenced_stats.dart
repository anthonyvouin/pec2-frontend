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
  final List<Revenues> subscriptions;
  CreatorAdvencedStats({required this.payments, required this.subscriptions});

  factory CreatorAdvencedStats.fromJson(Map<String, dynamic> json) {
    return CreatorAdvencedStats(
      payments:
      json['monthlyRevenue'] != null
          ? (json['monthlyRevenue'] as List)
          .map((e) => Revenues.fromJson(e))
          .toList()
          : [],
      subscriptions:
      json['subscriptions'] != null
          ? (json['subscriptions'] as List)
          .map((e) => Revenues.fromJson(e))
          .toList()
          : [],
    );
  }
}