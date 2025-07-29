import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:finalchat/services/api_service.dart';

class PKBattleDebugScreen extends StatefulWidget {
  final Map<String, dynamic> apiCallDetails;

  const PKBattleDebugScreen({
    Key? key,
    required this.apiCallDetails,
  }) : super(key: key);

  @override
  State<PKBattleDebugScreen> createState() => _PKBattleDebugScreenState();
}

class _PKBattleDebugScreenState extends State<PKBattleDebugScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'PK BATTLE DEBUG INFO',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                // Refresh the screen
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.white),
            onPressed: () {
              _showTestDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            onPressed: () {
              _showForcePKBattleDialog();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeaderSection(),
            const SizedBox(height: 20),
            
            // API Calls Section
            _buildApiCallsSection(),
            const SizedBox(height: 20),
            
            // Final Response Section
            _buildFinalResponseSection(),
            const SizedBox(height: 20),
            
            // Raw Data Section (for developers)
            _buildRawDataSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              const Text(
                'PK BATTLE DEBUG INFORMATION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Timestamp: ${widget.apiCallDetails['timestamp'] ?? 'N/A'}',
            style: const TextStyle(color: Colors.yellow, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Total API Calls: ${widget.apiCallDetails['api_calls']?.length ?? 0}',
            style: const TextStyle(color: Colors.cyan, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.apiCallDetails['error'] != null ? Colors.red[900] : Colors.green[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.apiCallDetails['error'] != null ? 'FAILED' : 'SUCCESS',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiCallsSection() {
    final apiCalls = widget.apiCallDetails['api_calls'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'API CALLS DETAILS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...apiCalls.asMap().entries.map((entry) {
          final index = entry.key;
          final apiCall = entry.value as Map<String, dynamic>;
          return _buildApiCallCard(index + 1, apiCall);
        }).toList(),
      ],
    );
  }

  Widget _buildApiCallCard(int index, Map<String, dynamic> apiCall) {
    final isSuccess = apiCall['response_status'] == 200;
    final hasError = apiCall['error'] != null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError ? Colors.red : (isSuccess ? Colors.green : Colors.orange),
          width: 2,
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        collapsedIconColor: Colors.white,
        iconColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: hasError ? Colors.red : (isSuccess ? Colors.green : Colors.orange),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    apiCall['api_name'] ?? 'Unknown API',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${apiCall['method'] ?? 'GET'} - ${apiCall['response_status'] ?? 'Pending'}',
                    style: TextStyle(
                      color: hasError ? Colors.red : (isSuccess ? Colors.green : Colors.orange),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // URL
                _buildInfoRow('URL', apiCall['url'] ?? 'N/A', Colors.blue),
                const SizedBox(height: 8),
                
                // Request Headers
                _buildInfoRow('Request Headers', apiCall['request_headers'] ?? 'N/A', Colors.orange),
                const SizedBox(height: 8),
                
                // Request Body (if exists)
                if (apiCall['request_body'] != null) ...[
                  _buildInfoRow('Request Body', apiCall['request_body'], Colors.purple),
                  const SizedBox(height: 8),
                ],
                
                // Response Status
                _buildInfoRow('Response Status', '${apiCall['response_status'] ?? 'Pending'}', 
                    apiCall['response_status'] == 200 ? Colors.green : Colors.red),
                const SizedBox(height: 8),
                
                // Response Body
                _buildInfoRow('Response Body', apiCall['response_body'] ?? 'No response yet', Colors.cyan),
                const SizedBox(height: 8),
                
                // Result
                _buildInfoRow('Result', '${apiCall['result'] ?? 'Pending'}', Colors.yellow),
                
                // Error (if exists)
                if (apiCall['error'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[900],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Error: ${apiCall['error']}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinalResponseSection() {
    final finalResponse = widget.apiCallDetails['final_response'];
    final error = widget.apiCallDetails['error'];
    
    if (finalResponse != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'SUCCESS RESPONSE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'PK Battle ID: ${finalResponse['pk_battle_id']}',
              style: const TextStyle(
                color: Colors.yellow,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${finalResponse['status']}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            Text(
              'Message: ${finalResponse['message']}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      );
    } else if (error != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'ERROR RESPONSE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildRawDataSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.code, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'RAW DATA (For Developers)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[600]!),
            ),
            child: Text(
              const JsonEncoder.withIndent('  ').convert(widget.apiCallDetails),
              style: const TextStyle(
                color: Colors.green,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTestDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Test API Call',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'This will test the getUserIdByUsername API call with the current user\'s username',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _testApiCall();
              },
              child: const Text('Test', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _testApiCall() async {
    try {
      // Get current user's username from API service
      final currentUser = await ApiService.getCurrentUser();
      final username = currentUser['username'] ?? 'unknown';
      
      // Test the API service with current user's username
      final result = await ApiService.getUserIdByUsername(username);
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Test Result',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'API call successful!\nUsername: $username\nUser ID: $result',
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK', style: TextStyle(color: Colors.blue)),
              ),
            ],
          );
        },
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Test Failed',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Error: $e',
              style: const TextStyle(color: Colors.red),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK', style: TextStyle(color: Colors.blue)),
              ),
            ],
          );
        },
      );
    }
  }

  void _showForcePKBattleDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Force PK Battle API Call',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'This will force the PK battle API call to be made immediately, regardless of PK battle state.',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _forcePKBattleApiCall();
              },
              child: const Text('Force Call', style: TextStyle(color: Colors.orange)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _forcePKBattleApiCall() async {
    try {
      // Import the events class to access the force method
      // Since we don't have direct access to PKEvents here, we'll call the API directly
      final currentUser = await ApiService.getCurrentUser();
      final username = currentUser['username'] ?? 'unknown';
      
      // Get user ID for the current user
      final userId = await ApiService.getUserIdByUsername(username);
      
      if (userId != null) {
        // Force call the PK battle API with the same user as both hosts (for testing)
        final pkBattleId = await ApiService.startPKBattle(
          leftHostId: userId,
          rightHostId: userId,
          leftStreamId: 0,
          rightStreamId: 0,
        );
        
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text(
                'Force PK Battle Result',
                style: TextStyle(color: Colors.white),
              ),
              content: Text(
                'PK Battle API call successful!\nUsername: $username\nUser ID: $userId\nPK Battle ID: $pkBattleId',
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK', style: TextStyle(color: Colors.blue)),
                ),
              ],
            );
          },
        );
      } else {
        throw Exception('Could not get user ID for username: $username');
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Force PK Battle Failed',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Error: $e',
              style: const TextStyle(color: Colors.red),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK', style: TextStyle(color: Colors.blue)),
              ),
            ],
          );
        },
      );
    }
  }
} 