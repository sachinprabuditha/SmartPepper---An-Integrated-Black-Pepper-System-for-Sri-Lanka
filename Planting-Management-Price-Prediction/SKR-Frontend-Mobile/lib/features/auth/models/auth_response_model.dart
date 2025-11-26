import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'auth_response_model.g.dart';

@JsonSerializable()
class AuthResponseModel {
  final String userId;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String token;

  AuthResponseModel({
    required this.userId,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.token,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseModelToJson(this);

  UserModel toUserModel() {
    return UserModel(
      id: userId,
      email: email,
      fullName: fullName,
      phoneNumber: phoneNumber,
    );
  }
}

