class CountryModel {
  final int id;
  final String name;
  final String? code;

  CountryModel({required this.id, required this.name, this.code});

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] is String ? json['name'] : '',
      code: json['code'] is String ? json['code'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'code': code};
  }
}

class StateModel {
  final int id;
  final String name;
  final int countryId;

  StateModel({required this.id, required this.name, required this.countryId});

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] is String ? json['name'] : '',
      countryId:
          json['country_id'] is int
              ? json['country_id']
              : int.tryParse(json['country_id'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'country_id': countryId};
  }
}

class CityModel {
  final int id;
  final String name;
  final int stateId;

  CityModel({required this.id, required this.name, required this.stateId});

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] is String ? json['name'] : '',
      stateId:
          json['state_id'] is int
              ? json['state_id']
              : int.tryParse(json['state_id'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'state_id': stateId};
  }
}

class DropdownResponse {
  final bool success;
  final String message;
  final List<dynamic> data;

  DropdownResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory DropdownResponse.fromJson(Map<String, dynamic> json) {
    return DropdownResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] is List ? json['data'] : [],
    );
  }
}
