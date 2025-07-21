import 'package:flutter/material.dart';

enum LiveStreamType { video, audio }

class LiveStream {
  final String channelName;
  final LiveStreamType type;
  final int viewers;
  final String host;
  final int liveId;
  final int userId;

  LiveStream({
    required this.channelName,
    required this.type,
    required this.viewers,
    required this.host,
    required this.liveId,
    required this.userId,
  });
}

class LiveStreamService extends ChangeNotifier {
  static final LiveStreamService _instance = LiveStreamService._internal();
  factory LiveStreamService() => _instance;
  LiveStreamService._internal();

  final List<LiveStream> _streams = [];

  List<LiveStream> get streams => List.unmodifiable(_streams);

  void addStream(LiveStream stream) {
    _streams.add(stream);
    notifyListeners();
  }

  void removeStream(String channelName) {
    _streams.removeWhere((s) => s.channelName == channelName);
    notifyListeners();
  }

  void updateViewers(String channelName, int viewers) {
    final idx = _streams.indexWhere((s) => s.channelName == channelName);
    if (idx != -1) {
      _streams[idx] = LiveStream(
        channelName: _streams[idx].channelName,
        type: _streams[idx].type,
        viewers: viewers,
        host: _streams[idx].host,
        liveId: _streams[idx].liveId,
        userId: _streams[idx].userId,
      );
      notifyListeners();
    }
  }

  void clear() {
    _streams.clear();
    notifyListeners();
  }
} 