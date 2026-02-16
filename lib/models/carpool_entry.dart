enum CarpoolEntryType {
  petrol,
  fees,
}

class CarpoolEntry {
  final String id;
  final CarpoolEntryType type;
  final double amount;
  final String description;
  final String date;

  const CarpoolEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
  });
}
