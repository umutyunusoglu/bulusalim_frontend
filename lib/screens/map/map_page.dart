import 'dart:async'; // Timer için gerekli
import 'dart:math';
import 'dart:ui' as ui;

import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/components/event_card.dart';
import 'package:bulusalim/components/map_create_button.dart';
import 'package:bulusalim/components/map_filter_chip.dart';
import 'package:bulusalim/core/utils/debug/android_image_url_fixer.dart';
import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/domain/repositories/map_repository.dart';
import 'package:bulusalim/domain/services/remote_config_service.dart'; // EKLENDİ
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final PageController _pageController = PageController();
  final LoggingService _logger = getIt<LoggingService>();

  final MapRepository _mapRepository = getIt<MapRepository>();

  // --- REMOTE CONFIG STATE (YENİ) ---
  Map<String, String> _categories = {};
  bool _isLoadingConfig = true;
  String _selectedCategory = "Hepsi";

  Cancelable? _clickListener;
  EventEntity? _selectedEvent;
  bool _isCardVisible = false;
  late MapboxMap mapboxMap;
  PointAnnotationManager? pointAnnotationManager;

  final Map<String, EventEntity> _markerEventMap = {};
  final Set<String> _loadedEventIds = {};

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Filtreleri Çek (YENİ)
    _fetchMapConfig();
  }

  // --- REMOTE CONFIG FETCH (YENİ) ---
  Future<void> _fetchMapConfig() async {
    try {
      final remoteService = getIt<RemoteConfigService>();
      final rawMap = await remoteService.getValue<Map>('map_filters');

      if (mounted) {
        setState(() {
          _categories = Map<String, String>.from(rawMap);
          _isLoadingConfig = false;
        });
      }
    } catch (e) {
      _logger.error("Map filters fetch error: $e");
      if (mounted) setState(() => _isLoadingConfig = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _clickListener?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _addMapProfileMarker(EventEntity event) async {
    if (_loadedEventIds.contains(event.id)) return;

    var url = event.creator.profileImageUrl;
    final customMarkerIcon = await _generateCustomMarkerImage(url, scale: 1.5);
    if (customMarkerIcon == null) return;

    final pointAnnotationOptions = PointAnnotationOptions(
      geometry: Point(
        coordinates: Position(
          event.location.longitude,
          event.location.latitude,
        ),
      ),
      image: customMarkerIcon,
      iconSize: 0.6,
    );

    if (pointAnnotationManager != null) {
      final annotation = await pointAnnotationManager!.create(
        pointAnnotationOptions,
      );

      _markerEventMap[annotation.id] = event;
      _loadedEventIds.add(event.id);
    }
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;

    await mapboxMap.gestures.updateSettings(
      GesturesSettings(
        scrollEnabled: true,
        rotateEnabled: true,
        pitchEnabled: false,
      ),
    );

    await mapboxMap.style.setStyleLayerProperty(
      'poi-label',
      'visibility',
      'none',
    );

    pointAnnotationManager = await mapboxMap.annotations
        .createPointAnnotationManager();

    _clickListener = pointAnnotationManager?.tapEvents(
      onTap: (PointAnnotation annotation) {
        final event = _markerEventMap[annotation.id];
        if (event != null) {
          setState(() {
            _selectedEvent = event;
            _isCardVisible = true;
          });
          _flyToEvent(event);
        }
      },
    );
  }

  void _onCameraChangeListener(CameraChangedEventData event) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchVisibleEvents();
    });
  }

  Future<void> _fetchVisibleEvents() async {
    try {
      final cameraState = await mapboxMap.getCameraState();
      final bounds = await mapboxMap.coordinateBoundsForCamera(
        CameraOptions(
          center: cameraState.center,
          zoom: cameraState.zoom,
          pitch: cameraState.pitch,
          bearing: cameraState.bearing,
        ),
      );

      const precision = 7;
      final events = await _mapRepository.fetchEventsInBounds(
        bounds: bounds,
        precision: precision,
      );

      for (final event in events) {
        await _addMapProfileMarker(event);
      }
    } catch (e) {
      _logger.error('Error fetching visible events: $e');
    }
  }

  void _flyToEvent(EventEntity event) {
    mapboxMap.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(
            event.location.longitude,
            event.location.latitude,
          ),
        ),
        padding: MbxEdgeInsets(
          top: 0,
          left: 0,
          bottom: 50.h,
          right: 0,
        ),
      ),
      MapAnimationOptions(duration: 1200),
    );
  }

  void _onMapBackgroundClick(MapContentGestureContext context) {
    if (_isCardVisible) {
      setState(() {
        _isCardVisible = false;
      });
    }
  }

  Future<Uint8List?> _generateCustomMarkerImage(
    String imageUrl, {
    double scale = 1.0,
  }) async {
    try {
      final colorPair = kMarkerPalette[Random().nextInt(kMarkerPalette.length)];

      final response = await http.get(Uri.parse(fixEmulatorUrl(imageUrl)));
      if (response.statusCode != 200) return null;

      final codec = await ui.instantiateImageCodec(response.bodyBytes);
      final fi = await codec.getNextFrame();
      final profileImage = fi.image;

      const baseOuterRadius = 60.0;
      const baseRingRadius = 46.0;
      const baseImageRadius = 37.0;
      const baseCanvasSize = 140.0;

      final double outerRadius = baseOuterRadius * scale;
      final double ringRadius = baseRingRadius * scale;
      final double imageRadius = baseImageRadius * scale;
      final double canvasSize = baseCanvasSize * scale;

      final double center = canvasSize / 2;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..isAntiAlias = true;

      final shadowPath = Path()
        ..addOval(
          Rect.fromCircle(
            center: Offset(center, center + (2 * scale)),
            radius: outerRadius,
          ),
        );
      canvas.drawShadow(shadowPath, Colors.black, 3.0 * scale, true);

      paint.color = colorPair.outer;
      canvas.drawCircle(Offset(center, center), outerRadius, paint);

      paint.color = colorPair.inner;
      canvas.drawCircle(Offset(center, center), ringRadius, paint);

      final imagePath = Path()
        ..addOval(
          Rect.fromCircle(
            center: Offset(center, center),
            radius: imageRadius,
          ),
        );
      canvas.clipPath(imagePath);

      paint.filterQuality = FilterQuality.high;

      final srcW = profileImage.width.toDouble();
      final srcH = profileImage.height.toDouble();
      final dstSize = imageRadius * 2;

      canvas.drawImageRect(
        profileImage,
        Rect.fromLTWH(0, 0, srcW, srcH),
        Rect.fromLTWH(
          center - imageRadius,
          center - imageRadius,
          dstSize,
          dstSize,
        ),
        Paint(),
      );

      final markerImage = await recorder.endRecording().toImage(
        canvasSize.toInt(),
        canvasSize.toInt(),
      );
      final byteData = await markerImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final camera = CameraOptions(
      center: Point(coordinates: Position(29.0254, 40.9819)),
      zoom: 17, // Biraz daha zoom out başlatabilirsin
      bearing: 0,
      pitch: 0,
    );

    return Scaffold(
      body: Stack(
        children: [
          // 1. ZEMİN: HARİTA
          MapWidget(
            cameraOptions: camera,
            onMapCreated: _onMapCreated,
            styleUri: MapboxStyles.MAPBOX_STREETS,
            onTapListener: _onMapBackgroundClick,
            onCameraChangeListener: _onCameraChangeListener,
          ),

          // 2. KATMAN: FİLTRE BAR (YENİ)
          Positioned(
            top: 116.h,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 40.h,
              child: _isLoadingConfig
                  ? const Center(child: CircularProgressIndicator.adaptive())
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(width: 10.w),
                      itemBuilder: (context, index) {
                        final key = _categories.keys.elementAt(index);
                        final value = _categories[key] ?? '';
                        final isSelected = _selectedCategory == key;

                        return Center(
                          child: MapFilterChip(
                            label: key,
                            emoji: value,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedCategory = "Hepsi";
                                } else {
                                  _selectedCategory = key;
                                }
                              });
                              // Filtreleme logic'i buraya eklenebilir
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),

          // 3. KATMAN: ETKİNLİK KARTI (ANIMATED)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            bottom: _isCardVisible ? 0 : -400.h,
            left: 0,
            right: 0,
            child: _selectedEvent != null
                ? EventCard(
                    event: _selectedEvent!,
                    participants: _selectedEvent!.participants,
                  )
                : const SizedBox.shrink(),
          ),

          // 4. KATMAN: TURUNCU BUTON (YENİ)
          Positioned(
            top: 668.h,
            left: 310.w,
            child: MapCreateButton(
              onTap: () {
                debugPrint("Etkinlik Oluştur Tıklandı");
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MarkerColorPair {
  final Color outer;
  final Color inner;
  const MarkerColorPair({required this.outer, required this.inner});
}

const List<MarkerColorPair> kMarkerPalette = [
  MarkerColorPair(outer: Color(0xFFC6D0D9), inner: Color(0xFF5B7A98)),
  MarkerColorPair(outer: Color(0xFFFFCCBC), inner: Color(0xFFFF7043)),
  MarkerColorPair(outer: Color(0xFFC8E6C9), inner: Color(0xFF66BB6A)),
  MarkerColorPair(outer: Color(0xFFFFF9C4), inner: Color(0xFFFDD835)),
  MarkerColorPair(outer: Color(0xFFE1BEE7), inner: Color(0xFFAB47BC)),
];
// import 'dart:async'; // Timer için gerekli
// import 'dart:math';
// import 'dart:ui' as ui;

// import 'package:bulusalim/application/providers/get_it_init.dart';
// import 'package:bulusalim/components/event_card.dart';
// import 'package:bulusalim/core/utils/debug/android_image_url_fixer.dart';
// import 'package:bulusalim/core/utils/logging/logging_service.dart';
// import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
// import 'package:bulusalim/domain/repositories/map_repository.dart'; // EventRepo yerine MapRepo
// import 'package:bulusalim/screens/map/map_profile_marker.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:http/http.dart' as http;
// import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

// class MapPage extends StatefulWidget {
//   const MapPage({super.key});

//   @override
//   State<MapPage> createState() => _MapPageState();
// }

// class _MapPageState extends State<MapPage> {
//   final PageController _pageController = PageController();
//   final LoggingService _logger = getIt<LoggingService>();

//   // 1. MapRepository'yi çağırıyoruz
//   final MapRepository _mapRepository = getIt<MapRepository>();

//   Cancelable? _clickListener;
//   EventEntity? _selectedEvent;
//   bool _isCardVisible = false;
//   late MapboxMap mapboxMap;
//   PointAnnotationManager? pointAnnotationManager;

//   // Haritada şu an yüklü olan markerlar (Tekrar yüklememek için)
//   final Map<String, EventEntity> _markerEventMap = {}; // AnnotationID -> Event
//   final Set<String> _loadedEventIds = {}; // EventID -> Exists Check

//   // Debounce için Timer (Kaydırma bitince istek atmak için)
//   Timer? _debounceTimer;

//   @override
//   void dispose() {
//     _pageController.dispose();
//     _clickListener?.cancel();
//     _debounceTimer?.cancel(); // Timer'ı temizle
//     super.dispose();
//   }

//   Future<void> _addMapProfileMarker(EventEntity event) async {
//     // Eğer bu event zaten haritada varsa tekrar çizme (Performans)
//     if (_loadedEventIds.contains(event.id)) return;

//     var url = event.creator.profileImageUrl;

//     // 1. Marker Resmini Oluştur
//     final customMarkerIcon = await _generateCustomMarkerImage(url, scale: 1.5);
//     if (customMarkerIcon == null) return;

//     // 2. Mapbox Options
//     final pointAnnotationOptions = PointAnnotationOptions(
//       geometry: Point(
//         coordinates: Position(
//           event.location.longitude,
//           event.location.latitude,
//         ),
//       ),
//       image: customMarkerIcon,
//       iconSize: 0.6,
//     );

//     // 3. Ekle ve Kaydet
//     if (pointAnnotationManager != null) {
//       final annotation = await pointAnnotationManager!.create(
//         pointAnnotationOptions,
//       );

//       _markerEventMap[annotation.id] = event; // Tıklama için
//       _loadedEventIds.add(event.id); // Duplicate kontrolü için
//     }
//   }

//   Future<void> _onMapCreated(MapboxMap mapboxMap) async {
//     this.mapboxMap = mapboxMap;

//     await mapboxMap.gestures.updateSettings(
//       GesturesSettings(
//         scrollEnabled: true,
//         rotateEnabled: true,
//         pitchEnabled: false,
//       ),
//     );

//     // POI (İşletme isimleri vs) kapat
//     await mapboxMap.style.setStyleLayerProperty(
//       'poi-label',
//       'visibility',
//       'none',
//     );

//     pointAnnotationManager = await mapboxMap.annotations
//         .createPointAnnotationManager();

//     // Tıklama Listener
//     _clickListener = pointAnnotationManager?.tapEvents(
//       onTap: (PointAnnotation annotation) {
//         final event = _markerEventMap[annotation.id];
//         if (event != null) {
//           setState(() {
//             _selectedEvent = event;
//             _isCardVisible = true;
//           });
//           _flyToEvent(event);
//         }
//       },
//     );
//   }

//   void _onCameraChangeListener(CameraChangedEventData event) {
//     // Timer varsa iptal et (Debounce)
//     _debounceTimer?.cancel();

//     // 300ms boyunca yeni hareket olmazsa fetch yap
//     _debounceTimer = Timer(const Duration(milliseconds: 300), () {
//       _fetchVisibleEvents();
//     });
//   }

//   Future<void> _fetchVisibleEvents() async {
//     try {
//       // 1. Önce kameranın durumunu al (Zoom, Merkez vs.)
//       final cameraState = await mapboxMap.getCameraState();

//       // 2. Bu kamera açısına göre "Görünen Alanın Sınırlarını" (CoordinateBounds) hesaplat
//       // "getBounds()" yerine "getCoordinateBoundsForCamera()" kullanıyoruz.
//       final bounds = await mapboxMap.coordinateBoundsForCamera(
//         CameraOptions(
//           center: cameraState.center,
//           zoom: cameraState.zoom,
//           pitch: cameraState.pitch,
//           bearing: cameraState.bearing,
//         ),
//       );

//       // 3. Zoom seviyesine göre hassasiyet (Precision) ayarla
//       const precision = 7;
//       // 4. Repository'ye doğru TİPTE (CoordinateBounds) veri gönder
//       final events = await _mapRepository.fetchEventsInBounds(
//         bounds: bounds,
//         precision: precision,
//       );

//       for (final event in events) {
//         await _addMapProfileMarker(event);
//       }
//     } catch (e) {
//       _logger.error('Error fetching visible events: $e');
//     }
//   }

//   void _flyToEvent(EventEntity event) {
//     mapboxMap.flyTo(
//       CameraOptions(
//         center: Point(
//           coordinates: Position(
//             event.location.longitude,
//             event.location.latitude,
//           ),
//         ),
//         padding: MbxEdgeInsets(
//           top: 0,
//           left: 0,
//           bottom: 50.h,
//           right: 0,
//         ),
//       ),
//       MapAnimationOptions(duration: 1200),
//     );
//   }

//   void _onMapBackgroundClick(MapContentGestureContext context) {
//     if (_isCardVisible) {
//       setState(() {
//         _isCardVisible = false;
//       });
//     }
//   }

//   // ... _generateCustomMarkerImage METODU AYNI KALACAK ...
//   Future<Uint8List?> _generateCustomMarkerImage(
//     String imageUrl, {
//     double scale = 1.0,
//   }) async {
//     // (Eski kodundakiyle birebir aynı)
//     // ...
//     // Yer kaplamaması için burayı kısalttım, senin kodundakini koru.
//     try {
//       final colorPair = kMarkerPalette[Random().nextInt(kMarkerPalette.length)];

//       final response = await http.get(Uri.parse(fixEmulatorUrl(imageUrl)));
//       if (response.statusCode != 200) return null;

//       final codec = await ui.instantiateImageCodec(response.bodyBytes);
//       final fi = await codec.getNextFrame();
//       final profileImage = fi.image;

//       const baseOuterRadius = 60.0;
//       const baseRingRadius = 46.0;
//       const baseImageRadius = 37.0;
//       const baseCanvasSize = 140.0;

//       final double outerRadius = baseOuterRadius * scale;
//       final double ringRadius = baseRingRadius * scale;
//       final double imageRadius = baseImageRadius * scale;
//       final double canvasSize = baseCanvasSize * scale;

//       final double center = canvasSize / 2;

//       final recorder = ui.PictureRecorder();
//       final canvas = Canvas(recorder);
//       final paint = Paint()..isAntiAlias = true;

//       final shadowPath = Path()
//         ..addOval(
//           Rect.fromCircle(
//             center: Offset(center, center + (2 * scale)),
//             radius: outerRadius,
//           ),
//         );
//       canvas.drawShadow(shadowPath, Colors.black, 3.0 * scale, true);

//       paint.color = colorPair.outer;
//       canvas.drawCircle(Offset(center, center), outerRadius, paint);

//       paint.color = colorPair.inner;
//       canvas.drawCircle(Offset(center, center), ringRadius, paint);

//       final imagePath = Path()
//         ..addOval(
//           Rect.fromCircle(
//             center: Offset(center, center),
//             radius: imageRadius,
//           ),
//         );
//       canvas.clipPath(imagePath);

//       paint.filterQuality = FilterQuality.high;

//       final srcW = profileImage.width.toDouble();
//       final srcH = profileImage.height.toDouble();
//       final dstSize = imageRadius * 2;

//       canvas.drawImageRect(
//         profileImage,
//         Rect.fromLTWH(0, 0, srcW, srcH),
//         Rect.fromLTWH(
//           center - imageRadius,
//           center - imageRadius,
//           dstSize,
//           dstSize,
//         ),
//         Paint(),
//       );

//       final markerImage = await recorder.endRecording().toImage(
//         canvasSize.toInt(),
//         canvasSize.toInt(),
//       );
//       final byteData = await markerImage.toByteData(
//         format: ui.ImageByteFormat.png,
//       );

//       return byteData?.buffer.asUint8List();
//     } catch (e) {
//       return null;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // ... (Aynı kalacak)
//     // Sadece build metodu senin kodundaki gibi.
//     final camera = CameraOptions(
//       center: Point(coordinates: Position(28.9795, 41.0151)),
//       zoom: 17, // Biraz daha zoom out başlatabilirsin
//       bearing: 0,
//       pitch: 0,
//     );

//     return Scaffold(
//       body: Stack(
//         children: [
//           MapWidget(
//             cameraOptions: camera,
//             onMapCreated: _onMapCreated,
//             styleUri: MapboxStyles.MAPBOX_STREETS,
//             onTapListener: _onMapBackgroundClick,
//             onCameraChangeListener: _onCameraChangeListener,
//           ),

//           AnimatedPositioned(
//             duration: const Duration(milliseconds: 250),
//             curve: Curves.easeInOut,
//             bottom: _isCardVisible ? 0 : -400.h,
//             left: 0,
//             right: 0,
//             child: _selectedEvent != null
//                 ? EventCard(
//                     event: _selectedEvent!,
//                     participants: _selectedEvent!.participants,
//                   )
//                 : const SizedBox.shrink(),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class MarkerColorPair {
//   final Color outer;
//   final Color inner;
//   const MarkerColorPair({required this.outer, required this.inner});
// }

// // Widget'ındaki renklerin aynısı
// const List<MarkerColorPair> kMarkerPalette = [
//   MarkerColorPair(
//     outer: Color(0xFFC6D0D9),
//     inner: Color(0xFF5B7A98),
//   ), // Mavi-Gri
//   MarkerColorPair(outer: Color(0xFFFFCCBC), inner: Color(0xFFFF7043)), // Somon
//   MarkerColorPair(outer: Color(0xFFC8E6C9), inner: Color(0xFF66BB6A)), // Yeşil
//   MarkerColorPair(outer: Color(0xFFFFF9C4), inner: Color(0xFFFDD835)), // Sarı
//   MarkerColorPair(outer: Color(0xFFE1BEE7), inner: Color(0xFFAB47BC)), // Mor
// ];
