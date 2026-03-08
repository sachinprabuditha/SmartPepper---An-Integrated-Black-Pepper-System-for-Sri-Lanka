import 'localized_string.dart';

class SoilType {
  final String id;
  final LocalizedString typeName;

  SoilType({
    required this.id,
    required this.typeName,
  });

  factory SoilType.fromJson(Map<String, dynamic> json) {
    return SoilType(
      id: json['id'].toString(),
      typeName: LocalizedString.fromJson(json['typeName'] ?? json['name']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'typeName': typeName.toJson(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SoilType &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          typeName == other.typeName;

  @override
  int get hashCode => id.hashCode ^ typeName.hashCode;
}

