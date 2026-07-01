import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:trplapp/services/data_service.dart';

class UploadFoto extends StatefulWidget {
  const UploadFoto({super.key});

  @override
  State<UploadFoto> createState() => _UploadFotoState();
}

class _UploadFotoState extends State<UploadFoto> {
  // variable inisialisation sesuai bawaan proyek
  // 1 FormController
  final _formKey = GlobalKey<FormState>();
  final _nimController = TextEditingController();
  // 2 Transaksional
  File? foto;
  String? fotoPath;
  bool isLoading = false;

  // Inisialisasi ImagePicker untuk akses kamera
  final ImagePicker _picker = ImagePicker();

  // Fungsi untuk meminta izin kamera dan mengambil foto
  Future<void> _ambilFoto() async {
    // 4. Gunakan permission-handler sebelum akses kamera
    var status = await Permission.camera.request();
    
    if (status.isGranted) {
      // Mengambil gambar dari kamera
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          foto = File(pickedFile.path);
          fotoPath = pickedFile.path;
        });
      }
    } else if (status.isDenied || status.isPermanentlyDenied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin akses kamera ditolak. Silakan aktifkan izin di pengaturan.')),
      );
    }
  }

  // Fungsi untuk mengirim data ke DataService
  Future<void> _submitData() async {
    if (_formKey.currentState!.validate()) {
      if (foto == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan ambil foto terlebih dahulu!')),
        );
        return;
      }

      setState(() {
        isLoading = true;
      });

      try {
        // Memanggil fungsi postGambarKamera dari DataService
        await DataService().postGambarKamera(foto!, _nimController.text);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data dan Foto berhasil diupload!')),
        );
        
        // Reset form setelah berhasil upload
        setState(() {
          foto = null;
          fotoPath = null;
          _nimController.clear();
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Foto Kamera'),
      ),
      // Jika proses loading sedang berjalan, tampilkan indikator loading
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. UI Form Input NIM
                    TextFormField(
                      controller: _nimController,
                      decoration: const InputDecoration(
                        labelText: 'Masukkan Nama Anda',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'NIM tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // 5. Memastikan gambar tampil sebelum di-submit jika foto sudah diambil
                    if (foto != null) ...[
                      const Text(
                        'Pratinjau Foto:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.file(
                          foto!,
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Tombol untuk memicu aksi kamera
                    ElevatedButton.icon(
                      onPressed: _ambilFoto,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(foto == null ? 'Buka Kamera' : 'Ambil Ulang Foto'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tombol Kirim/Submit ke API
                    ElevatedButton(
                      onPressed: _submitData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Submit Data',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}