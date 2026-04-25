import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

class ChatApiService {
  final Dio _dio;

  ChatApiService(this._dio);

  // ---------------------------------------------------------------------------
  // GET /messages  — flat list filtered by the server for the current user
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchMessages({int page = 1}) async {
    final response = await _dio.get('/messages',
        queryParameters: {'page': page, 'limit': 100});
    final raw = response.data;
    final List data = (raw is Map ? raw['data'] : raw) ?? [];
    return data
        .map((e) => e is Map<String, dynamic>
            ? e
            : Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // POST /messages  — send a new message
  //   recipientType: 'broadcast' | 'class' | 'individual'
  //   targetClass:   class _id   (required for recipientType == 'class')
  //   targetUser:    user _id    (required for recipientType == 'individual')
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> sendMessage({
    required String content,
    required String recipientType,
    String? targetUserId,
    String? targetClassId,
    bool allowReply = true,
  }) async {
    final body = <String, dynamic>{
      'content': content,
      'recipientType': recipientType,
      'allowReply': allowReply,
      if (targetUserId != null) 'targetUser': targetUserId,
      if (targetClassId != null) 'targetClass': targetClassId,
    };
    final response = await _dio.post('/messages', data: body);
    final raw = response.data;
    final List data = (raw is Map ? raw['data'] : [raw]) ?? [];
    return data.isNotEmpty
        ? (data.first is Map<String, dynamic>
            ? data.first as Map<String, dynamic>
            : Map<String, dynamic>.from(data.first as Map))
        : {};
  }

  // ---------------------------------------------------------------------------
  // POST /messages/:id/reply
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> replyToMessage(
      String messageId, String content) async {
    final response = await _dio.post('/messages/$messageId/reply',
        data: {'content': content});
    final raw = response.data;
    return (raw is Map ? raw['data'] ?? raw : raw) as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // POST /messages  — send a new message with file attachment (teacher)
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> sendMessageWithAttachment({
    required String recipientType,
    String? targetUserId,
    String? targetClassId,
    String content = '',
    required String filePath,
    required String fileName,
    required String mimeType,
    bool allowReply = true,
  }) async {
    final formData = FormData.fromMap({
      'content': content,
      'recipientType': recipientType,
      'allowReply': allowReply,
      if (targetUserId != null) 'targetUser': targetUserId,
      if (targetClassId != null) 'targetClass': targetClassId,
      'attachments': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ),
    });
    final response = await _dio.post(
      '/messages',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final raw = response.data;
    final List data = (raw is Map ? raw['data'] : [raw]) ?? [];
    return data.isNotEmpty
        ? (data.first is Map<String, dynamic>
            ? data.first as Map<String, dynamic>
            : Map<String, dynamic>.from(data.first as Map))
        : {};
  }

  // ---------------------------------------------------------------------------
  // POST /messages/:id/reply  — with file attachment
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> replyWithAttachment({
    required String messageId,
    String content = '',
    required String filePath,
    required String fileName,
    required String mimeType,
  }) async {
    final formData = FormData.fromMap({
      'content': content,
      'attachments': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ),
    });
    final response = await _dio.post(
      '/messages/$messageId/reply',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final raw = response.data;
    return (raw is Map ? raw['data'] ?? raw : raw) as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // PUT /messages/:id  — edit message content
  // ---------------------------------------------------------------------------
  Future<bool> editMessage(String messageId, String content) async {
    final response =
        await _dio.put('/messages/$messageId', data: {'content': content});
    return response.statusCode == 200;
  }

  // ---------------------------------------------------------------------------
  // DELETE /messages/:id  — soft delete (sets isActive = false)
  // ---------------------------------------------------------------------------
  Future<bool> deleteMessage(String messageId) async {
    final response = await _dio.delete('/messages/$messageId');
    return response.statusCode == 200;
  }

  // ---------------------------------------------------------------------------
  // PUT /messages/:id/read
  // ---------------------------------------------------------------------------
  Future<void> markAsRead(String messageId) async {
    await _dio.put('/messages/$messageId/read');
  }

  // ---------------------------------------------------------------------------
  // GET /messages/recipients  — users the current teacher can message
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getRecipients() async {
    try {
      final response = await _dio.get('/messages/recipients');
      final raw = response.data;
      final List data = (raw is Map ? raw['data'] : raw) ?? [];
      return data
          .map((e) => e is Map<String, dynamic>
              ? e
              : Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
