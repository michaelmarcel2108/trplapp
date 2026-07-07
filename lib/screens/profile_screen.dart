import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = true;
  int? _localProfileId;
  String? _profileImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Coba ambil ID profil dari penyimpanan lokal
    _localProfileId = prefs.getInt('profile_id');
    
    // Ambil data dasar dari shared_prefs sebagai cadangan sementara (optimistic loading)
    _nameController.text = prefs.getString('emp_name') ?? '';
    _positionController.text = prefs.getString('emp_position') ?? '';
    _phoneController.text = prefs.getString('emp_phone') ?? '';
    _profileImagePath = prefs.getString('emp_image_path');

    // Jika punya ID, coba sinkronkan data terbaru dari Supabase
    if (_localProfileId != null) {
      try {
        final data = await Supabase.instance.client
            .from('profil_karyawan')
            .select()
            .eq('id', _localProfileId!)
            .maybeSingle();

        if (data != null) {
          setState(() {
            _nameController.text = data['nama_lengkap'] ?? '';
            _positionController.text = data['jabatan'] ?? '';
            _phoneController.text = data['no_telepon'] ?? '';
            
            // Perbarui cache lokal juga
            prefs.setString('emp_name', _nameController.text);
            prefs.setString('emp_position', _positionController.text);
            prefs.setString('emp_phone', _phoneController.text);
          });
        }
      } catch (e) {
        debugPrint('Gagal memuat profil dari Supabase: $e');
      }
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus(); // dismiss keyboard
    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final prefs = await SharedPreferences.getInstance();
      
      final profileData = {
        'nama_lengkap': _nameController.text,
        'jabatan': _positionController.text,
        'no_telepon': _phoneController.text,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (_localProfileId == null) {
        // Belum punya ID, berarti buat baru (Insert)
        final response = await supabase
            .from('profil_karyawan')
            .insert(profileData)
            .select()
            .single();
            
        // Simpan ID yang baru dibuat ke memori lokal HP
        _localProfileId = response['id'] as int;
        await prefs.setInt('profile_id', _localProfileId!);
      } else {
        // Sudah punya ID, berarti update data yang ada
        await supabase
            .from('profil_karyawan')
            .update(profileData)
            .eq('id', _localProfileId!);
      }
      
      // Tetap simpan ke shared_prefs agar sapaan di Home cepat muncul
      await prefs.setString('emp_name', _nameController.text);
      await prefs.setString('emp_position', _positionController.text);
      await prefs.setString('emp_phone', _phoneController.text);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil disimpan ke Cloud!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan profil: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 40, bottom: 30),
              decoration: BoxDecoration(
                color: Colors.indigo[800],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: _showImagePickerModal,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: _profileImagePath != null ? FileImage(File(_profileImagePath!)) : null,
                          child: _profileImagePath == null 
                              ? Icon(Icons.person, size: 60, color: Colors.indigo[300]) 
                              : null,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showImagePickerModal,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.indigo[800]!, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Profil Karyawan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Informasi Pribadi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nama Lengkap',
                          prefixIcon: const Icon(Icons.badge),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _positionController,
                        decoration: InputDecoration(
                          labelText: 'Jabatan (Position)',
                          prefixIcon: const Icon(Icons.work),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Nomor Telepon',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading 
                          ? const SizedBox(
                              height: 20, 
                              width: 20, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            )
                          : const Text(
                              'Simpan Profil',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('emp_image_path', pickedFile.path);
        setState(() {
          _profileImagePath = pickedFile.path;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diubah secara lokal.')),
        );
      }
    } catch (e) {
      debugPrint("Gagal mengambil foto: $e");
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Ubah Foto Profil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
