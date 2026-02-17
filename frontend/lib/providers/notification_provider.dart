import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/message.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiClient _api;
  List<Message> _messages = [];
  bool _isLoading = false;

  NotificationProvider(this._api);

  List<Message> get allMessages {
    final sorted = List<Message>.from(_messages);
    sorted.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return sorted;
  }

  bool get hasUnread => _messages.isNotEmpty;
  bool get isLoading => _isLoading;

  Future<void> fetchMessages() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.dio.get('/messages/');
      final List data = res.data;
      _messages = data.map((json) => Message.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching messages: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
