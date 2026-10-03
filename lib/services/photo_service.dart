import 'package:image_picker/image_picker.dart';

class PhotoResult {
  const PhotoResult({this.path, this.error});
  final String? path;
  final String? error;
}

/// Camera / gallery capture. Images are downscaled and recompressed on pick
/// (max 1280 px, JPEG quality 70) before being stored or uploaded.
class PhotoService {
  final ImagePicker _picker = ImagePicker();

  Future<PhotoResult> pick({required bool camera}) async {
    try {
      final file = await _picker.pickImage(
        source: camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 70,
      );
      if (file == null) return const PhotoResult(error: 'No photo selected.');
      return PhotoResult(path: file.path);
    } catch (e) {
      return PhotoResult(
        error: camera ? 'Camera unavailable or permission denied.' : 'Gallery unavailable or permission denied.',
      );
    }
  }
}
