// Model for a single diamond history entry
// Used in DiamondHistoryScreen and ApiService
// Fields: id, userId, datetime, amount, status
//
// Example usage:
//   DiamondHistoryEntry.fromJson(json)
//
// Author: AI-generated
class DiamondHistoryEntry {
  final int id;
  final int userId;
  final DateTime datetime;
  final int amount;
  final String status;

  DiamondHistoryEntry({
    required this.id,
    required this.userId,
    required this.datetime,
    required this.amount,
    required this.status,
  });

  factory DiamondHistoryEntry.fromJson(Map<String, dynamic> json) {
    return DiamondHistoryEntry(
      id: json['id'],
      userId: json['user_id'],
      datetime: DateTime.parse(json['datetime']),
      amount: json['amount'],
      status: json['status'],
    );
  }
}
