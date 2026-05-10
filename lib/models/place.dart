class Place {
  final String placeId;
  final String name;
  final double lat;
  final double lng;
  final double? rating;
  final int? userRatingCount;
  final String? address;
  final List<PhotoInfo> photos;

  const Place({
    required this.placeId,
    required this.name,
    required this.lat,
    required this.lng,
    this.rating,
    this.userRatingCount,
    this.address,
    this.photos = const [],
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? {};
    final displayName = json['displayName'] as Map<String, dynamic>? ?? {};
    final photoList = (json['photos'] as List<dynamic>?)
            ?.map((p) => PhotoInfo.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];

    return Place(
      placeId: json['id'] as String? ?? '',
      name: displayName['text'] as String? ?? 'Unknown Place',
      lat: (location['latitude'] as num?)?.toDouble() ?? 0,
      lng: (location['longitude'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingCount: json['userRatingCount'] as int?,
      address: json['formattedAddress'] as String?,
      photos: photoList,
    );
  }
}

class PhotoInfo {
  final String name;
  final int? heightPx;
  final int? widthPx;

  const PhotoInfo({required this.name, this.heightPx, this.widthPx});

  factory PhotoInfo.fromJson(Map<String, dynamic> json) {
    return PhotoInfo(
      name: json['name'] as String? ?? '',
      heightPx: json['heightPx'] as int?,
      widthPx: json['widthPx'] as int?,
    );
  }
}
