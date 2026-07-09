import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:trplapp/dto/datas.dart';
import 'package:trplapp/endpoints/endpoints.dart';

class DataService {
  static Map<String, String> get _headers => {
        'apikey': Endpoints.supabaseAnonKey,
        'Authorization': 'Bearer ${Endpoints.supabaseAnonKey}',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

  static Future<List<Datas>> fetchDatas({http.Client? client}) async {
    final httpClient = client ?? http.Client();
    try {
      final url = Uri.parse(
          '${Endpoints.supabaseUrl}/rest/v1/presensi?select=*&order=created_at.desc');

      final response = await httpClient.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Datas.fromJson(item)).toList();
      } else {
        throw Exception(
            'Failed to load data: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load data: $e');
    }
  }

  static Future<Map<String, dynamic>?> login(String username, String password, {http.Client? client}) async {
    final httpClient = client ?? http.Client();
    try {
      final url = Uri.parse(
          '${Endpoints.supabaseUrl}/rest/v1/akun_karyawan?select=*&username=eq.$username&password=eq.$password');

      final response = await httpClient.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data.first as Map<String, dynamic>;
        } else {
          return null;
        }
      } else {
        throw Exception(
            'Failed to login: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  Future<dynamic> postGambarKamera(
    File foto,
    String nim, {
    String? judul,
    String? deskripsi,
    String? status,
    String? tanggal,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${foto.path.split(Platform.pathSeparator).last}';

      // 1. Upload to Supabase Storage via REST
      final uploadUrl = Uri.parse(
          '${Endpoints.supabaseUrl}/storage/v1/object/foto_presensi/$fileName');

      final bytes = await foto.readAsBytes();

      final uploadHeaders = {
        'apikey': Endpoints.supabaseAnonKey,
        'Authorization': 'Bearer ${Endpoints.supabaseAnonKey}',
        'Content-Type': 'application/octet-stream',
      };

      final uploadResponse = await httpClient.post(
        uploadUrl,
        headers: uploadHeaders,
        body: bytes,
      );

      if (uploadResponse.statusCode != 200 &&
          uploadResponse.statusCode != 201) {
        throw Exception(
            'Failed to upload image: ${uploadResponse.statusCode} - ${uploadResponse.body}');
      }

      // 2. Get public URL
      final imageUrl =
          '${Endpoints.supabaseUrl}/storage/v1/object/public/foto_presensi/$fileName';

      // 3. Insert to table via REST
      final insertUrl = Uri.parse('${Endpoints.supabaseUrl}/rest/v1/presensi');

      final bodyData = {
        'name': nim,
        'judul': judul,
        'deskripsi': deskripsi,
        'status': status,
        'image_url': imageUrl,
        if (tanggal != null) 'created_at': tanggal,
      };

      final insertResponse = await httpClient.post(
        insertUrl,
        headers: _headers,
        body: jsonEncode(bodyData),
      );

      if (insertResponse.statusCode == 201 ||
          insertResponse.statusCode == 200) {
        final List<dynamic> data = jsonDecode(insertResponse.body);
        return data; // Return the inserted data
      } else {
        throw Exception(
            'Failed to insert data: ${insertResponse.statusCode} - ${insertResponse.body}');
      }
    } catch (e) {
      throw Exception('Error uploading data: $e');
    }
  }
}
