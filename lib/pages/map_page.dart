import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/place.dart';
import '../services/location_service.dart';
import '../services/places_service.dart';
import '../widgets/place_info_card.dart';
import '../widgets/search_controls.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with SingleTickerProviderStateMixin {
  final _placesService = PlacesService();
  GoogleMapController? _mapController;

  // Default to NYC until geolocation resolves
  LatLng _center = const LatLng(40.7128, -74.0060);
  LatLng? _userLocation;

  Set<Marker> _markers = {};
  Place? _selectedPlace;

  double _radiusMiles = 1.0;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  Timer? _debounce;
  late AnimationController _cardController;
  late Animation<Offset> _cardSlide;

  static const _defaultZoom = 14.0;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic));

    _initLocation();
  }

  Future<void> _initLocation() async {
    final loc = await LocationService.getCurrentLocation();
    if (!mounted) return;
    if (loc != null) {
      setState(() {
        _userLocation = loc;
        _center = loc;
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(loc, _defaultZoom),
      );
    }
    _fetchPlaces();
  }

  double get _radiusMeters => _radiusMiles * 1609.34;

  Future<void> _fetchPlaces() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final center = _userLocation ?? _center;
      final places = _searchQuery.trim().isEmpty
          ? await _placesService.searchNearby(
              lat: center.latitude,
              lng: center.longitude,
              radiusMeters: _radiusMeters,
            )
          : await _placesService.searchText(
              query: _searchQuery.trim(),
              lat: center.latitude,
              lng: center.longitude,
              radiusMeters: _radiusMeters,
            );

      if (!mounted) return;
      _applyPlaces(places);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyPlaces(List<Place> places) {
    final markers = places.map((p) {
      return Marker(
        markerId: MarkerId(p.placeId),
        position: LatLng(p.lat, p.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        onTap: () => _selectPlace(p),
      );
    }).toSet();

    setState(() {
      _markers = markers;
      _selectedPlace = null;
    });
    _cardController.reverse();
  }

  void _selectPlace(Place place) {
    setState(() => _selectedPlace = place);
    _cardController.forward(from: 0);
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(place.lat, place.lng)),
    );
  }

  void _dismissCard() {
    _cardController.reverse().then((_) {
      if (mounted) setState(() => _selectedPlace = null);
    });
  }

  void _onSearch(String query) {
    _debounce?.cancel();
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _fetchPlaces();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 600), _fetchPlaces);
  }

  void _onRadiusChanged(double miles) {
    setState(() => _radiusMiles = miles);
    _fetchPlaces();
  }

  void _goToMyLocation() {
    if (_userLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation!, _defaultZoom),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cardController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          GoogleMap(
            onMapCreated: (c) {
              _mapController = c;
              if (_userLocation != null) {
                c.animateCamera(
                  CameraUpdate.newLatLngZoom(_userLocation!, _defaultZoom),
                );
              }
            },
            initialCameraPosition: CameraPosition(target: _center, zoom: _defaultZoom),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onTap: (_) => _dismissCard(),
          ),

          // ── Search controls ───────────────────────────────────────────────
          Positioned(
            top: topPad + 10,
            left: 12,
            right: 12,
            child: SearchControls(
              onSearch: _onSearch,
              onRadiusChanged: _onRadiusChanged,
              radiusMiles: _radiusMiles,
              isLoading: _isLoading,
            ),
          ),

          // ── Error banner ──────────────────────────────────────────────────
          if (_errorMessage != null)
            Positioned(
              top: topPad + 76,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD93025),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // ── Custom zoom + location buttons ────────────────────────────────
          Positioned(
            right: 12,
            bottom: _selectedPlace != null ? 300 : 40,
            child: Column(
              children: [
                _MapButton(
                  icon: Icons.add,
                  onTap: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                ),
                const SizedBox(height: 6),
                _MapButton(
                  icon: Icons.remove,
                  onTap: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                ),
                const SizedBox(height: 10),
                _MapButton(
                  icon: Icons.my_location,
                  onTap: _goToMyLocation,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),

          // ── Place info card ───────────────────────────────────────────────
          if (_selectedPlace != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _cardSlide,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    child: PlaceInfoCard(
                      place: _selectedPlace!,
                      photoUrl: _selectedPlace!.photos.isNotEmpty
                          ? _placesService.getPhotoUrl(
                              _selectedPlace!.photos.first.name,
                            )
                          : null,
                      onClose: _dismissCard,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _MapButton({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 22, color: color ?? Colors.grey[800]),
        ),
      ),
    );
  }
}
