# Machine Learning Model Integration Guide

This guide details how to use the newly implemented Price Prediction API in your mobile application.

## API Endpoint

**URL**: `POST /api/prediction/predict`  
**Content-Type**: `application/json`

### Request Body
```json
{
  "usdBuyRate": 300.50,
  "usdSellRate": 310.00,
  "temperature": 28.5,
  "precipitation": 0.0,
  "date": "2024-12-31T00:00:00",
  "location": "Colombo",
  "grade": "GR-2"
}
```

- **location**: One of `Colombo`, `Galle`, `Hambantota`, `Kandy`, `Kegalle`, `Kurunegala`, `Matale`, `Matara`, `Monaragala` (Case-insensitive).
- **grade**: One of `GR-1`, `GR-2`, `WHITE` (Case-insensitive).

### Response Body
```json
{
  "highestPrice": 1500.50,
  "averagePrice": 1450.00,
  "currency": "LKR"
}
```

---

## Flutter Integration Code

Copy these files into your Flutter project (e.g., `lib/services/` and `lib/models/`).

### 1. Data Models (`price_prediction_model.dart`)

```dart
class PricePredictionRequest {
  final double usdBuyRate;
  final double usdSellRate;
  final double temperature;
  final double precipitation;
  final DateTime date;
  final String location;
  final String grade;

  PricePredictionRequest({
    required this.usdBuyRate,
    required this.usdSellRate,
    required this.temperature,
    required this.precipitation,
    required this.date,
    required this.location,
    required this.grade,
  });

  Map<String, dynamic> toJson() {
    return {
      'usdBuyRate': usdBuyRate,
      'usdSellRate': usdSellRate,
      'temperature': temperature,
      'precipitation': precipitation,
      'date': date.toIso8601String(),
      'location': location,
      'grade': grade,
    };
  }
}

class PricePredictionResult {
  final double highestPrice;
  final double averagePrice;
  final String currency;

  PricePredictionResult({
    required this.highestPrice,
    required this.averagePrice,
    required this.currency,
  });

  factory PricePredictionResult.fromJson(Map<String, dynamic> json) {
    return PricePredictionResult(
      highestPrice: (json['highestPrice'] as num).toDouble(),
      averagePrice: (json['averagePrice'] as num).toDouble(),
      currency: json['currency'] ?? 'LKR',
    );
  }
}
```

### 2. Service Class (`prediction_service.dart`)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'price_prediction_model.dart'; // Import the model above

class PredictionService {
  // Update with your actual backend URL (use 10.0.2.2 for Android Emulator)
  final String baseUrl = "http://10.0.2.2:5000/api"; 

  Future<PricePredictionResult> getPricePrediction(PricePredictionRequest request) async {
    final url = Uri.parse('$baseUrl/prediction/predict');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $token', // Add token if endpoint is protected
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return PricePredictionResult.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get prediction: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to prediction service: $e');
    }
  }
}
```

### 3. Usage Example (in a Widget)

```dart
// Inside your State class
final _predictionService = PredictionService();
String _result = "";

void _predict() async {
  final request = PricePredictionRequest(
    usdBuyRate: 300.0,
    usdSellRate: 310.0,
    temperature: 30.0,
    precipitation: 10.0,
    date: DateTime.now(),
    location: "Kandy",
    grade: "GR-1",
  );

  try {
    final result = await _predictionService.getPricePrediction(request);
    setState(() {
      _result = "High: ${result.highestPrice}, Avg: ${result.averagePrice}";
    });
  } catch (e) {
    setState(() {
      _result = "Error: $e";
    });
  }
}
```
