class ArtistModel {
  final String artistId;
  final String name;
  final String imageUrl;
  final String bio;
  final DateTime? createdAt;

  ArtistModel({
    required this.artistId,
    required this.name,
    this.imageUrl = '',
    this.bio = '',
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'artistId': artistId,
      'name': name,
      'imageUrl': imageUrl,
      'bio': bio,
      'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory ArtistModel.fromMap(Map<String, dynamic> map, String docId) {
    return ArtistModel(
      artistId: docId,
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      bio: map['bio'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) : null,
    );
  }
}
