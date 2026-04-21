import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../parent/viewmodels/chat_view_model.dart';
import '../../../core/models/models.dart';
import 'media_viewer_screen.dart';

class ChatDetailsScreen extends StatelessWidget {
  final ChatThreadModel thread;

  const ChatDetailsScreen({super.key, required this.thread});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Détails du chat", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Consumer<ChatViewModel>(
        builder: (context, vm, child) {
          final mediaMessages = vm.activeMessages.where((m) => m.type == 'image').toList();
          final docMessages = vm.activeMessages.where((m) => m.type == 'document').toList();

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Profile Section
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: thread.avatarUrl != null ? NetworkImage(thread.avatarUrl!) : null,
                        backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                        child: thread.avatarUrl == null
                            ? Text(thread.contactName.substring(0, 1).toUpperCase(), 
                                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.blueAccent))
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(thread.contactName, 
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryTextColor)),
                      Text(thread.contactRole, 
                        style: TextStyle(fontSize: 14, color: secondaryTextColor)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Media Section
                _buildSectionHeader(context, "Média partagés", mediaMessages.length.toString()),
                if (mediaMessages.isEmpty)
                   _buildEmptyMedia(context, "Pas de médias")
                else
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: mediaMessages.length,
                      itemBuilder: (context, index) {
                        final url = mediaMessages[index].attachments.isNotEmpty 
                            ? mediaMessages[index].attachments.first 
                            : '';
                        if (url.isEmpty) return const SizedBox.shrink();
                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MediaViewerScreen(url: url))),
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: CachedNetworkImageProvider(url),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Documents Section
                _buildSectionHeader(context, "Documents", docMessages.length.toString()),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docMessages.length,
                  itemBuilder: (context, index) {
                    final msg = docMessages[index];
                    return ListTile(
                      leading: const Icon(Icons.description_rounded, color: Colors.blue),
                      title: Text(msg.content, style: TextStyle(color: primaryTextColor, fontSize: 14)),
                      subtitle: Text(msg.time, style: TextStyle(color: secondaryTextColor, fontSize: 12)),
                      onTap: () {
                        // Open Doc
                      },
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildActionItem(
                        context, 
                        Icons.delete_outline_rounded, 
                        "Supprimer la conversation", 
                        Colors.redAccent,
                        () => _showDeleteConfirm(context, vm),
                      ),
                      const SizedBox(height: 12),
                      _buildActionItem(
                        context, 
                        Icons.block_rounded, 
                        "Bloquer le contact", 
                        Colors.redAccent,
                        () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(count, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyMedia(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(text, style: const TextStyle(color: Colors.grey)),
    );
  }

  Widget _buildActionItem(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, ChatViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer la conversation ?"),
        content: const Text("Cette action est irréversible. Voulez-vous continuer ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              final ok = await vm.deleteConversation(thread.id);
              if (ok && context.mounted) {
                Navigator.pop(context); // Go back to list
                Navigator.pop(context); // Go back to home if needed
              }
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
