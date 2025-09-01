class SocketResponse {
  final List<Group> groups;

  SocketResponse({required this.groups});

  SocketResponse copyWith({List<Group>? groups}) =>
      SocketResponse(groups: groups ?? this.groups);

  factory SocketResponse.fromJson(Map<String, dynamic> json) {
    return SocketResponse(
      groups:
          (json['groups'] as List)
              .map((group) => Group.fromJson(group))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'groups': groups.map((group) => group.toJson()).toList()};
  }
}

class Group {
  final String groupName;
  final List<ListElement> list;

  Group({required this.groupName, required this.list});

  Group copyWith({String? groupName, List<ListElement>? list}) =>
      Group(groupName: groupName ?? this.groupName, list: list ?? this.list);

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      groupName: json['group_name'] ?? '',
      list:
          (json['list'] as List)
              .map((item) => ListElement.fromJson(item))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group_name': groupName,
      'list': list.map((item) => item.toJson()).toList(),
    };
  }
}

class ListElement {
  final String symbol;
  final int digits;
  final double bid;
  final double ask;
  final int last;
  final int volume;
  final int volumeReal;
  final String logo;
  final double spreadDiff;

  ListElement({
    required this.symbol,
    required this.digits,
    required this.bid,
    required this.ask,
    required this.last,
    required this.volume,
    required this.volumeReal,
    required this.logo,
    required this.spreadDiff,
  });

  ListElement copyWith({
    String? symbol,
    int? digits,
    double? bid,
    double? ask,
    int? last,
    int? volume,
    int? volumeReal,
    String? logo,
    double? spreadDiff,
  }) => ListElement(
    symbol: symbol ?? this.symbol,
    digits: digits ?? this.digits,
    bid: bid ?? this.bid,
    ask: ask ?? this.ask,
    last: last ?? this.last,
    volume: volume ?? this.volume,
    volumeReal: volumeReal ?? this.volumeReal,
    logo: logo ?? this.logo,
    spreadDiff: spreadDiff ?? this.spreadDiff,
  );

  factory ListElement.fromJson(Map<String, dynamic> json) {
    return ListElement(
      symbol: json['Symbol'] ?? '',
      digits: json['Digits'] ?? 0,
      bid: (json['Bid'] ?? 0.0).toDouble(),
      ask: (json['Ask'] ?? 0.0).toDouble(),
      last: json['Last'] ?? 0,
      volume: json['Volume'] ?? 0,
      volumeReal: json['VolumeReal'] ?? 0,
      logo: json['logo'] ?? '',
      spreadDiff: (json['SpreadDiff'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Symbol': symbol,
      'Digits': digits,
      'Bid': bid,
      'Ask': ask,
      'Last': last,
      'Volume': volume,
      'VolumeReal': volumeReal,
      'logo': logo,
      'SpreadDiff': spreadDiff,
    };
  }
}
