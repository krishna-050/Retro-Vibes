class PlaylistModel {
  final String playlistId;
  final String name;
  final String ownerId;
  final String coverUrl;
  final List<String> songIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PlaylistModel({
    required this.playlistId,
    required this.name,
    required this.ownerId,
    this.coverUrl = '',
    this.songIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'playlistId': playlistId,
      'name': name,
      'ownerId': ownerId,
      'coverUrl': coverUrl,
      'songIds': songIds,
      'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory PlaylistModel.fromMap(Map<String, dynamic> map, String docId) {
    return PlaylistModel(
      playlistId: docId,
      name: map['name'] ?? '',
      ownerId: map['ownerId'] ?? '',
      coverUrl: map['coverUrl'] ?? '',
      songIds: List<String>.from(map['songIds'] ?? []),
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) : null,
    );
  }
}
