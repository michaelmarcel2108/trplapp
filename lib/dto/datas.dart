class Datas {
  final int idDatas;
  final String name;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? judul;
  final String? deskripsi;
  final String? status;

  Datas({
    required this.idDatas,
    required this.name,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    this.judul,
    this.deskripsi,
    this.status,
  });

  factory Datas.fromJson(Map<String, dynamic> json) {
    return Datas(
      idDatas: (json['id'] ?? json['_id_datas'] ?? 0) as int,
      
      name: json['name'] as String? ?? 'No Name',
      imageUrl: json['image_url'] as String?,
      
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
          
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
          
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      judul: json['judul'] as String?,
      deskripsi: json['deskripsi'] as String?,
      status: json['status'] as String?,
    );
  }
}