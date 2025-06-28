import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/property_model.dart';

enum MapStatus { loading, error, success, permissionDenied, locationOnly }

enum MapMode { location, directions }

enum TileMode { street, satellite }

class InteractiveMapWidget extends StatefulWidget {
  final Property property;
  final double height;
  final EdgeInsets? padding;

  const InteractiveMapWidget({
    super.key,
    required this.property,
    this.height = 400,
    this.padding,
  });

  @override
  State<InteractiveMapWidget> createState() => _InteractiveMapWidgetState();
}

class _InteractiveMapWidgetState extends State<InteractiveMapWidget> {
  MapStatus _status = MapStatus.loading;
  MapMode _mapMode = MapMode.location;
  TileMode _tileMode = TileMode.street;
  LatLng? _userLocation;
  List<LatLng> _route = [];
  double? _distance;
  int? _duration;
  String _errorMessage = '';
  final MapController _mapController = MapController();

  LatLng get _destinationCoords {
    return LatLng(
      widget.property.latitude ?? 0.0,
      widget.property.longitude ?? 0.0,
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _status = MapStatus.locationOnly;
        });
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _status = MapStatus.permissionDenied;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _status = MapStatus.permissionDenied;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _status = MapStatus.locationOnly;
      });
    } catch (e) {
      setState(() {
        _status = MapStatus.locationOnly;
      });
    }
  }

  Future<void> _getDirections() async {
    if (_userLocation == null) {
      setState(() {
        _errorMessage = 'Your location is required to get directions.';
        _status = MapStatus.error;
      });
      return;
    }

    setState(() {
      _status = MapStatus.loading;
    });

    try {
      final userLat = _userLocation!.latitude;
      final userLng = _userLocation!.longitude;
      final destLat = _destinationCoords.latitude;
      final destLng = _destinationCoords.longitude;

      // Use OSRM routing service
      final url =
          'https://router.project-osrm.org/route/v1/driving/'
          '$userLng,$userLat;$destLng,$destLat?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'].isEmpty) {
          throw Exception('No route could be found.');
        }

        final routeData = data['routes'][0];
        final coordinates = routeData['geometry']['coordinates'] as List;

        setState(() {
          _route =
              coordinates
                  .map(
                    (coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()),
                  )
                  .toList();
          _distance = routeData['distance'].toDouble();
          _duration = routeData['duration'].toInt();
          _mapMode = MapMode.directions;
          _status = MapStatus.success;
        });

        // Fit bounds to show both locations
        _fitBounds();
      } else {
        throw Exception('Failed to get directions');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _status = MapStatus.error;
      });
    }
  }

  void _fitBounds() {
    if (_userLocation != null) {
      final bounds = LatLngBounds.fromPoints([
        _userLocation!,
        _destinationCoords,
      ]);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
      );
    }
  }

  void _openLargeMap() async {
    final lat = _destinationCoords.latitude;
    final lng = _destinationCoords.longitude;
    final googleMapsUrl = 'https://www.google.com/maps?q=$lat,$lng&z=15';

    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(
        Uri.parse(googleMapsUrl),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}min';
    return '${minutes}min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: widget.height,
      padding: widget.padding,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _buildMapContent(theme),
      ),
    );
  }

  Widget _buildMapContent(ThemeData theme) {
    switch (_status) {
      case MapStatus.loading:
        return _buildLoadingState(theme);
      case MapStatus.permissionDenied:
        return _buildPermissionDeniedState(theme);
      case MapStatus.error:
        return _buildErrorState(theme);
      case MapStatus.locationOnly:
      case MapStatus.success:
        return _buildMapView(theme);
    }
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Loading map...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedState(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Location Permission Required',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please enable location access to see directions to this property.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await openAppSettings();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Route Error',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _initializeLocation,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView(ThemeData theme) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _userLocation ?? _destinationCoords,
            initialZoom: _status == MapStatus.success ? 13.0 : 15.0,
            minZoom: 3.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  _tileMode == TileMode.satellite
                      ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.test_app',
              maxZoom: 18,
            ),
            MarkerLayer(markers: _buildMarkers()),
            if (_route.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _route,
                    strokeWidth: 4.0,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
          ],
        ),
        _buildControlButtons(theme),
        if (_status == MapStatus.success &&
            _distance != null &&
            _duration != null)
          _buildRouteInfo(theme),
        if (_status == MapStatus.locationOnly) _buildLocationInfo(theme),
      ],
    );
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [
      Marker(
        point: _destinationCoords,
        width: 40,
        height: 40,
        child: Icon(Icons.location_on, size: 40, color: Colors.red),
      ),
    ];

    if (_userLocation != null) {
      markers.add(
        Marker(
          point: _userLocation!,
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.my_location, size: 16, color: Colors.white),
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildControlButtons(ThemeData theme) {
    return Positioned(
      top: 12,
      right: 12,
      child: Column(
        children: [
          // Satellite toggle
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _tileMode =
                      _tileMode == TileMode.street
                          ? TileMode.satellite
                          : TileMode.street;
                });
              },
              icon: Icon(
                _tileMode == TileMode.street ? Icons.satellite : Icons.map,
                color: theme.colorScheme.primary,
              ),
              tooltip:
                  _tileMode == TileMode.street
                      ? 'Satellite View'
                      : 'Street View',
            ),
          ),
          const SizedBox(height: 8),
          // Directions button
          if (_userLocation != null && _status != MapStatus.success)
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _getDirections,
                icon: const Icon(Icons.directions, color: Colors.white),
                tooltip: 'Get Directions',
              ),
            ),
          const SizedBox(height: 8),
          // External map button
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _openLargeMap,
              icon: Icon(Icons.open_in_new, color: theme.colorScheme.primary),
              tooltip: 'Open in Google Maps',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo(ThemeData theme) {
    return Positioned(
      top: 12,
      left: 12,
      right: 80,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.route, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              '${(_distance! / 1000).toStringAsFixed(1)} km',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            Icon(Icons.access_time, size: 16, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              _formatDuration(_duration!),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo(ThemeData theme) {
    return Positioned(
      bottom: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Property Location',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
