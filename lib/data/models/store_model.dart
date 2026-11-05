/// Mô hình thông tin Cửa hàng LOWLAND Coffee
class StoreModel {
  final String id;
  final String name;
  final String address;
  final String hotline;
  final String openingHours;
  final String wifiName;
  final String wifiPassword;
  final double latitude;
  final double longitude;
  final String imageUrl;

  StoreModel({
    required this.id,
    required this.name,
    required this.address,
    required this.hotline,
    required this.openingHours,
    required this.wifiName,
    required this.wifiPassword,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'hotline': hotline,
      'openingHours': openingHours,
      'wifiName': wifiName,
      'wifiPassword': wifiPassword,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
    };
  }

  factory StoreModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return StoreModel(
      id: docId ?? map['id']?.toString() ?? 'store_flagship',
      name: map['name'] ?? 'LOWLAND Coffee - Đại Học FPT Cần Thơ',
      address: map['address'] ?? '600 Nguyễn Văn Cừ nối dài, Phường An Bình, Quận Ninh Kiều, TP. Cần Thơ',
      hotline: map['hotline'] ?? '1900 1755',
      openingHours: map['openingHours'] ?? '07:00 - 22:00 (Hàng ngày)',
      wifiName: map['wifiName'] ?? 'LOWLAND_Coffee_FPT_CanTho',
      wifiPassword: map['wifiPassword'] ?? 'lowlandcoffee2026',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 10.0132,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 105.7316,
      imageUrl: map['imageUrl'] ?? 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=800&q=80',
    );
  }
}

