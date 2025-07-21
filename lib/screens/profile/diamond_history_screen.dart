import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/diamond_history_model.dart';

class DiamondHistoryScreen extends StatefulWidget {
  final int userId;
  const DiamondHistoryScreen({Key? key, required this.userId})
    : super(key: key);

  @override
  State<DiamondHistoryScreen> createState() => _DiamondHistoryScreenState();
}

class _DiamondHistoryScreenState extends State<DiamondHistoryScreen> {
  late Future<List<DiamondHistoryEntry>> _futureHistory;

  @override
  void initState() {
    super.initState();
    _futureHistory = ApiService.getDiamondHistory(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Diamond History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<DiamondHistoryEntry>>(
        future: _futureHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load history',
                style: TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No diamond history found',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          final history = snapshot.data!;
          final totalDiamonds = history.fold<int>(0, (sum, entry) => sum + entry.amount);
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.transparent),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/diamond.png',
                      width: 30,
                      height: 30,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ' $totalDiamonds Diamonds',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = history[index];
                    final isCredit = entry.amount > 0 || entry.status == 'credited';
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.transparent),
                        boxShadow: [
                          BoxShadow(
                            color:
                                isCredit
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Icon(
                          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isCredit ? Colors.green : Colors.red,
                        ),
                        title: Text(
                          isCredit ? 'Credited' : 'Debited',
                          style: TextStyle(
                            color: isCredit ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          _formatDate(entry.datetime),
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('assets/diamond.png', width: 24, height: 24),
                            const SizedBox(width: 4),
                            Text(
                              (entry.amount > 0
                                      ? '+${entry.amount}'
                                      : '${entry.amount}') +
                                  ' Diamonds',
                              style: TextStyle(
                                color: isCredit ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      backgroundColor: Colors.black,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}  ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');
}
