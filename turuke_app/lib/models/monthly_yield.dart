class MonthlyYield {
  final DateTime collectionDate;
  final int totalEggs;

  MonthlyYield({required this.collectionDate, required this.totalEggs});

  factory MonthlyYield.fromJson(Map<String, dynamic> json) {
    return MonthlyYield(
      collectionDate: DateTime.parse(json['collection_date']),
      totalEggs: json['total_eggs'],
    );
  }
}
