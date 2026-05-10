import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/place.dart';

class PlacesService {
  static const _baseUrl = 'https://places.googleapis.com/v1/places';

  static String get _apiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  static const _fieldMask =
      'places.id,places.displayName,places.location,places.rating,'
      'places.userRatingCount,places.formattedAddress,places.photos';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask': _fieldMask,
      };

  Future<List<Place>> searchNearby({
    required double lat,
    required double lng,
    required double radiusMeters,
  }) =>
      _textSearch(
        query: 'food and drink',
        lat: lat,
        lng: lng,
        radiusMeters: radiusMeters,
      );

  Future<List<Place>> searchText({
    required String query,
    required double lat,
    required double lng,
    required double radiusMeters,
  }) =>
      _textSearch(
        query: query,
        lat: lat,
        lng: lng,
        radiusMeters: radiusMeters,
      );

  Future<List<Place>> _textSearch({
    required String query,
    required double lat,
    required double lng,
    required double radiusMeters,
  }) async {
    final url = Uri.parse('$_baseUrl:searchText');
    final body = jsonEncode({
      'textQuery': query,
      'maxResultCount': 20,
      'locationBias': {
        'circle': {
          'center': {'latitude': lat, 'longitude': lng},
          'radius': radiusMeters,
        },
      },
    });

    final response = await http.post(url, headers: _headers, body: body);
    return _parsePlaces(response);
  }

  List<Place> _parsePlaces(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception('Places API error ${response.statusCode}: ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final places = data['places'] as List<dynamic>? ?? [];
    return places.map((p) => Place.fromJson(p as Map<String, dynamic>)).toList();
  }

  String getPhotoUrl(String photoName, {int maxHeightPx = 500}) {
    return 'https://places.googleapis.com/v1/$photoName/media'
        '?maxHeightPx=$maxHeightPx'
        '&key=$_apiKey';
  }
}
