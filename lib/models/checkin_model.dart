class CheckinUser {
  final int id;
  final String name;
  final String? profileImage;

  CheckinUser({
    required this.id,
    required this.name,
    this.profileImage,
  });

  factory CheckinUser.fromJson(Map<String, dynamic> json) {
    return CheckinUser(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      profileImage: json['profileImage']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profileImage': profileImage,
    };
  }
}

class CheckinModel {
  final int id;
  final int? userId;
  final double lat;
  final double lng;
  final String locationName;
  final String? address;
  final double? accuracy;
  final String? description;
  final String? imageUrl;
  final DateTime? createdAt;
  final CheckinUser? user;

  CheckinModel({
    required this.id,
    this.userId,
    required this.lat,
    required this.lng,
    required this.locationName,
    this.address,
    this.accuracy,
    this.description,
    this.imageUrl,
    this.createdAt,
    this.user,
  });

  factory CheckinModel.fromJson(Map<String, dynamic> json) {
    return CheckinModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['userId'] is int
          ? json['userId'] as int
          : int.tryParse(json['userId']?.toString() ?? ''),
      lat: (json['lat'] is num)
          ? (json['lat'] as num).toDouble()
          : (json['latitude'] is num)
              ? (json['latitude'] as num).toDouble()
              : double.tryParse(json['lat']?.toString() ?? json['latitude']?.toString() ?? '0.0') ?? 0.0,
      lng: (json['lng'] is num)
          ? (json['lng'] as num).toDouble()
          : (json['longitude'] is num)
              ? (json['longitude'] as num).toDouble()
              : double.tryParse(json['lng']?.toString() ?? json['longitude']?.toString() ?? '0.0') ?? 0.0,
      locationName: json['locationName']?.toString() ?? 'Unknown Place',
      address: json['address']?.toString(),
      accuracy: (json['accuracy'] is num)
          ? (json['accuracy'] as num).toDouble()
          : double.tryParse(json['accuracy']?.toString() ?? ''),
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      user: json['user'] is Map<String, dynamic>
          ? CheckinUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'userId': userId,
      'lat': lat,
      'lng': lng,
      'locationName': locationName,
      'address': address,
      'accuracy': accuracy,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': createdAt?.toIso8601String(),
      if (user != null) 'user': user!.toJson(),
    };
  }
}
