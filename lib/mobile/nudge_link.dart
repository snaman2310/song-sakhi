import 'dart:async';
import 'dart:convert';
import 'dart:io';

// The floating overlay runs in its own Flutter engine. The overlay plugin's
// own messaging proved unreliable for overlay -> app taps, so the two sides
// talk over a plain loopback socket instead (same device, same process, no
// plugin involved). One JSON message per line.

const int kNudgePort = 47231;

/// Main-isolate side: listens for the overlay and pushes state to it.
class NudgeServer {
  final void Function(String json) onMessage;
  NudgeServer({required this.onMessage});

  ServerSocket? _server;
  Socket? _client;

  bool get connected => _client != null;

  Future<bool> start() async {
    try {
      _server = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        kNudgePort,
        shared: true,
      );
    } catch (_) {
      return false;
    }
    _server!.listen((s) {
      _client?.destroy();
      _client = s;
      try {
        s.setOption(SocketOption.tcpNoDelay, true);
      } catch (_) {}
      s
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            onMessage,
            onDone: () {
              if (identical(_client, s)) _client = null;
            },
            onError: (_) {
              if (identical(_client, s)) _client = null;
            },
            cancelOnError: true,
          );
    }, onError: (_) {});
    return true;
  }

  void send(String json) {
    try {
      _client?.write('$json\n');
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      _client?.destroy();
    } catch (_) {}
    _client = null;
    try {
      await _server?.close();
    } catch (_) {}
    _server = null;
  }
}

/// Overlay side: keeps (re)connecting to the main isolate.
class NudgeClient {
  final void Function(String json) onMessage;
  final void Function(bool linked) onLink;
  NudgeClient({required this.onMessage, required this.onLink});

  Socket? _socket;
  Timer? _retry;
  bool _closed = false;

  void start() => _connect();

  Future<void> _connect() async {
    if (_closed) return;
    try {
      final s = await Socket.connect(
        InternetAddress.loopbackIPv4,
        kNudgePort,
        timeout: const Duration(seconds: 2),
      );
      if (_closed) {
        s.destroy();
        return;
      }
      _socket = s;
      try {
        s.setOption(SocketOption.tcpNoDelay, true);
      } catch (_) {}
      s
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            onMessage,
            onDone: () => _lost(s),
            onError: (_) => _lost(s),
            cancelOnError: true,
          );
      onLink(true);
    } catch (_) {
      _scheduleRetry();
    }
  }

  void _lost(Socket s) {
    if (!identical(_socket, s)) return;
    _socket = null;
    onLink(false);
    _scheduleRetry();
  }

  void _scheduleRetry() {
    if (_closed) return;
    _retry?.cancel();
    _retry = Timer(const Duration(milliseconds: 600), _connect);
  }

  void send(Map<String, dynamic> m) {
    try {
      _socket?.write('${jsonEncode(m)}\n');
    } catch (_) {}
  }

  void close() {
    _closed = true;
    _retry?.cancel();
    try {
      _socket?.destroy();
    } catch (_) {}
  }
}
