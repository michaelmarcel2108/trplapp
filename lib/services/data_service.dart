import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:trplapp/dto/datas.dart';
import 'package:trplapp/endpoints/endpoints.dart';

class DataService {
  static Future<List<Datas>> fetchDatas() async {
    final response = await http.get(Uri.parse(Endpoints.datas));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      return (data['datas'] as List<dynamic>)
          .map((item) => Datas.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load data');
    }
  }

  // fungsi upload foto
 //fungsi upload foto
  //fungsi upload foto
  Future<dynamic> postGambarKamera(File foto, String nim) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(Endpoints.datas));
      
      request.headers.addAll({
        'Accept': 'application/json',
      });
      
      request.fields['name'] = nim;
      request.files.add(await http.MultipartFile.fromPath('image', foto.path));
      
      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);
      
      print("===== DEBUG MESSAGE =====");
      print("Status Code API: ${response.statusCode}");
      print("Response API: $responseString");
      print("=========================");
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(responseString);
      } else {
        throw Exception('Server merespons dengan kode ${response.statusCode}: $responseString');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }
}