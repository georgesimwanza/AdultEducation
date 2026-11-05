import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CdnSupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  final String bucketName = 'Adult Education CDN';

  Future<String?> uploadContent(PlatformFile file, String courseId) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final path = '$courseId/$fileName';
      print('⬆️ Uploading to Supabase: $path');
      // Browsers expose the picked file's bytes, never a file path.
      await _client.storage.from(bucketName).uploadBinary(path, file.bytes!);

      final publicUrl = _client.storage.from(bucketName).getPublicUrl(path);
      print('✅ Upload success: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Upload failed: $e');
      return null;
    }
  }
}
