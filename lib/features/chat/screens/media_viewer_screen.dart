import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:open_filex/open_filex.dart';

class MediaViewerScreen extends StatelessWidget {
  final String url;
  final String? fileName;

  const MediaViewerScreen({super.key, required this.url, this.fileName});

  @override
  Widget build(BuildContext context) {
    final isImage = url.toLowerCase().contains('.jpg') || 
                  url.toLowerCase().contains('.jpeg') || 
                  url.toLowerCase().contains('.png') ||
                  url.toLowerCase().contains('.gif') ||
                  url.startsWith('https://'); // Assume images for https in this mock context

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: fileName != null ? Text(fileName!, style: const TextStyle(color: Colors.white)) : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: () {
              // DOWNLOAD LOGIC
            },
          ),
        ],
      ),
      body: Center(
        child: isImage 
          ? InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: url,
                placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
                errorWidget: (context, url, error) => Image.asset(url, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.white, size: 50)),
                fit: BoxFit.contain,
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.description_rounded, size: 100, color: Colors.white54),
                const SizedBox(height: 24),
                Text(fileName ?? "Document", style: const TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => _openFile(url),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text("Ouvrir le fichier"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Future<void> _openFile(String path) async {
    try {
      await OpenFilex.open(path);
    } catch (e) {
      debugPrint("Error opening file: $e");
    }
  }
}
