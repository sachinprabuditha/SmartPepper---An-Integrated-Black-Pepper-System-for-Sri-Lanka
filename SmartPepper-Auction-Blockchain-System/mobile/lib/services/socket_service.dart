import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/env.dart';

class SocketService {
  IO.Socket? _socket;
  bool _connected = false;
  final List<Function()> _connectionQueue = [];

  Future<void> connect() async {
    if (_socket != null && _connected) {
      print('✅ Socket already connected');
      return;
    }

    print(
        '🔌 Connecting to WebSocket: ${Environment.wsBaseUrl}${Environment.wsNamespace}');
    print('   Base URL: ${Environment.wsBaseUrl}');
    print('   Namespace: ${Environment.wsNamespace}');
    print('   Using protocol: HTTP (Socket.IO will upgrade)');

    _socket = IO.io(
      '${Environment.wsBaseUrl}${Environment.wsNamespace}',
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling']) // Try both transports
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setReconnectionAttempts(10)
          .setTimeout(10000)
          .build(),
    );

    _socket!.onConnect((_) {
      print('✅ Socket connected successfully to ${Environment.wsUrl}');
      print('   Socket ID: ${_socket!.id}');
      _connected = true;

      // Execute any queued actions
      for (var action in _connectionQueue) {
        action();
      }
      _connectionQueue.clear();
    });

    _socket!.onDisconnect((reason) {
      print('❌ Socket disconnected. Reason: $reason');
      _connected = false;
    });

    _socket!.onError((error) {
      print('❌ Socket error: $error');
      _connected = false;
    });

    _socket!.onConnectError((error) {
      print('❌ Socket connect_error: $error');
      print('   URL: ${Environment.wsUrl}');
      print('   TROUBLESHOOTING:');
      print('   1. Check if backend server is running');
      print('   2. Verify IP address matches backend server');
      print('   3. Check if firewall is blocking port 3002');
      _connected = false;
    });

    _socket!.on('connect_timeout', (_) {
      print('⏱️ Socket connection timeout (10s)');
      print('   Backend may not be reachable at ${Environment.wsUrl}');
      _connected = false;
    });

    _socket!.onReconnect((attemptNumber) {
      print('🔄 Socket reconnected after $attemptNumber attempts');
      _connected = true;
    });

    _socket!.onReconnectAttempt((attemptNumber) {
      print('🔄 Socket reconnection attempt $attemptNumber...');
    });

    _socket!.onReconnectError((error) {
      print('❌ Socket reconnection error: $error');
    });

    _socket!.onReconnectFailed((_) {
      print('❌ Socket reconnection failed after max attempts');
      _connected = false;
    });

    // Connect the socket
    _socket!.connect();
  }

  void disconnect() {
    if (_socket != null && _connected) {
      print('🔌 Disconnecting socket...');
      _socket!.disconnect();
      _connected = false;
    }
  }

  // Auction events with auto-retry
  void joinAuction(String auctionId) {
    if (_socket == null) {
      print('⚠️ Socket not initialized. Call connect() first.');
      return;
    }

    if (auctionId.isEmpty) {
      print('⚠️ Cannot join auction with empty auctionId');
      return;
    }

    if (_connected) {
      print('📡 Emitting join_auction for: $auctionId');
      _socket!.emit('join_auction', {'auctionId': auctionId});
    } else {
      print('⏳ Socket not connected yet. Queuing join_auction for: $auctionId');
      _connectionQueue.add(() {
        print('📡 Executing queued join_auction for: $auctionId');
        _socket!.emit('join_auction', {'auctionId': auctionId});
      });

      // If socket is not connecting, try to reconnect
      if (_socket?.connected == false) {
        print('🔄 Attempting to reconnect socket...');
        _socket!.connect();
      }
    }
  }

  void leaveAuction(String auctionId) {
    if (auctionId.isEmpty) {
      print('⚠️ Cannot leave auction with empty auctionId');
      return;
    }

    if (_socket != null && _connected) {
      print('📡 Emitting leave_auction for: $auctionId');
      _socket!.emit('leave_auction', {'auctionId': auctionId});
    }
  }

  void onNewBid(Function(dynamic) callback) {
    _socket?.on('new_bid', callback);
  }

  void onAuctionEnd(Function(dynamic) callback) {
    _socket?.on('auction_ended', callback);
  }

  void onAuctionUpdate(Function(dynamic) callback) {
    _socket?.on('auction_update', callback);
  }

  // Remove listeners
  void offNewBid() {
    _socket?.off('new_bid');
  }

  void offAuctionEnd() {
    _socket?.off('auction_ended');
  }

  void offAuctionUpdate() {
    _socket?.off('auction_update');
  }

  // Generic methods for custom events
  void emit(String event, dynamic data) {
    if (_socket != null && _connected) {
      _socket!.emit(event, data);
    } else {
      print('⚠️ Cannot emit $event - socket not connected');
    }
  }

  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  void off(String event) {
    _socket?.off(event);
  }

  bool get isConnected => _connected && _socket != null && _socket!.connected;

  String? get socketId => _socket?.id;
}
