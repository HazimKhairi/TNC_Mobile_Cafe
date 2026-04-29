import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const _cloudName = 'dfy0rpjdv';
  static const _apiKey = '655824831933762';
  static const _apiSecret = 'FRwZqGvVhIeM2I6CdSrutsGbLiQ';
  static const _menuFolder = 'tnc_cafe_menu';
  static const _receiptFolder = 'tnc_cafe_receipts';

  /// Uploads an image file to Cloudinary and returns the optimised URL.
  Future<String> uploadImage(File imageFile) =>
      _upload(imageFile, folder: _menuFolder, resourceType: 'image');

  /// Uploads a payment receipt (image or PDF) and returns the secure URL.
  /// PDFs use `resource_type=raw` so they are served as-is.
  Future<String> uploadReceipt(File file, {required bool isPdf}) =>
      _upload(file, folder: _receiptFolder, resourceType: isPdf ? 'raw' : 'image');

  Future<String> _upload(
    File file, {
    required String folder,
    required String resourceType,
  }) async {
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

    // Build the string-to-sign (params in alphabetical order)
    final toSign = 'folder=$folder&timestamp=$timestamp$_apiSecret';
    final signature = sha1.convert(utf8.encode(toSign)).toString();

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['api_key'] = _apiKey
      ..fields['timestamp'] = timestamp
      ..fields['signature'] = signature
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error']?['message'] ?? 'Upload failed');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = data['secure_url'] as String;

    // Image transform optimisation (skip for raw / PDF)
    if (resourceType == 'image') {
      return secureUrl.replaceFirst('/upload/', '/upload/f_auto,q_auto/');
    }
    return secureUrl;
  }
}
