import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  final String cloudName = "dhycdzz73";

  // Define your two specific presets here
  final String imagePreset = "Image_Upload";
  final String videoPreset = "Video_Upload";

  Future<String?> uploadMedia(File file, String resourceType) async {
    // 1. Determine the correct URL and Preset based on type
    final String preset = (resourceType == "video") ? videoPreset : imagePreset;
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = preset // Dynamically pick the preset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    try {
      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = utf8.decode(responseData);
      final jsonResponse = jsonDecode(responseString);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonResponse['secure_url'];
      } else {
        print("Cloudinary Error: ${jsonResponse['error']?['message'] ?? 'Unknown Error'}");
        return null;
      }
    } catch (e) {
      print("Upload failed: $e");
      return null;
    }
  }
}