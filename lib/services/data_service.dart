import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trplapp/dto/datas.dart';

class DataService {
  static Future<List<Datas>> fetchDatas() async {
    try {
      final response = await Supabase.instance.client
          .from('presensi')
          .select()
          .order('created_at', ascending: false);
          
      return response.map((item) => Datas.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to load data: $e');
    }
  }

  Future<dynamic> postGambarKamera(File foto, String nim, {String? judul, String? deskripsi, String? status, String? tanggal}) async {
    try {
      final supabase = Supabase.instance.client;
      // Get filename from path
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${foto.path.split(Platform.pathSeparator).last}';
      
      // Upload to Supabase Storage
      await supabase.storage.from('foto_presensi').upload(fileName, foto);
      
      // Get public URL
      final imageUrl = supabase.storage.from('foto_presensi').getPublicUrl(fileName);
      
      // Insert to table
      final data = await supabase.from('presensi').insert({
        'name': nim,
        'judul': judul,
        'deskripsi': deskripsi,
        'status': status,
        'image_url': imageUrl,
        if (tanggal != null) 'created_at': tanggal,
      }).select();
      
      return data;
    } catch (e) {
      throw Exception('Error uploading data: $e');
    }
  }
}