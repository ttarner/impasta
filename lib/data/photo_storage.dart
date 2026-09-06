import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

const _photosSubdir = 'preset_photos';

String? _cachedBasePath;

/// Initializes the photos base path. Call once at app startup.
Future<void> initPhotoStorage() async {
  if (kIsWeb) return;
  final dir = await getApplicationDocumentsDirectory();
  _cachedBasePath = '${dir.path}/$_photosSubdir';
}

/// Returns the photos directory path on mobile.
String _photosBasePath() {
  return _cachedBasePath!;
}

/// Resolves a stored media path to an absolute path.
String _resolveMediaPath(String mediaPath) {
  if (mediaPath.startsWith('data:') || mediaPath.startsWith('/') || mediaPath.contains(':\\')) {
    return mediaPath;
  }
  return '${_photosBasePath()}/$mediaPath';
}

/// Saves a picked photo and returns a storable reference.
/// - On mobile: copies to app documents dir, returns relative filename.
/// - On web: reads bytes and returns a base64 data URI.
Future<String> savePhoto(XFile file) async {
  final bytes = await file.readAsBytes();

  if (kIsWeb) {
    final b64 = base64Encode(bytes);
    final mime = file.mimeType ?? 'image/jpeg';
    return 'data:$mime;base64,$b64';
  } else {
    final basePath = _photosBasePath();
    final photosDir = Directory(basePath);
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.name.hashCode}.$ext';
    await File('$basePath/$fileName').writeAsBytes(bytes);
    return fileName;
  }
}

/// Deletes photo files associated with a preset (mobile only).
Future<void> deletePhotos(List<String> mediaPaths) async {
  if (kIsWeb) return;
  for (final path in mediaPaths) {
    if (path.startsWith('data:')) continue;
    final resolved = _resolveMediaPath(path);
    final file = File(resolved);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

/// Returns an ImageProvider for a stored photo reference.
/// For relative paths, resolves against the photos directory synchronously
/// by using a FutureBuilder pattern. Use [loadPhotoProviderAsync] for async.
ImageProvider loadPhotoProvider(String mediaPath) {
  if (mediaPath.startsWith('data:')) {
    final commaIndex = mediaPath.indexOf(',');
    final b64 = mediaPath.substring(commaIndex + 1);
    final bytes = base64Decode(b64);
    return MemoryImage(Uint8List.fromList(bytes));
  } else if (kIsWeb) {
    return NetworkImage(mediaPath);
  } else if (mediaPath.startsWith('/') || mediaPath.contains(':\\')) {
    // Legacy absolute path — still supported
    return FileImage(File(mediaPath));
  } else {
    // Relative path — resolve using cached base path
    return FileImage(File(_resolveMediaPath(mediaPath)));
  }
}
