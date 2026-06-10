class TicketDepartment {
  final int id;
  final String name;
  final String icon;

  const TicketDepartment({
    required this.id,
    required this.name,
    required this.icon,
  });

  factory TicketDepartment.fromJson(Map<String, dynamic> json) {
    return TicketDepartment(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
    );
  }
}

class TicketAssignee {
  final String name;
  final String avatar;

  const TicketAssignee({
    required this.name,
    required this.avatar,
  });

  factory TicketAssignee.fromJson(Map<String, dynamic>? json) {
    return TicketAssignee(
      name: json?['name']?.toString() ?? 'Unassigned',
      avatar: json?['avatar']?.toString() ?? '',
    );
  }
}

class Ticket {
  final String id;
  final String title;
  final String description;
  final String department;
  final String priority;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final TicketAssignee assignee;
  final int conversationCount;

  const Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.department,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.assignee,
    required this.conversationCount,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      priority: json['priority']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      assignee: TicketAssignee.fromJson(_asMap(json['assignee'])),
      conversationCount: _parseInt(json['conversation_count']),
    );
  }
}

class TicketDetail extends Ticket {
  final List<TicketConversation> conversation;
  final TicketAttachment? attachment;

  const TicketDetail({
    required super.id,
    required super.title,
    required super.description,
    required super.department,
    required super.priority,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    required super.assignee,
    required super.conversationCount,
    required this.conversation,
    required this.attachment,
  });

  factory TicketDetail.fromJson(Map<String, dynamic> json) {
    final ticket = Ticket.fromJson(json);
    final conversationList = json['conversation'];

    return TicketDetail(
      id: ticket.id,
      title: ticket.title,
      description: ticket.description,
      department: ticket.department,
      priority: ticket.priority,
      status: ticket.status,
      createdAt: ticket.createdAt,
      updatedAt: ticket.updatedAt,
      assignee: ticket.assignee,
      conversationCount: ticket.conversationCount,
      conversation: conversationList is List
          ? conversationList
              .whereType<Map<String, dynamic>>()
              .map(TicketConversation.fromJson)
              .toList()
          : <TicketConversation>[],
      attachment: _asMap(json['attachment']) == null
          ? null
          : TicketAttachment.fromJson(_asMap(json['attachment'])!),
    );
  }
}

class TicketConversation {
  final int id;
  final String type;
  final TicketAssignee author;
  final String content;
  final DateTime? timestamp;

  const TicketConversation({
    required this.id,
    required this.type,
    required this.author,
    required this.content,
    required this.timestamp,
  });

  bool get isCustomer => type.toLowerCase() == 'customer';

  factory TicketConversation.fromJson(Map<String, dynamic> json) {
    return TicketConversation(
      id: _parseInt(json['id']),
      type: json['type']?.toString() ?? '',
      author: TicketAssignee.fromJson(_asMap(json['author'])),
      content: json['content']?.toString() ?? '',
      timestamp: _parseDate(json['timestamp']),
    );
  }
}

class TicketAttachment {
  final String filename;
  final String path;
  final String url;

  const TicketAttachment({
    required this.filename,
    required this.path,
    required this.url,
  });

  factory TicketAttachment.fromJson(Map<String, dynamic> json) {
    return TicketAttachment(
      filename: json['filename']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }
}

class TicketPagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const TicketPagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory TicketPagination.fromJson(Map<String, dynamic>? json) {
    return TicketPagination(
      currentPage: _parseInt(json?['current_page'], fallback: 1),
      lastPage: _parseInt(json?['last_page'], fallback: 1),
      perPage: _parseInt(json?['per_page'], fallback: 6),
      total: _parseInt(json?['total']),
    );
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

int _parseInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime? _parseDate(dynamic value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
