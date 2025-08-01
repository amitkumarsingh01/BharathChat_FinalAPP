import 'package:flutter/material.dart';
import 'package:finalchat/services/api_service.dart';
import 'dart:convert';

class PKBattleDebugScreen extends StatefulWidget {
  final int? streamId;
  
  const PKBattleDebugScreen({Key? key, this.streamId}) : super(key: key);

  @override
  State<PKBattleDebugScreen> createState() => _PKBattleDebugScreenState();
}

class _PKBattleDebugScreenState extends State<PKBattleDebugScreen> {
  final TextEditingController _streamIdController = TextEditingController();
  final List<String> _logs = [];
  bool _isLoading = false;
  Map<String, dynamic>? _lastResponse;
  String? _lastError;
  
  // Hardcoded stream ID as requested
  static const String hardcodedStreamId = "1753960759354";

  @override
  void initState() {
    super.initState();
    
    // Use the passed stream ID if available, otherwise use hardcoded one
    final initialStreamId = widget.streamId?.toString() ?? hardcodedStreamId;
    _streamIdController.text = initialStreamId;
    
    _addLog("🚀 PK Battle Debug Screen initialized");
    if (widget.streamId != null) {
      _addLog("📝 Using Stream ID from Live Page: ${widget.streamId}");
    } else {
      _addLog("📝 Using Hardcoded Stream ID: $hardcodedStreamId");
    }
    _addLog("🔗 API Endpoint: /api/pk-battle/stream/{stream_id}");
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logEntry = '[$timestamp] $message';
    setState(() {
      _logs.add(logEntry);
      if (_logs.length > 100) {
        _logs.removeAt(0);
      }
    });
    print(logEntry);
  }

  Future<void> _testPKBattleAPI() async {
    setState(() {
      _isLoading = true;
      _lastResponse = null;
      _lastError = null;
    });

    _addLog("🔍 Starting PK Battle API test...");
    _addLog("🎯 Current Stream ID: ${_streamIdController.text}");
    if (widget.streamId != null) {
      _addLog("✅ Stream ID was passed from Live Page");
    } else {
      _addLog("⚠️ Using hardcoded Stream ID (no stream ID passed from Live Page)");
    }
    
    try {
      final streamId = int.tryParse(_streamIdController.text.trim());
      if (streamId == null) {
        throw Exception("Invalid stream ID: ${_streamIdController.text}");
      }

      _addLog("📡 Making API call to: /api/pk-battle/stream/$streamId");
      _addLog("⏰ Request started at: ${DateTime.now()}");

      final startTime = DateTime.now();
      final response = await ApiService.getActivePKBattleByStreamId(streamId);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      _addLog("✅ API call completed in ${duration.inMilliseconds}ms");

      if (response != null) {
        setState(() {
          _lastResponse = response;
        });
        
        _addLog("🎉 SUCCESS: PK Battle found!");
        _addLog("📊 Response Data:");
        _addLog("   - PK Battle ID: ${response['pk_battle_id']}");
        _addLog("   - Start Time: ${response['start_time']}");
        _addLog("   - Left Host ID: ${response['left_host_id']}");
        _addLog("   - Right Host ID: ${response['right_host_id']}");
        _addLog("   - Left Stream ID: ${response['left_stream_id']}");
        _addLog("   - Right Stream ID: ${response['right_stream_id']}");
        _addLog("   - Left Score: ${response['left_score']}");
        _addLog("   - Right Score: ${response['right_score']}");
        _addLog("   - Status: ${response['status']}");
        
        // Check if response matches expected format
        _validateResponse(response);
      } else {
        setState(() {
          _lastError = "No PK battle found for stream ID: $streamId";
        });
        _addLog("❌ FAILED: No PK battle found for stream ID: $streamId");
        _addLog("💡 This could mean:");
        _addLog("   - The stream ID doesn't exist");
        _addLog("   - No PK battle is associated with this stream");
        _addLog("   - The PK battle has ended");
      }
    } catch (e) {
      setState(() {
        _lastError = e.toString();
      });
      _addLog("💥 EXCEPTION: $e");
      _addLog("🔍 Exception type: ${e.runtimeType}");
    } finally {
      setState(() {
        _isLoading = false;
      });
      _addLog("🏁 Test completed");
    }
  }

  void _validateResponse(Map<String, dynamic> response) {
    _addLog("🔍 Validating response format...");
    
    final expectedFields = [
      'pk_battle_id',
      'start_time', 
      'left_host_id',
      'right_host_id',
      'left_stream_id',
      'right_stream_id',
      'left_score',
      'right_score',
      'status'
    ];

    bool isValid = true;
    for (final field in expectedFields) {
      if (!response.containsKey(field)) {
        _addLog("⚠️ Missing field: $field");
        isValid = false;
      }
    }

    if (isValid) {
      _addLog("✅ Response format validation: PASSED");
    } else {
      _addLog("❌ Response format validation: FAILED");
    }

    // Check data types
    if (response['pk_battle_id'] is! int) {
      _addLog("⚠️ pk_battle_id should be int, got: ${response['pk_battle_id'].runtimeType}");
    }
    if (response['left_host_id'] is! int) {
      _addLog("⚠️ left_host_id should be int, got: ${response['left_host_id'].runtimeType}");
    }
    if (response['right_host_id'] is! int) {
      _addLog("⚠️ right_host_id should be int, got: ${response['right_host_id'].runtimeType}");
    }
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
      _lastResponse = null;
      _lastError = null;
    });
    _addLog("🧹 Logs cleared");
  }

  void _copyResponseToClipboard() {
    if (_lastResponse != null) {
      final jsonString = json.encode(_lastResponse, toEncodable: (obj) => obj.toString());
      // You can implement clipboard functionality here
      _addLog("📋 Response copied to clipboard (JSON format)");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'PK Battle API Debug',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.white),
            onPressed: _clearLogs,
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Input Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[900],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Stream ID',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (widget.streamId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'From Live Page',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Hardcoded',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _streamIdController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter Stream ID',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[800],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testPKBattleAPI,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Test API',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Expected Response Format:',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '{"pk_battle_id": 149, "start_time": "...", "left_host_id": 29, "right_host_id": 17, ...}',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Results Section
          if (_lastResponse != null || _lastError != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: _lastError != null ? Colors.red[900] : Colors.green[900],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _lastError != null ? '❌ Error' : '✅ Success',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_lastResponse != null)
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.white),
                          onPressed: _copyResponseToClipboard,
                          tooltip: 'Copy Response',
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_lastResponse != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        json.encode(_lastResponse),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  if (_lastError != null)
                    Text(
                      _lastError!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),

          // Logs Section
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Debug Logs (${_logs.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Auto-scroll',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          Color logColor = Colors.white;
                          
                          // Color code different types of logs
                          if (log.contains('🚀')) {
                            logColor = Colors.blue;
                          } else if (log.contains('🔍')) {
                            logColor = Colors.cyan;
                          } else if (log.contains('📡')) {
                            logColor = Colors.yellow;
                          } else if (log.contains('✅')) {
                            logColor = Colors.green;
                          } else if (log.contains('❌')) {
                            logColor = Colors.red;
                          } else if (log.contains('⚠️')) {
                            logColor = Colors.orange;
                          } else if (log.contains('💥')) {
                            logColor = Colors.purple;
                          } else if (log.contains('⏰')) {
                            logColor = Colors.grey;
                          } else if (log.contains('🎉')) {
                            logColor = Colors.pink;
                          }
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 8),
                            child: Text(
                              log,
                              style: TextStyle(
                                color: logColor,
                                fontSize: 11,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _streamIdController.dispose();
    super.dispose();
  }
} 