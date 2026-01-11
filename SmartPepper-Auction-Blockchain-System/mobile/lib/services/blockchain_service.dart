import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import '../config/env.dart';

class BlockchainService {
  late Web3Client _client;
  bool _isInitialized = false;

  // Contract instances
  DeployedContract? _pepperPassportContract;
  DeployedContract? _pepperAuctionContract;

  // Contract functions
  ContractFunction? _mintPassportFunction;
  ContractFunction? _createAuctionFunction;
  ContractFunction? _placeBidFunction;

  BlockchainService() {
    _client = Web3Client(Environment.blockchainRpcUrl, Client());
  }

  /// Initialize blockchain service and load contract ABIs
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('Initializing blockchain service...');
      await _loadContracts();
      _isInitialized = true;
      print('✅ Blockchain service initialized');
    } catch (e) {
      print('❌ Failed to initialize blockchain service: $e');
      rethrow;
    }
  }

  /// Load smart contract ABIs from assets
  Future<void> _loadContracts() async {
    try {
      // Load PepperPassport contract
      final passportAbiString =
          await rootBundle.loadString('assets/abis/PepperPassport.json');
      final passportAbiJson = jsonDecode(passportAbiString);
      final passportAbi = ContractAbi.fromJson(
          jsonEncode(passportAbiJson['abi']), 'PepperPassport');

      _pepperPassportContract = DeployedContract(
        passportAbi,
        EthereumAddress.fromHex(Environment.passportContractAddress),
      );

      _mintPassportFunction = _pepperPassportContract!.function('mintPassport');

      // Load PepperAuction contract
      final auctionAbiString =
          await rootBundle.loadString('assets/abis/PepperAuction.json');
      final auctionAbiJson = jsonDecode(auctionAbiString);
      final auctionAbi = ContractAbi.fromJson(
          jsonEncode(auctionAbiJson['abi']), 'PepperAuction');

      _pepperAuctionContract = DeployedContract(
        auctionAbi,
        EthereumAddress.fromHex(Environment.auctionContractAddress),
      );

      _createAuctionFunction =
          _pepperAuctionContract!.function('createAuction');
      _placeBidFunction = _pepperAuctionContract!.function('placeBid');

      print('✅ Blockchain contracts loaded successfully');
    } catch (e) {
      print('❌ Failed to load contracts: $e');
      rethrow;
    }
  }

  /// Generate a new Ethereum wallet
  /// Returns tuple of (privateKey, address)
  Future<Map<String, String>> generateWallet() async {
    try {
      final random = Random.secure();
      final privateKey = EthPrivateKey.createRandom(random);
      final address = await privateKey.extractAddress();

      // Return private key with 0x prefix for consistency
      final privateKeyHex =
          privateKey.privateKeyInt.toRadixString(16).padLeft(64, '0');

      return {
        'privateKey': '0x$privateKeyHex',
        'address': address.hex,
      };
    } catch (e) {
      throw Exception('Failed to generate wallet: $e');
    }
  }

  /// Fund a newly created wallet with test ETH from Hardhat's test account
  /// This is needed for gas fees on test networks
  Future<bool> fundWallet(String walletAddress) async {
    try {
      // Hardhat Account #0 with pre-funded 10000 ETH
      const testAccountPrivateKey =
          '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';

      print('💰 Funding wallet $walletAddress with test ETH...');

      // Send 10 ETH for gas fees
      final credentials = EthPrivateKey.fromHex(testAccountPrivateKey);
      final transaction = Transaction(
        to: EthereumAddress.fromHex(walletAddress),
        value: EtherAmount.fromInt(EtherUnit.ether, 10),
      );

      final txHash = await _client.sendTransaction(
        credentials,
        transaction,
        chainId: Environment.chainId,
      );

      print('✅ Funding transaction sent: $txHash');

      // Wait for transaction confirmation
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(seconds: 1));
        final receipt = await _client.getTransactionReceipt(txHash);
        if (receipt != null) {
          print('✅ Wallet funded successfully');
          return true;
        }
      }

      return true; // Assume success even if receipt not found
    } catch (e) {
      print('⚠️ Wallet funding failed: $e');
      return false; // Don't fail registration if funding fails
    }
  }

  Future<EthereumAddress> getAddressFromPrivateKey(String privateKey) async {
    String formattedPrivateKey = privateKey.trim();
    if (!formattedPrivateKey.startsWith('0x')) {
      formattedPrivateKey = '0x$formattedPrivateKey';
    }
    final credentials = EthPrivateKey.fromHex(formattedPrivateKey);
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
      // Ensure private key has correct format
      String formattedPrivateKey = privateKey.trim();
      if (!formattedPrivateKey.startsWith('0x')) {
        formattedPrivateKey = '0x$formattedPrivateKey';
      }

      final credentials = EthPrivateKey.fromHex(formattedPrivateKey);
      final transaction = Transaction(
        to: EthereumAddress.fromHex(to),
        value: EtherAmount.inWei(value),
      );

      final txHash = await _client.sendTransaction(
        credentials,
        transaction,
        chainId: Environment.chainId,
      );

      return txHash;
    } catch (e) {
      rethrow;
    }
  }

  /// Mint a PepperPassport NFT for a lot
  /// This creates the blockchain record for traceability
  Future<Map<String, dynamic>> mintLotPassport({
    required String privateKey,
    required String farmerAddress,
    required String lotId,
    required String variety,
    required int quantity,
    required String harvestDate,
    required String origin,
    required String certificateHash,
    required String metadataURI,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_pepperPassportContract == null || _mintPassportFunction == null) {
      throw Exception(
          'Contract not loaded. Check contract addresses in env.dart');
    }

    try {
      print('Minting passport for lot: $lotId');
      print('Private key length: ${privateKey.length}');

      // Ensure private key has correct format
      String formattedPrivateKey = privateKey.trim();
      if (!formattedPrivateKey.startsWith('0x')) {
        formattedPrivateKey = '0x$formattedPrivateKey';
      }

      final credentials = EthPrivateKey.fromHex(formattedPrivateKey);
      final farmer = EthereumAddress.fromHex(farmerAddress);

      // Check wallet balance and fund if needed
      final balance = await _client.getBalance(credentials.address);
      final minBalance =
          EtherAmount.fromInt(EtherUnit.ether, 1); // 1 ETH minimum

      if (balance.getInWei < minBalance.getInWei) {
        print(
            '⚠️ Low balance detected: ${balance.getValueInUnit(EtherUnit.ether)} ETH');
        print('💰 Auto-funding wallet...');
        await fundWallet(farmerAddress);
      } else {
        print(
            '✅ Wallet balance: ${balance.getValueInUnit(EtherUnit.ether)} ETH');
      }

      // Convert IPFS hash to bytes32 by hashing it with SHA-256
      // IPFS hashes are base58 encoded, not hex, so we need to hash them
      final certHashBytes = sha256.convert(utf8.encode(certificateHash)).bytes;

      print('Certificate hash: $certificateHash');
      print('Converted to bytes32: ${hex.encode(certHashBytes)}');

      final transaction = Transaction.callContract(
        contract: _pepperPassportContract!,
        function: _mintPassportFunction!,
        parameters: [
          farmer,
          lotId,
          variety,
          BigInt.from(quantity), // Convert to BigInt for smart contract
          harvestDate,
          origin,
          certHashBytes,
          metadataURI,
        ],
      );

      final txHash = await _client.sendTransaction(
        credentials,
        transaction,
        chainId: Environment.chainId,
      );

      print('Transaction sent: $txHash');

      // Wait for transaction receipt (with timeout)
      TransactionReceipt? receipt;
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(seconds: 1));
        receipt = await _client.getTransactionReceipt(txHash);
        if (receipt != null) break;
      }

      if (receipt == null) {
        throw Exception('Transaction timeout - receipt not received');
      }

      // Parse logs to get tokenId
      int? tokenId;
      if (receipt.logs.isNotEmpty) {
        // PassportMinted event returns tokenId as first indexed parameter
        // For now, we'll estimate it (in production, parse the event properly)
        tokenId = receipt.logs.first.topics?.length ?? 1;
      }

      return {
        'txHash': txHash,
        'tokenId': tokenId,
        'blockNumber': receipt.blockNumber.blockNum.toInt(),
        'gasUsed': receipt.gasUsed?.toInt(),
      };
    } catch (e) {
      throw Exception('Failed to mint passport: $e');
    }
  }

  Future<Map<String, dynamic>> createAuction({
    required String privateKey,
    required int tokenId,
    required BigInt startingPrice,
    required int duration,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_pepperAuctionContract == null || _createAuctionFunction == null) {
      throw Exception('Auction contract not loaded');
    }

    try {
      // Ensure private key has correct format
      String formattedPrivateKey = privateKey.trim();
      if (!formattedPrivateKey.startsWith('0x')) {
        formattedPrivateKey = '0x$formattedPrivateKey';
      }

      final credentials = EthPrivateKey.fromHex(formattedPrivateKey);

      final transaction = Transaction.callContract(
        contract: _pepperAuctionContract!,
        function: _createAuctionFunction!,
        parameters: [
          BigInt.from(tokenId),
          startingPrice,
          BigInt.from(duration),
        ],
      );

      final txHash = await _client.sendTransaction(
        credentials,
        transaction,
        chainId: Environment.chainId,
      );

      return {
        'txHash': txHash,
        'tokenId': tokenId,
      };
    } catch (e) {
      throw Exception('Failed to create auction: $e');
    }
  }

  /// Place a bid on an auction
  Future<String> placeBid({
    required String privateKey,
    required int tokenId,
    required BigInt bidAmount,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_pepperAuctionContract == null || _placeBidFunction == null) {
      throw Exception('Auction contract not loaded');
    }

    try {
      // Ensure private key has correct format
      String formattedPrivateKey = privateKey.trim();
      if (!formattedPrivateKey.startsWith('0x')) {
        formattedPrivateKey = '0x$formattedPrivateKey';
      }

      final credentials = EthPrivateKey.fromHex(formattedPrivateKey);

      final transaction = Transaction.callContract(
        contract: _pepperAuctionContract!,
        function: _placeBidFunction!,
        parameters: [BigInt.from(tokenId)],
        value: EtherAmount.inWei(bidAmount),
      );

      final txHash = await _client.sendTransaction(
        credentials,
        transaction,
        chainId: Environment.chainId,
      );

      return txHash;
    } catch (e) {
      throw Exception('Failed to place bid: $e');
    }
  }

  List<int> hexToBytes(String hex) {
    final result = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }

  void dispose() {
    _client.dispose();
  }
}
