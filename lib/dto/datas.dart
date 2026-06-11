class Datas {
  final int idDatas;
  final String name;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Datas({
    required this.idDatas,
    required this.name,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  factory Datas.fromJson(Map<String, dynamic> json) {
    return Datas(
      idDatas: json['_id_datas'] != null ? json['_id_datas'] as int : 0,
      
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
    );
  }
}