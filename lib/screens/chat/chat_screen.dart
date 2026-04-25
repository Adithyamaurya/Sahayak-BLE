import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sahayak/theme.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Responder Chat'),
            Text(
              'Dr. Smith • Active Now',
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10, color: AppTheme.accent),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(LucideIcons.phone, size: 20), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                _buildMessageBubble(
                  context, 
                  'Hello Ravi, I see your request. I\'m only 2 minutes away from your location. Stay calm.', 
                  true
                ),
                _buildMessageBubble(
                  context, 
                  'Thank you so much! I am waiting near the North Gate entrance.', 
                  false
                ),
                _buildMessageBubble(
                  context, 
                  'Understood. I have the medical kit ready.', 
                  true
                ),
              ],
            ),
          ),
          
          // Floating Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.plus, color: AppTheme.primary, size: 20),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(fontSize: 14),
                      fillColor: AppTheme.background,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.primaryGlow,
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.send, color: Colors.white, size: 18),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, String text, bool isResponder) {
    return Align(
      alignment: isResponder ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isResponder ? AppTheme.surface : AppTheme.primary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isResponder ? 4 : 20),
            bottomRight: Radius.circular(isResponder ? 20 : 4),
          ),
          boxShadow: isResponder ? AppTheme.softShadow : AppTheme.primaryGlow,
          border: isResponder ? Border.all(color: AppTheme.primary.withValues(alpha: 0.1)) : null,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isResponder ? AppTheme.textDark : Colors.white,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
