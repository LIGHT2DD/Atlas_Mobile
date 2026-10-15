class NotificationModel {
  final String id;
  final String? title;
  final String content;
  final String type;
  final bool isRead;
  final String? link;
  final String? createdAt;

  NotificationModel({
    required this.id,
    this.title,
    required this.content,
    required this.type,
    required this.isRead,
    this.link,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String?,
      content: json['content']?.toString() ?? '',
      type: json['type'] as String? ?? 'system',
      isRead: json['is_read'] == true || json['is_read'] == 1,
      link: json['link'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}
