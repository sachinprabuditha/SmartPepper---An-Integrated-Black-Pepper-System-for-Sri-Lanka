import 'localized_string.dart';

class District {
  final String id;
  final LocalizedString name;

  District({required this.id, required this.name});

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'].toString(),
      name: LocalizedString.fromJson(json['name']),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name.toJson()};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is District &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
