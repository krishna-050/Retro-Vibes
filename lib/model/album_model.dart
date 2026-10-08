class AlbumModel {
  final String albumId;
  final String title;
  final String artistId;
  final String coverUrl;
  final String releaseYear;
  final String genre;

  AlbumModel({
    required this.albumId,
    required this.title,
    required this.artistId,
    this.coverUrl = '',
    this.releaseYear = '2024',
    this.genre = 'Retro',
  });

  Map<String, dynamic> toMap() {
    return {
      'albumId': albumId,
      'title': title,
      'artistId': artistId,
      'coverUrl': coverUrl,
      'releaseYear': releaseYear,
      'genre': genre,
    };
  }

  factory AlbumModel.fromMap(Map<String, dynamic> map, String docId) {
    return AlbumModel(
      albumId: docId,
      title: map['title'] ?? '',
      artistId: map['artistId'] ?? '',
      coverUrl: map['coverUrl'] ?? '',
      releaseYear: map['releaseYear']?.toString() ?? '2024',
      genre: map['genre'] ?? 'Retro',
    );
  }
}
