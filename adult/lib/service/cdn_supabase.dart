import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class CdnSupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  final String bucketName = 'Adult Education CDN';

  Future<String?> uploadContent(File file, String courseId) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final path = '$courseId/$fileName';
      print('⬆️ Uploading to Supabase: $path');
      await _client.storage.from(bucketName).upload(path, file);

      final publicUrl = _client.storage.from(bucketName).getPublicUrl(path);
      print('✅ Upload success: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Upload failed: $e');
      return null;
    }
  }
}
