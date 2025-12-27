import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/env.dart';

class SocketService {
  late IO.Socket _socket;
  bool _connected = false;

  void connect() {
    _socket = IO.io(
      Environment.wsUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    _socket.on('connect', (_) {
      print('✅ Socket connected');
      _connected = true;
    });

    _socket.on('disconnect', (_) {
      print('❌ Socket disconnected');
      _connected = false;
    });

    _socket.on('error', (error) {
      print('Socket error: $error');
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
      _socket.emit('joinAuction', {'auctionId': auctionId});
      print('Joined auction: $auctionId');
    }
  }

  void leaveAuction(String auctionId) {
    if (_connected) {
      _socket.emit('leaveAuction', {'auctionId': auctionId});
      print('Left auction: $auctionId');
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
