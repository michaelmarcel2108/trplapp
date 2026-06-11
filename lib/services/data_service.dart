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
  //fungsi upload foto
  Future<dynamic> postGambarKamera(File foto, String nim) async{
    
  }
}