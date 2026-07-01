import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 60, color: Colors.indigo[300]),
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

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
