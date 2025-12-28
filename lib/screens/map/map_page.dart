import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final PageController _pageController = PageController();
  late MapboxMap mapboxMap;
  PointAnnotationManager? pointAnnotationManager;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    final logger = getIt<LoggingService>();
    this.mapboxMap = mapboxMap;

    await mapboxMap.gestures.updateSettings(
      GesturesSettings(
        scrollEnabled: true,
        rotateEnabled: true,
        pitchEnabled: false,
      ),
    );

    pointAnnotationManager = await mapboxMap.annotations
        .createPointAnnotationManager();

    // Load the image from assets

    final bytes = await rootBundle.load('assets/map/location.png');
    logger.debug('Image loaded with ${bytes.lengthInBytes} bytes');
    final imageData = bytes.buffer.asUint8List();

    // Create a PointAnnotationOptions

    final pointAnnotationOptions = PointAnnotationOptions(
      geometry: Point(
        coordinates: Position(40.985496058, 29.035333192),
      ), // Example coordinates

      image: imageData,

      iconSize: 1,
    );

    // Add the annotation to the map

    await pointAnnotationManager?.create(pointAnnotationOptions);
  }

  @override
  Widget build(BuildContext context) {
    final camera = CameraOptions(
      center: Point(coordinates: Position(40.985496058, 29.035333192)),
      zoom: 5,
      bearing: 0,
      pitch: 0,
    );

    return Scaffold(
      body: MapWidget(
        cameraOptions: camera,
        onMapCreated: _onMapCreated,
        styleUri: MapboxStyles.MAPBOX_STREETS,
      ),
    );
  }
}
