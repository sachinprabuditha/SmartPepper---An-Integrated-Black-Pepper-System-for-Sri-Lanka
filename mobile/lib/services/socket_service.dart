import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/env.dart';

class SocketService {
  late IO.Socket _socket;
  bool _connected = false;

  void connect() {
    print('🔌 Connecting to WebSocket: ${Environment.wsUrl}');
    _socket = IO.io(
      Environment.wsUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .build(),
    );

    _socket.on('connect', (_) {
      print('✅ Socket connected to ${Environment.wsUrl}');
      _connected = true;
    });

    _socket.on('disconnect', (_) {
      print('❌ Socket disconnected');
      _connected = false;
    });

    _socket.on('error', (error) {
      print('❌ Socket error: $error');
    });

    _socket.on('connect_error', (error) {
      print('❌ Socket connect_error: $error');
    });
  }

  void disconnect() {
    if (_connected) {
      _socket.disconnect();
      _connected = false;
    }
  }

  // Auction events
  void joinAuction(String auctionId) {
    if (_connected) {
      print('📡 Emitting join_auction for: $auctionId');
      _socket.emit('join_auction', {'auctionId': auctionId});
    } else {
      print('⚠️ Cannot join auction - socket not connected');
    }
  }

  void leaveAuction(String auctionId) {
    if (_connected) {
      print('📡 Emitting leave_auction for: $auctionId');
      _socket.emit('leave_auction', {'auctionId': auctionId});
    }
  }

  void onNewBid(Function(dynamic) callback) {
    _socket.on('newBid', callback);
  }

  void onAuctionEnd(Function(dynamic) callback) {
    _socket.on('auctionEnded', callback);
  }

  void onAuctionUpdate(Function(dynamic) callback) {
    _socket.on('auctionUpdate', callback);
  }

  // Remove listeners
  void offNewBid() {
    _socket.off('newBid');
  }

  void offAuctionEnd() {
    _socket.off('auctionEnded');
  }

  void offAuctionUpdate() {
    _socket.off('auctionUpdate');
  }

  // Generic methods for custom events
  void emit(String event, dynamic data) {
    if (_connected) {
      _socket.emit(event, data);
    }
  }

  void on(String event, Function(dynamic) callback) {
    _socket.on(event, callback);
  }

  void off(String event) {
    _socket.off(event);
  }

  bool get isConnected => _connected;
}
