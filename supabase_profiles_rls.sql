-- 1. Pastikan Row Level Security (RLS) aktif pada tabel profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 2. Hapus policy lama jika ada untuk menghindari bentrok
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow select for owners" ON public.profiles;
DROP POLICY IF EXISTS "Allow insert for owners" ON public.profiles;
DROP POLICY IF EXISTS "Allow update for owners" ON public.profiles;

-- 3. Policy untuk SELECT (Membaca data profil sendiri)
CREATE POLICY "Users can view their own profile" ON public.profiles
  FOR SELECT TO authenticated
  USING (auth.uid() = id);

-- Catatan: Jika aplikasi membutuhkan karyawan untuk melihat nama profil karyawan lain 
-- (misal di riwayat presensi umum), gunakan policy di bawah ini sebagai gantinya:
-- CREATE POLICY "Users can view all profiles" ON public.profiles
--   FOR SELECT TO authenticated
--   USING (true);

-- 4. Policy untuk INSERT (Menambahkan data profil sendiri)
-- Ini SANGAT PENTING untuk operasi UPSERT agar dapat membuat baris baru jika belum ada.
CREATE POLICY "Users can insert their own profile" ON public.profiles
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id);

-- 5. Policy untuk UPDATE (Memperbarui data profil sendiri)
-- Ini SANGAT PENTING untuk operasi UPSERT agar dapat memperbarui baris data yang sudah ada.
CREATE POLICY "Users can update their own profile" ON public.profiles
  FOR UPDATE TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);
