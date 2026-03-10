import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../config/env.dart';

class ApiService {
  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Environment.apiBaseUrl,
        connectTimeout:
            const Duration(seconds: 60), // Increased for physical devices
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Add comprehensive HTTP logging
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: true,
        error: true,
        compact: false,
        maxWidth: 120,
        enabled: true, // Set to false in production
        filter: (options, args) {
          // Log all requests
          return true;
        },
      ),
    );

    // Add auth token interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token if available
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          print('🔹 REQUEST: ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
              '✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (error, handler) {
          print('❌ API Error: ${error.message}');
          if (error.response != null) {
            print('   Status: ${error.response?.statusCode}');
            print('   Data: ${error.response?.data}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Auth endpoints
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/auth/register', data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        // Extract error message from response
        final errorData = e.response!.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        } else if (errorData is Map && errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/auth/login', data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        // Extract error message from response
        final errorData = e.response!.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        } else if (errorData is Map && errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Lot endpoints
  Future<List<dynamic>> getLots({String? farmerAddress, String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (farmerAddress != null) queryParams['farmer'] = farmerAddress;
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get(
        '/lots',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return response.data['lots'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getLotById(String lotId) async {
    try {
      final response = await _dio.get('/lots/$lotId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createLot(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/lots', data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        // Extract error message from response
        final errorData = e.response!.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        } else if (errorData is Map && errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      rethrow;
    }
  }

  // Auction endpoints
  Future<List<dynamic>> getAuctions({String? farmerAddress}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (farmerAddress != null && farmerAddress.isNotEmpty) {
        queryParams['farmer'] = farmerAddress;
      }
      final response = await _dio.get(
        '/auctions',
        queryParameters: queryParams,
      );
      return response.data['auctions'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAuctionById(String auctionId) async {
    try {
      final response = await _dio.get('/auctions/$auctionId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createAuction(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/auctions', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> placeBid(
    String auctionId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post('/auctions/$auctionId/bid', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Get user's bids
  Future<Map<String, dynamic>> getUserBids(String userId) async {
    try {
      final response = await _dio.get('/auctions/bids/user/$userId');
      final data = response.data as Map<String, dynamic>;

      // Helper function to convert Firebase Timestamp to ISO string
      String? convertFirebaseTimestamp(dynamic timestamp) {
        if (timestamp == null) return null;
        if (timestamp is String) return timestamp;
        if (timestamp is Map && timestamp['_seconds'] != null) {
          final seconds = timestamp['_seconds'] as int;
          final dateTime =
              DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
          return dateTime.toIso8601String();
        }
        return null;
      }

      // Transform camelCase to snake_case for auction data
      if (data['auctions'] != null) {
        final auctions = (data['auctions'] as List).map((auction) {
          return {
            'auction_id': auction['auctionId'],
            'lot_id': auction['lotId'],
            'status': auction['status'],
            'current_bid': auction['currentBid'],
            'start_time': convertFirebaseTimestamp(auction['startTime']),
            'end_time': convertFirebaseTimestamp(auction['endTime']),
            'farmer_address': auction['farmerAddress'],
            'reserve_price': auction['reservePrice'],
            'bid_count': auction['bidCount'],
            'variety': auction['variety'],
            'quantity': auction['quantity'],
            'quality': auction['quality'],
            'is_leading': auction['isLeading'],
            'my_highest_bid': auction['myHighestBid'],
            'my_highest_bid_lkr': auction['myHighestBidLkr'],
            'my_bids': (auction['myBids'] as List?)?.map((bid) {
                  return {
                    'id': bid['id'],
                    'amount': bid['amount'],
                    'amount_lkr': bid['amountLkr'],
                    'currency': bid['currency'],
                    'placed_at': convertFirebaseTimestamp(bid['placedAt']),
                    'status': bid['status'],
                  };
                }).toList() ??
                [],
          };
        }).toList();

        return {
          'success': data['success'],
          'count': data['count'],
          'auctions': auctions,
          'message': data['message'],
        };
      }

      return data;
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? address,
    String? city,
    String? language,
    String? walletAddress,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;
      if (address != null) data['address'] = address;
      if (city != null) data['city'] = city;
      if (language != null) data['language'] = language;
      if (walletAddress != null) data['walletAddress'] = walletAddress;

      final response = await _dio.put('/auth/profile', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Compliance endpoints
  Future<Map<String, dynamic>> checkCompliance(String lotId) async {
    try {
      final response = await _dio.get('/compliance/$lotId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // NFT Passport endpoints
  Future<Map<String, dynamic>> mintPassport(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/nft-passport/mint', data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception('Failed to mint passport: ${errorData['error']}');
        } else if (errorData is Map && errorData.containsKey('message')) {
          throw Exception('Failed to mint passport: ${errorData['message']}');
        }
      }
      throw Exception(
          'Failed to mint passport: Network error. Please check your connection.');
    } catch (e) {
      throw Exception('Failed to mint passport: ${e.toString()}');
    }
  }

  // File upload
  Future<String> uploadFile(String filePath) async {
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post('/upload', data: formData);
      return response.data['url'];
    } catch (e) {
      rethrow;
    }
  }

  // Quality Grading
  Future<Map<String, dynamic>> saveQualityGrading(
      Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/quality-grading', data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        } else if (errorData is Map && errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getQualityGradingHistory() async {
    try {
      final response = await _dio.get('/quality-grading/history');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Generic HTTP methods
  Future<dynamic> get(String endpoint,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      final response =
          await _dio.get(endpoint, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        } else if (errorData is Map && errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic>? data) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        } else if (errorData is Map && errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic>? data) async {
    try {
      final response = await _dio.patch(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        } else if (errorData is Map && errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await _dio.delete(endpoint);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        } else if (errorData is Map && errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      rethrow;
    }
  }

  // Processing Stages endpoint
  Future<Map<String, dynamic>> addProcessingStage({
    required String lotId,
    required String stageType,
    required String stageName,
    required String location,
    required String timestamp,
    required String operatorName,
    required Map<String, dynamic> qualityMetrics,
    required String notes,
  }) async {
    try {
      final response = await _dio.post('/processing/stages', data: {
        'lotId': lotId,
        'stageType': stageType,
        'stageName': stageName,
        'location': location,
        'timestamp': timestamp,
        'operatorName': operatorName,
        'qualityMetrics': qualityMetrics,
        'notes': notes,
      });
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        } else if (errorData is Map && errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to add processing stage');
    } catch (e) {
      rethrow;
    }
  }

  // Lock escrow for auction
  Future<Map<String, dynamic>> lockEscrow({
    required String auctionId,
    required String exporterAddress,
    required String transactionHash,
  }) async {
    try {
      final response = await _dio.post(
        '/auctions/$auctionId/escrow/lock',
        data: {
          'exporterAddress': exporterAddress,
          'transactionHash': transactionHash,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Settle auction (after delivery confirmation)
  Future<Map<String, dynamic>> settleAuction({
    required String auctionId,
  }) async {
    try {
      final response = await _dio.post('/auctions/$auctionId/settle');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Pepper Varieties endpoints
  Future<List<Map<String, dynamic>>> getPepperVarieties() async {
    try {
      final response = await _dio.get('/pepper-varieties');
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
            response.data['error'] ?? 'Failed to fetch pepper varieties');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        } else if (errorData is Map && errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      rethrow;
    }
  }

  /// Get simplified pepper variety names for dropdown
  /// Returns a list with id, name (localized), nameEn, and nameSi
  Future<List<Map<String, dynamic>>> getPepperVarietyNames({
    String language = 'en',
  }) async {
    try {
      final response = await _dio.get(
        '/pepper-varieties/simple/names',
        queryParameters: {'lang': language},
      );
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
            response.data['error'] ?? 'Failed to fetch variety names');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        } else if (errorData is Map && errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      rethrow;
    }
  }

  // Price Prediction endpoints

  /// Get latest price predictions for all districts and grades
  /// Optional filters: district, grade
  Future<Map<String, dynamic>> getLatestPricePredictions({
    String? district,
    String? grade,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (district != null && district.isNotEmpty) {
        queryParams['district'] = district;
      }
      if (grade != null && grade.isNotEmpty) {
        queryParams['grade'] = grade;
      }

      final response = await _dio.get(
        '/price-predictions/latest',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get price prediction for a specific lot based on its district and quality
  Future<Map<String, dynamic>> getPricePredictionForLot(String lotId) async {
    try {
      final response = await _dio.get('/price-predictions/by-lot/$lotId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get historical price predictions
  Future<Map<String, dynamic>> getHistoricalPricePredictions({
    String? district,
    String? grade,
    int days = 7,
  }) async {
    try {
      final queryParams = <String, dynamic>{'days': days};
      if (district != null && district.isNotEmpty) {
        queryParams['district'] = district;
      }
      if (grade != null && grade.isNotEmpty) {
        queryParams['grade'] = grade;
      }

      final response = await _dio.get(
        '/price-predictions/history',
        queryParameters: queryParams,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get list of districts with available predictions
  Future<List<String>> getPredictionDistricts() async {
    try {
      final response = await _dio.get('/price-predictions/districts');
      if (response.data['success'] == true) {
        final List<dynamic> districts = response.data['districts'] ?? [];
        return districts.cast<String>();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
