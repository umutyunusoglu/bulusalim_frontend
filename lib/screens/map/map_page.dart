import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/components/event_card.dart';
import 'package:bulusalim/components/map_create_button.dart';
import 'package:bulusalim/components/map_filter_chip.dart';
import 'package:bulusalim/core/constants/configs/app_config.dart';
import 'package:bulusalim/core/utils/debug/android_image_url_fixer.dart';
import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/domain/repositories/map_repository.dart';
import 'package:flutter/foundation.dart'; // Uint8List için
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
  // --- DEPENDENCIES ---
  final PageController _pageController = PageController();
  final LoggingService _logger = getIt<LoggingService>();
  final MapRepository _mapRepository = getIt<MapRepository>();

  // --- STATE ---
  final Map<String, String> _categories = AppConfig.categories;
  String? _selectedCategory;
  bool _isCardVisible = false;
  EventEntity? _selectedEvent;

  // --- MAPBOX ---
  late MapboxMap mapboxMap;
  PointAnnotationManager? pointAnnotationManager;
  Cancelable? _clickListener;

  // --- OPTIMIZATION & CACHE ---
  /// Mapbox annotation ID -> EventEntity eşleşmesi
  final Map<String, EventEntity> _markerEventMap = {};

  /// Şu an haritada olan veya yüklenmekte olan Event ID'leri (Race condition önleyici)
  final Set<String> _loadedEventIds = {};

  /// Marker resim cache'i (Tekrar tekrar işlem yapmamak için)
  final Map<String, Uint8List> _markerImageCache = {};

  /// Gereksiz fetch önlemek için son çekilen bounds
  CoordinateBounds? _lastFetchedBounds;

  Timer? _debounceTimer;

  /// Sayfanın yaşam döngüsü kontrolü (Async gap protection)
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true; // Guard flag'i aktif et

    _debounceTimer?.cancel();
    _clickListener?.cancel();
    _pageController.dispose();
    _markerImageCache.clear();

    // Annotation Manager temizliği (Safe Dispose)
    if (pointAnnotationManager != null) {
      try {
        pointAnnotationManager!.deleteAll();
      } on Exception catch (e) {
        // Sayfa kapanırken oluşan hataları yutabiliriz
        debugPrint('Annotation cleanup error: $e');
      }
    }

    super.dispose();
  }

  // --- 1. KATEGORİ FİLTRELEME ---
  Future<void> _onCategoryChanged() async {
    if (_isDisposed) return;
    // Kategori değişince mevcut markerları temizleyip yeniden çekmek mantıklı olabilir
    // Ancak diffing algoritması bunu zaten halledecek.
    await _fetchVisibleEvents(forceRefresh: true);
  }

  // --- 2. DIFFING ALGORİTMASI (SAFE MARKER UPDATE) ---
  Future<void> _updateMarkers(List<EventEntity> visibleEvents) async {
    // Guard: Sayfa kapandıysa veya manager yoksa işlem yapma
    if (_isDisposed || !mounted || pointAnnotationManager == null) return;

    final targetEventIds = visibleEvents.map((e) => e.id).toSet();

    // A. SİLİNECEKLER (To Remove)
    // ConcurrentModificationError yememek için .toList() ile kopyasını alıyoruz
    final markersToRemoveEntries = _markerEventMap.entries.where((entry) {
      return !targetEventIds.contains(entry.value.id);
    }).toList();

    if (markersToRemoveEntries.isNotEmpty) {
      try {
        final annotationIdsToDelete = markersToRemoveEntries
            .map((e) => e.key)
            .toList();

        // 1. Local State Temizliği
        for (final entry in markersToRemoveEntries) {
          _loadedEventIds.remove(entry.value.id);
          _markerEventMap.remove(entry.key);
        }

        // 2. Mapbox Toplu Silme
        // Mapbox annotation objelerine ihtiyacımız var
        final allAnnotations = await pointAnnotationManager!.getAnnotations();
        final annotationsToDelete = allAnnotations
            .where((a) => annotationIdsToDelete.contains(a.id))
            .toList();

        if (annotationsToDelete.isNotEmpty) {
          // Varsa toplu silme, yoksa döngü
          for (final annotation in annotationsToDelete) {
            await pointAnnotationManager!.delete(annotation);
          }
        }
      } on Exception catch (e) {
        _logger.warn('Marker silme hatası: $e');
      }
    }

    // B. EKLENECEKLER (To Add)
    final eventsToAdd = visibleEvents.where((e) {
      return !_loadedEventIds.contains(e.id);
    }).toList();

    for (final event in eventsToAdd) {
      // Döngü sırasında sayfa kapanırsa hemen çık
      if (_isDisposed || !mounted) break;
      await _addMapProfileMarker(event);
    }
  }

  Future<void> _addMapProfileMarker(EventEntity event) async {
    // Race Condition Guard (Optimistic Locking)
    if (_loadedEventIds.contains(event.id)) return;
    _loadedEventIds.add(event.id); // Kilidi koy

    final url = event.creator.profileImageUrl;

    // Resim oluşturma (Ağır işlem, UI thread'i bloklamasın)
    final customMarkerIcon = await _generateCustomMarkerImage(url, scale: 1.5);

    // FIX: İşlem bitince sayfa kapanmışsa veya resim başarısızsa iptal et
    if (_isDisposed || !mounted || customMarkerIcon == null) {
      _loadedEventIds.remove(event.id); // Kilidi kaldır
      return;
    }

    try {
      if (pointAnnotationManager == null) {
        _loadedEventIds.remove(event.id);
        return;
      }

      final annotation = await pointAnnotationManager!.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              event.location.longitude,
              event.location.latitude,
            ),
          ),
          image: customMarkerIcon,
          iconSize: 0.6,
          textSize: 10,
          textOffset: [0.0, 2.0],
          textColor: Colors.black.value,
        ),
      );

      // Başarılı, map'e kaydet
      _markerEventMap[annotation.id] = event;
    } on Exception {
      // Hata olursa kilidi aç ki sonra tekrar denenebilsin
      _loadedEventIds.remove(event.id);
      _logger.error('Marker ekleme hatası: $e');
    }
  }

  // --- 3. RESİM OLUŞTURMA & CACHE ---
  Future<Uint8List?> _generateCustomMarkerImage(
    String imageUrl, {
    double scale = 1.0,
  }) async {
    if (_markerImageCache.containsKey(imageUrl)) {
      return _markerImageCache[imageUrl];
    }

    try {
      // Deterministik Renk (Event'e/URL'e bağlı sabit renk)
      final colorIndex = imageUrl.hashCode.abs() % kMarkerPalette.length;
      final colorPair = kMarkerPalette[colorIndex];

      final response = await http
          .get(Uri.parse(fixEmulatorUrl(imageUrl)))
          .timeout(const Duration(seconds: 10)); // Timeout eklendi

      if (response.statusCode != 200) return null;

      final codec = await ui.instantiateImageCodec(response.bodyBytes);
      final fi = await codec.getNextFrame();
      final profileImage = fi.image;

      const baseOuterRadius = 60.0;
      const baseRingRadius = 46.0;
      const baseImageRadius = 37.0;
      const baseCanvasSize = 140.0;

      final outerRadius = baseOuterRadius * scale;
      final ringRadius = baseRingRadius * scale;
      final imageRadius = baseImageRadius * scale;
      final canvasSize = baseCanvasSize * scale;

      final center = canvasSize / 2;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..isAntiAlias = true;

      // Gölge
      final shadowPath = Path()
        ..addOval(
          Rect.fromCircle(
            center: Offset(center, center + (2 * scale)),
            radius: outerRadius,
          ),
        );
      canvas.drawShadow(shadowPath, Colors.black, 3.0 * scale, true);

      // Dış Çember
      paint.color = colorPair.outer;
      canvas.drawCircle(Offset(center, center), outerRadius, paint);

      // İç Çember
      paint.color = colorPair.inner;
      canvas.drawCircle(Offset(center, center), ringRadius, paint);

      // Resim Kırpma
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

      final bytes = byteData?.buffer.asUint8List();

      if (bytes != null) {
        _markerImageCache[imageUrl] = bytes;
      }

      return bytes;
    } on Exception {
      // Resim yüklenemezse null dön
      return null;
    }
  }

  // --- MAP INIT & EVENTS ---
  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;

    await mapboxMap.gestures.updateSettings(
      GesturesSettings(
        scrollEnabled: true,
        rotateEnabled: true,
        pitchEnabled: false,
      ),
    );

    // Style yüklenme hatası için try-catch
    try {
      await mapboxMap.style.setStyleLayerProperty(
        'poi-label',
        'visibility',
        'none',
      );
      // ignore: empty_catches
    } on Exception {
      _logger.warn('POI label gizleme hatası');
    }

    pointAnnotationManager = await mapboxMap.annotations
        .createPointAnnotationManager();

    // İlk veriyi çek
    await _fetchVisibleEvents(forceRefresh: true);

    _clickListener = pointAnnotationManager?.tapEvents(
      onTap: (PointAnnotation annotation) {
        final event = _markerEventMap[annotation.id];
        if (event != null) {
          if (mounted) {
            setState(() {
              _selectedEvent = event;
              _isCardVisible = true;
            });
            _flyToEvent(event);
          }
        }
      },
    );
  }

  void _onCameraChangeListener(CameraChangedEventData event) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (!_isDisposed && mounted) {
        _fetchVisibleEvents();
      }
    });
  }

  // --- SMART FETCH LOGIC ---
  Future<void> _fetchVisibleEvents({bool forceRefresh = false}) async {
    if (_isDisposed || !mounted) return;

    try {
      final cameraState = await mapboxMap.getCameraState();

      // OPTIMIZATION: Çok uzaktan (Dünya görünümü) veri çekmeyi engelle
      // Zoom seviyesi 8'den küçükse fetch yapma.
      if (cameraState.zoom < 8.0) {
        // İsteğe bağlı: Kullanıcıya "Yakınlaşın" mesajı verilebilir
        return;
      }

      final bounds = await mapboxMap.coordinateBoundsForCamera(
        CameraOptions(
          center: cameraState.center,
          zoom: cameraState.zoom,
          pitch: cameraState.pitch,
          bearing: cameraState.bearing,
        ),
      );

      // OPTIMIZATION: Region Equality Check
      // Eğer forceRefresh yoksa ve kamera çok az oynadıysa tekrar istek atma.
      if (!forceRefresh && _isBoundsSimilar(bounds, _lastFetchedBounds)) {
        return;
      }
      _lastFetchedBounds = bounds;

      final dynamicPrecision = _getGeohashPrecision(cameraState.zoom);

      final events = await _mapRepository.fetchEventsInBounds(
        bounds: bounds,
        precision: dynamicPrecision,
      );

      if (_isDisposed || !mounted) return;

      final filteredEvents = _selectedCategory == null
          ? events
          : events.where((e) {
              return e.hobbies.contains(_selectedCategory);
            }).toList();

      await _updateMarkers(filteredEvents);
    } on Exception catch (e) {
      _logger.error('Error fetching visible events: $e');
    }
  }

  // Helper: Bounds benzerlik kontrolü
  bool _isBoundsSimilar(CoordinateBounds? a, CoordinateBounds? b) {
    if (a == null || b == null) return false;

    // Köşe noktalarının farkı çok azsa "benzer" kabul et (~50-100m tolerans)
    const threshold = 0.0005;
    final latDiff =
        (a.southwest.coordinates.lat.toDouble() -
                b.southwest.coordinates.lat.toDouble())
            .abs();
    final lngDiff =
        (a.southwest.coordinates.lng.toDouble() -
                b.southwest.coordinates.lng.toDouble())
            .abs();

    return latDiff < threshold && lngDiff < threshold;
  }

  int _getGeohashPrecision(double zoom) {
    if (zoom >= 16) return 7;
    if (zoom >= 14) return 6;
    if (zoom >= 11) return 5;
    if (zoom >= 8) return 4;
    return 3;
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
          bottom: 250.h, // Kartın arkasında kalmaması için padding
          right: 0,
        ),
        zoom: 16.5, // Tıklandığında biraz yaklaşsın
      ),
      MapAnimationOptions(duration: 1200),
    );
  }

  void _onMapBackgroundClick(MapContentGestureContext context) {
    if (_isCardVisible) {
      if (mounted) {
        setState(() {
          _isCardVisible = false;
          _selectedEvent = null; // Seçimi temizle
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final camera = CameraOptions(
      center: Point(coordinates: Position(29.0254, 40.9819)),
      zoom: 13, // Başlangıç zoom seviyesi biraz daha mantıklı
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

          // 2. KATMAN: FİLTRE BAR
          Positioned(
            top: 60
                .h, // SafeArea'yı hesaba katarak biraz aşağı aldım (AppBar yoksa)
            left: 0,
            right: 0,
            child: SafeArea(
              child: SizedBox(
                height: 40.h,
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) => SizedBox(width: 10.w),
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
                              _selectedCategory = null;
                            } else {
                              _selectedCategory = key;
                            }
                          });
                          _onCategoryChanged();
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // 3. KATMAN: ETKİNLİK KARTI (ANIMATED)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutBack, // Biraz daha canlı bir animasyon
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

          // 4. KATMAN: ETKİNLİK OLUŞTUR BUTONU (FIXED LAYOUT)
          Positioned(
            bottom: 40.h,
            right: 16.w,
            child: SafeArea(
              child: MapCreateButton(
                onTap: () {
                  debugPrint('Etkinlik Oluştur Tıklandı');
                  // Navigator.pushNamed(context, '/create_event');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- YARDIMCI CLASS (Değişmedi) ---
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
