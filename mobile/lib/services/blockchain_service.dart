import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import '../config/env.dart';

class BlockchainService {
  late Web3Client _client;

  BlockchainService() {
    _client = Web3Client(Environment.blockchainRpcUrl, Client());
  }

  Future<EthereumAddress> getAddressFromPrivateKey(String privateKey) async {
    final credentials = EthPrivateKey.fromHex(privateKey);
    return credentials.address;
  }

  Future<EtherAmount> getBalance(String address) async {
    try {
      final ethAddress = EthereumAddress.fromHex(address);
      return await _client.getBalance(ethAddress);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> sendTransaction({
    required String privateKey,
    required String to,
    required BigInt value,
  }) async {
    try {
      final credentials = EthPrivateKey.fromHex(privateKey);
      final transaction = Transaction(
        to: EthereumAddress.fromHex(to),
        value: EtherAmount.inWei(value),
      );

      final txHash = await _client.sendTransaction(
        credentials,
        transaction,
        chainId: 31337, // Hardhat local network
      );

      return txHash;
    } catch (e) {
      rethrow;
    }
  }

  // Contract interactions will be implemented based on deployed contract
  Future<String> createAuction({
    required String privateKey,
    required int tokenId,
    required BigInt startingPrice,
    required int duration,
  }) async {
    // TODO: Implement contract interaction
    // This requires the contract ABI and address
    throw UnimplementedError('Contract interaction not yet implemented');
  }

  Future<String> placeBid({
    required String privateKey,
    required int tokenId,
    required BigInt bidAmount,
  }) async {
    // TODO: Implement contract interaction
    throw UnimplementedError('Contract interaction not yet implemented');
  }

  void dispose() {
    _client.dispose();
  }
}
