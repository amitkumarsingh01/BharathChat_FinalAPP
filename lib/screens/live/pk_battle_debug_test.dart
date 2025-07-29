import 'package:flutter/material.dart';
import 'pk_battle_debug_screen.dart';

class PKBattleDebugTest extends StatelessWidget {
  const PKBattleDebugTest({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PK Battle Debug Test'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Test PK Battle Debug Screen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'This will show sample API call data for testing the debug screen',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _showSampleDebugScreen(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Show Sample Debug Screen',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showErrorDebugScreen(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Show Error Debug Screen',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSampleDebugScreen(BuildContext context) {
    final sampleData = {
      'timestamp': DateTime.now().toIso8601String(),
      'api_calls': [
        {
          'api_name': 'Get User ID by Username (Local)',
          'url': 'https://api.example.com/user-id-by-username?username=john_doe',
          'method': 'GET',
          'request_headers': 'Authorization: Bearer token123, Content-Type: application/json',
          'request_body': null,
          'response_status': 200,
          'response_body': '{"id": 12345}',
          'result': 12345,
          'error': null,
        },
        {
          'api_name': 'Get User ID by Username (Remote)',
          'url': 'https://api.example.com/user-id-by-username?username=jane_smith',
          'method': 'GET',
          'request_headers': 'Authorization: Bearer token123, Content-Type: application/json',
          'request_body': null,
          'response_status': 200,
          'response_body': '{"id": 67890}',
          'result': 67890,
          'error': null,
        },
        {
          'api_name': 'Start PK Battle',
          'url': 'https://api.example.com/pk-battle/start',
          'method': 'POST',
          'request_headers': 'Authorization: Bearer token123, Content-Type: application/json',
          'request_body': '{"left_host_id": 12345, "right_host_id": 67890, "left_stream_id": 0, "right_stream_id": 0}',
          'response_status': 200,
          'response_body': '{"pk_battle_id": 999, "status": "started"}',
          'result': 999,
          'error': null,
        },
      ],
      'final_response': {
        'pk_battle_id': 999,
        'status': 'success',
        'message': 'PK Battle started successfully',
      },
      'error': null,
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PKBattleDebugScreen(
          apiCallDetails: sampleData,
        ),
      ),
    );
  }

  void _showErrorDebugScreen(BuildContext context) {
    final errorData = {
      'timestamp': DateTime.now().toIso8601String(),
      'api_calls': [
        {
          'api_name': 'Get User ID by Username (Local)',
          'url': 'https://api.example.com/user-id-by-username?username=invalid_user',
          'method': 'GET',
          'request_headers': 'Authorization: Bearer token123, Content-Type: application/json',
          'request_body': null,
          'response_status': 404,
          'response_body': '{"error": "User not found"}',
          'result': null,
          'error': 'User not found',
        },
        {
          'api_name': 'Get User ID by Username (Remote)',
          'url': 'https://api.example.com/user-id-by-username?username=another_invalid',
          'method': 'GET',
          'request_headers': 'Authorization: Bearer token123, Content-Type: application/json',
          'request_body': null,
          'response_status': 500,
          'response_body': '{"error": "Internal server error"}',
          'result': null,
          'error': 'Internal server error',
        },
      ],
      'final_response': null,
      'error': 'Failed to fetch user IDs for PK battle',
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PKBattleDebugScreen(
          apiCallDetails: errorData,
        ),
      ),
    );
  }
} 