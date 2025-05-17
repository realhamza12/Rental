import 'dart:convert';
import 'dart:typed_data'; // Add this
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

Future<String?> uploadImageToCloudinary(XFile imageFile) async {
  const cloudName = 'dzuc4aors'; // your Cloudinary cloud name
  const uploadPreset = 'rental_upload'; // your unsigned preset

  final url = Uri.parse(
    'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
  );

  // ✅ Read as bytes (works on Web)
  Uint8List imageBytes = await imageFile.readAsBytes();

  final request =
      http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: imageFile.name,
          ),
        );

  final response = await request.send();

  if (response.statusCode == 200) {
    final res = await http.Response.fromStream(response);
    final data = json.decode(res.body);
    return data['secure_url'];
  } else {
    print('❌ Failed to upload: ${response.statusCode}');
    return null;
  }
}
