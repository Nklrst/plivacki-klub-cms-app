import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import '../models/message.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).fetchMessages();
    });
  }

  IconData _iconForScope(String scope) {
    switch (scope) {
      case 'BROADCAST_ALL':
        return Icons.campaign;
      case 'DIRECT':
        return Icons.person;
      case 'INTERNAL_STAFF':
        return Icons.security;
      case 'GROUP_SCHEDULE':
        return Icons.groups;
      default:
        return Icons.mail;
    }
  }

  Color _colorForScope(String scope) {
    switch (scope) {
      case 'BROADCAST_ALL':
        return Colors.orange;
      case 'DIRECT':
        return Colors.blue;
      case 'INTERNAL_STAFF':
        return Colors.grey.shade700;
      case 'GROUP_SCHEDULE':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  String _labelForScope(String scope) {
    switch (scope) {
      case 'BROADCAST_ALL':
        return 'Obaveštenje';
      case 'DIRECT':
        return 'Direktna poruka';
      case 'INTERNAL_STAFF':
        return 'Interno';
      case 'GROUP_SCHEDULE':
        return 'Grupna poruka';
      default:
        return 'Poruka';
    }
  }

  void _showDetailDialog(Message msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(_iconForScope(msg.scope), color: _colorForScope(msg.scope)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg.senderName, style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _colorForScope(msg.scope).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _labelForScope(msg.scope),
                  style: TextStyle(
                    fontSize: 12,
                    color: _colorForScope(msg.scope),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                msg.content,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 16),
              Text(
                DateFormat('dd. MMM yyyy, HH:mm').format(msg.sentAt),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Zatvori"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context);
    final messages = provider.allMessages;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Obaveštenja"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : messages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Nema novih obaveštenja",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final msg = messages[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 1,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: _colorForScope(
                        msg.scope,
                      ).withOpacity(0.15),
                      child: Icon(
                        _iconForScope(msg.scope),
                        color: _colorForScope(msg.scope),
                      ),
                    ),
                    title: Text(
                      msg.senderName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      msg.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      DateFormat('dd. MMM\nHH:mm').format(msg.sentAt),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    onTap: () => _showDetailDialog(msg),
                  ),
                );
              },
            ),
    );
  }
}
