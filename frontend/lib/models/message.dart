class Message {
  final int id;
  final int senderId;
  final String content;
  final String scope;
  final DateTime sentAt;
  final String? imageUrl;
  final int? recipientId;
  final int? targetScheduleId;
  final String senderName;

  Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.scope,
    required this.sentAt,
    this.imageUrl,
    this.recipientId,
    this.targetScheduleId,
    required this.senderName,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      content: json['content'],
      scope: json['scope'],
      sentAt: DateTime.parse(json['sent_at']),
      imageUrl: json['image_url'],
      recipientId: json['recipient_id'],
      targetScheduleId: json['target_schedule_id'],
      senderName: json['sender_name'] ?? '',
    );
  }
}
