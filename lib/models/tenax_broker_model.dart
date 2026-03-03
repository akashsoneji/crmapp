class TenaxBrokerModel {
  final String id;
  final String slug;
  final String name;
  final String displayName;
  final String subTitle;
  final String logoUrl;
  final Map<String, dynamic> raw;

  const TenaxBrokerModel({
    required this.id,
    required this.slug,
    required this.name,
    required this.displayName,
    required this.subTitle,
    required this.logoUrl,
    required this.raw,
  });

  factory TenaxBrokerModel.fromJson(Map<String, dynamic> json) {
    final name =
        (json['name'] ??
                json['broker_name'] ??
                json['company_name'] ??
                json['title'] ??
                '')
            .toString();
    final subTitle =
        (json['short_name'] ??
                json['display_name'] ??
                json['slug'] ??
                json['code'] ??
                name)
            .toString();
    final logoUrl =
        (json['logo_url'] ??
                json['logoUrl'] ??
                json['logo'] ??
                json['icon'] ??
                '')
            .toString();

    return TenaxBrokerModel(
      id:
          (json['broker_id'] ?? json['id'] ?? json['uuid'] ?? name).toString(),
      slug: (json['slug'] ?? '').toString(),
      name: name,
      displayName: _toCamelCase(name),
      subTitle: subTitle,
      logoUrl: logoUrl,
      raw: json,
    );
  }

  static String _toCamelCase(String input) {
    final cleaned = input.trim().replaceAll(RegExp(r'[_\-\s]+'), ' ');
    if (cleaned.isEmpty) return '';
    return cleaned
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.length > 1 ? part.substring(1).toLowerCase() : ''}',
        )
        .join(' ');
  }
}
