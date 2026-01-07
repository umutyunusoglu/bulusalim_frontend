import 'dart:async';
import 'dart:ui' as ui;
import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/components/create_event_popup.dart';
import 'package:bulusalim/components/event_card.dart';
import 'package:bulusalim/components/map_create_button.dart';
import 'package:bulusalim/components/map_filter_chip.dart';
import 'package:bulusalim/components/steps/category_selection_step.dart';
import 'package:bulusalim/components/steps/event_name_step.dart';
import 'package:bulusalim/components/steps/event_summary_overlay.dart';
import 'package:bulusalim/components/steps/location_selection_step.dart';
import 'package:bulusalim/components/steps/time_selection_step.dart';
import 'package:bulusalim/components/steps/visibility_selection_step.dart';
import 'package:bulusalim/core/constants/configs/app_config.dart';
import 'package:bulusalim/core/utils/debug/android_image_url_fixer.dart';
import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/core/utils/types/enums/event_role_enum.dart';
import 'package:bulusalim/core/utils/types/enums/event_status_enum.dart';
import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/domain/entities/feed/event/event_entity.dart';
import 'package:bulusalim/domain/entities/user/compact_user_entity.dart';
import 'package:bulusalim/domain/repositories/event_repository.dart';
import 'package:bulusalim/domain/repositories/map_repository.dart';
import 'package:bulusalim/domain/services/session_service.dart';
import 'package:bulusalim/screens/map/map_profile_marker.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:flutter/foundation.dart';
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

  // --- WIZARD STATE ---
  int _createEventStep = 0;
  // 0:Kategori, 1:Konum, 2:Zaman, 3:Görünürlük, 4:İsim
  bool _isCreatePopupVisible = false;
  bool _isPickingFromMap = false;

  // --- GEÇİCİ VERİLER ---
  String? _tempCategory;
  String? _tempAddress;
  Geolocation? _tempLocation;
  DateTime? _tempDate;
  TimeOfDay? _tempTime;
  String? _tempEventName;

  PointAnnotation? _pickingMarker;
  Geolocation? _pickedLocation;

  final String _currentUserImageUrl = 'https://i.pravatar.cc/300?img=12';

  // --- MAPBOX ---
  late MapboxMap mapboxMap;
  PointAnnotationManager? pointAnnotationManager;
  Cancelable? _clickListener;

  // --- OPTIMIZATION & CACHE ---
  final Map<String, EventEntity> _markerEventMap = {};
  final Set<String> _loadedEventIds = {};
  final Map<String, Uint8List> _markerImageCache = {};
  CoordinateBounds? _lastFetchedBounds;
  Timer? _debounceTimer;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    _clickListener?.cancel();
    _pageController.dispose();
    _markerImageCache.clear();
    if (pointAnnotationManager != null) {
      try {
        pointAnnotationManager!.deleteAll();
      } on Exception catch (e) {
        debugPrint('Annotation cleanup error: $e');
      }
    }
    super.dispose();
  }

  // --- YARDIMCI METODLAR ---

  /// Sihirbazı kapatır ve tüm geçici durumları sıfırlar.
  void _closeWizard() {
    _removePickingMarker();
    setState(() {
      _tempCategory = null;
      _tempAddress = null;
      _tempLocation = null;
      _tempDate = null;
      _tempTime = null;
      _tempEventName = null;
      _isCreatePopupVisible = false;
      _createEventStep = 0;
      _isPickingFromMap = false;
    });
  }

  /// Haritadaki konumu onaylar ve popup'ı yukarı taşır.
  Future<void> _confirmLocationFromMap() async {
    if (_isPickingFromMap && _pickedLocation != null) {
      setState(() {
        _logger.info(
          'Picked location: Lat ${_pickedLocation!.latitude}, Lng ${_pickedLocation!.longitude}',
        );
        _tempAddress =
            '${_pickedLocation!.latitude.toStringAsFixed(5)}, ${_pickedLocation!.longitude.toStringAsFixed(5)}';
        _tempLocation = _pickedLocation;
        _isPickingFromMap = false;
      });
      await _removePickingMarker();
    }
  }

  Future<void> _removePickingMarker() async {
    if (_pickingMarker != null && pointAnnotationManager != null) {
      try {
        await pointAnnotationManager!.delete(_pickingMarker!);
      } catch (e) {
        _logger.warn('Error removing picking marker: $e');
      }
      _pickingMarker = null;
      _pickedLocation = null;
    }
  }

  Future<void> _handleMapPick(double lat, double lng) async {
    if (pointAnnotationManager == null) return;

    if (_pickingMarker != null) {
      try {
        await pointAnnotationManager!.delete(_pickingMarker!);
      } catch (e) {
        // ignore
      }
      _pickingMarker = null;
    }

    final customMarkerIcon = await _generateCustomMarkerImage(
      _currentUserImageUrl,
      scale: 1.5,
    );
    if (customMarkerIcon == null) return;

    try {
      final annotation = await pointAnnotationManager!.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(lng, lat),
          ),
          image: customMarkerIcon,
          iconSize: 0.6,
        ),
      );
      setState(() {
        _pickingMarker = annotation;
        _pickedLocation = Geolocation(latitude: lat, longitude: lng);
      });
    } catch (e) {
      _logger.error('Error creating picking marker: $e');
    }
  }

  // --- 1. KATEGORİ FİLTRELEME ---
  Future<void> _onCategoryChanged() async {
    if (_isDisposed) return;
    await _fetchVisibleEvents(forceRefresh: true);
  }

  // --- 2. MARKER YÖNETİMİ ---
  Future<void> _updateMarkers(List<EventEntity> visibleEvents) async {
    if (_isDisposed || !mounted || pointAnnotationManager == null) return;
    final targetEventIds = visibleEvents.map((e) => e.eventID).toSet();

    // Silinecekler
    final markersToRemoveEntries = _markerEventMap.entries
        .where((entry) => !targetEventIds.contains(entry.value.eventID))
        .toList();

    if (markersToRemoveEntries.isNotEmpty) {
      try {
        final annotationIdsToDelete = markersToRemoveEntries
            .map((e) => e.key)
            .toList();

        // Local state temizliği
        for (final entry in markersToRemoveEntries) {
          _loadedEventIds.remove(entry.value.eventID);
          _markerEventMap.remove(entry.key);
        }

        // Mapbox temizliği
        final allAnnotations = await pointAnnotationManager!.getAnnotations();
        final annotationsToDelete = allAnnotations
            .where((a) => annotationIdsToDelete.contains(a.id))
            .toList();

        if (annotationsToDelete.isNotEmpty) {
          for (final annotation in annotationsToDelete) {
            await pointAnnotationManager!.delete(annotation);
          }
        }
      } on Exception catch (e) {
        _logger.warn('Marker silme hatası: $e');
      }
    }

    // EKLENECEKLER
    final eventsToAdd = visibleEvents
        .where((e) => !_loadedEventIds.contains(e.eventID))
        .toList();

    for (final event in eventsToAdd) {
      if (_isDisposed || !mounted) break;
      await _addMapProfileMarker(event);
    }
  }

  Future<void> _addMapProfileMarker(EventEntity event) async {
    if (_loadedEventIds.contains(event.eventID)) return;
    _loadedEventIds.add(event.eventID);

    final url = event.creator.profileImageUrl;
    final customMarkerIcon = await _generateCustomMarkerImage(url, scale: 1.5);

    if (_isDisposed || !mounted || customMarkerIcon == null) {
      _loadedEventIds.remove(event.eventID);
      return;
    }

    try {
      if (pointAnnotationManager == null) {
        _loadedEventIds.remove(event.eventID);
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
      _markerEventMap[annotation.id] = event;
    } on Exception catch (e) {
      _loadedEventIds.remove(event.eventID);
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
      final colorIndex = imageUrl.hashCode.abs() % kMarkerPalette.length;
      final colorPair = kMarkerPalette[colorIndex];
      final response = await http
          .get(Uri.parse(fixEmulatorUrl(imageUrl)))
          .timeout(const Duration(seconds: 10));

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

      // Çemberler
      paint.color = colorPair.outer;
      canvas.drawCircle(Offset(center, center), outerRadius, paint);
      paint.color = colorPair.inner;
      canvas.drawCircle(Offset(center, center), ringRadius, paint);

      // Clip
      final imagePath = Path()
        ..addOval(
          Rect.fromCircle(center: Offset(center, center), radius: imageRadius),
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

      if (bytes != null) _markerImageCache[imageUrl] = bytes;
      return bytes;
    } on Exception {
      return null;
    }
  }

  // --- MAP INIT ---
  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    await mapboxMap.gestures.updateSettings(
      GesturesSettings(
        scrollEnabled: true,
        rotateEnabled: true,
        pitchEnabled: false,
      ),
    );

    try {
      await mapboxMap.style.setStyleLayerProperty(
        'poi-label',
        'visibility',
        'none',
      );
    } on Exception {
      _logger.warn('POI label gizleme hatası');
    }

    pointAnnotationManager = await mapboxMap.annotations
        .createPointAnnotationManager();
    await _fetchVisibleEvents(forceRefresh: true);

    _clickListener = pointAnnotationManager?.tapEvents(
      onTap: (PointAnnotation annotation) {
        if (_isPickingFromMap) {
          final pos = annotation.geometry.coordinates;
          _handleMapPick(pos.lat.toDouble(), pos.lng.toDouble());
          return;
        }

        final event = _markerEventMap[annotation.id];
        if (event != null && mounted) {
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
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (!_isDisposed && mounted) _fetchVisibleEvents();
    });
  }

  // --- FETCH ---
  Future<void> _fetchVisibleEvents({bool forceRefresh = false}) async {
    if (_isDisposed || !mounted) return;
    try {
      final cameraState = await mapboxMap.getCameraState();
      if (cameraState.zoom < 8.0) return;

      final bounds = await mapboxMap.coordinateBoundsForCamera(
        CameraOptions(center: cameraState.center, zoom: cameraState.zoom),
      );

      if (!forceRefresh && _isBoundsSimilar(bounds, _lastFetchedBounds)) return;
      _lastFetchedBounds = bounds;

      final dynamicPrecision = _getGeohashPrecision(cameraState.zoom);
      final events = await _mapRepository.fetchEventsInBounds(
        bounds: bounds,
        precision: dynamicPrecision,
      );

      if (_isDisposed || !mounted) return;

      final filteredEvents = _selectedCategory == null
          ? events
          : events.where((e) => e.hobbies.contains(_selectedCategory)).toList();

      await _updateMarkers(filteredEvents);
    } on Exception catch (e) {
      _logger.error('Error fetching visible events: $e');
    }
  }

  bool _isBoundsSimilar(CoordinateBounds? a, CoordinateBounds? b) {
    if (a == null || b == null) return false;
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
        padding: MbxEdgeInsets(top: 0, left: 0, bottom: 250.h, right: 0),
        zoom: 16.5,
      ),
      MapAnimationOptions(duration: 1200),
    );
  }

  void _onMapBackgroundClick(MapContentGestureContext context) {
    if (_isPickingFromMap) {
      final pos = context.point.coordinates;
      _handleMapPick(pos.lat.toDouble(), pos.lng.toDouble());
      return;
    }
    if (_isCardVisible && mounted) {
      setState(() {
        _isCardVisible = false;
        _selectedEvent = null;
      });
    }
  }

  // --- BUILD ---
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isSummaryStep = _createEventStep == 5;
    final popupTopNormal = 160.h;
    final popupTopCollapsed = size.height - (160.h + bottomPadding);
    final camera = CameraOptions(
      center: Point(coordinates: Position(29.0254, 40.9819)),
      zoom: 13,
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. ZEMİN: HARİTA
          MapWidget(
            key: const ValueKey('mapWidget'),
            cameraOptions: camera,
            onMapCreated: _onMapCreated,
            styleUri: MapboxStyles.MAPBOX_STREETS,
            onTapListener: _onMapBackgroundClick,
            onCameraChangeListener: _onCameraChangeListener,
          ),

          // 2. KATMAN: FİLTRE BAR
          if (!_isCreatePopupVisible && !_isCardVisible)
            Positioned(
              top: 60.h,
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
                              _selectedCategory = isSelected ? null : key;
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

          // 3. KATMAN: ETKİNLİK KARTI
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutBack,
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

          // 4. KATMAN: KARARTMA OVERLAY
          if (_isCreatePopupVisible)
            IgnorePointer(
              ignoring: _isPickingFromMap,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: _isPickingFromMap ? 0.0 : 0.6,
                child: GestureDetector(
                  onTap: () {},
                  child: Container(color: Colors.black),
                ),
              ),
            ),

          // 6. KATMAN: POPUP WIZARD
          if (_isCreatePopupVisible)
            if (isSummaryStep)
              Positioned.fill(
                child: EventSummaryOverlay(
                  previewEvent: _createPreviewEvent(),
                  onCancel: _closeWizard,
                  onConfirm: _closeWizard,
                ),
              )
            else
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOutCubic,
                top: _isPickingFromMap ? popupTopCollapsed : popupTopNormal,
                left: 16.w,
                right: 16.w,
                bottom: _isPickingFromMap ? -500.h : null,
                child: CreateEventPopup(
                  child: _buildWizardContent(),
                ),
              ),

          // 7. KATMAN: HARİTADAN SEÇ BUTONU
          if (_isCreatePopupVisible &&
              _createEventStep == 1 &&
              !_isPickingFromMap)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
              top: popupTopNormal + 460.h,
              left: 0,
              right: 0,
              child: Center(
                child: _buildMapSelectionButton(),
              ),
            ),

          // 8. KATMAN: FAB
          if (!_isCreatePopupVisible && !_isCardVisible)
            Positioned(
              bottom: 40.h,
              right: 16.w,
              child: SafeArea(
                child: MapCreateButton(
                  onTap: () => setState(() => _isCreatePopupVisible = true),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- WIZARD CONTENT ---
  Widget _buildWizardContent() {
    switch (_createEventStep) {
      // ADIM 0: KATEGORİ
      case 0:
        return CategorySelectionStep(
          initialSelectedCategory: _tempCategory,
          categories: _categories,
          onClose: _closeWizard,
          onNext: (c) => setState(() {
            _tempCategory = c;
            _createEventStep = 1;
          }),
        );

      // ADIM 1: KONUM
      case 1:
        return LocationSelectionStep(
          initialLocation: _tempLocation,
          initialAddress: _tempAddress,
          onHeaderTap: _confirmLocationFromMap,
          onClose: _closeWizard,
          onBack: () => setState(() => _createEventStep = 0),
          onNext: (adress, location) => setState(() {
            _logger.info(
              'Selected location: Lat ${location.latitude}, Lng ${location.longitude}',
            );
            _tempLocation = location;
            _tempAddress = adress;
            _createEventStep = 2;
          }),
        );

      // ADIM 2: ZAMAN
      case 2:
        return TimeSelectionStep(
          onBack: () => setState(() => _createEventStep = 1),
          onClose: _closeWizard,
          onNext: (d, t, u) => setState(() {
            _tempDate = d;
            _tempTime = t;
            _createEventStep = 3;
          }),
        );

      // ADIM 3: GÖRÜNÜRLÜK
      case 3:
        return VisibilitySelectionStep(
          onBack: () => setState(() => _createEventStep = 2),
          onClose: _closeWizard,
          onNext: (v, g, h) => setState(() {
            _createEventStep = 4;
          }),
        );

      // ADIM 4: İSİM
      case 4:
        return EventNameStep(
          onBack: () => setState(() => _createEventStep = 3),
          onClose: _closeWizard,
          onNext: (n) => setState(() {
            _tempEventName = n;
            _createEventStep = 5;
          }),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // --- UI PARÇALARI ---
  Widget _buildMapSelectionButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isPickingFromMap = true;
          FocusScope.of(context).unfocus();
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFFDCEAF7),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              size: 18.sp,
              color: const Color(0xFF2C5E87),
            ),
            SizedBox(width: 8.w),
            Text(
              'konumu haritadan işaretle',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2C5E87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  EventEntity _createPreviewEvent() {
    final date = _tempDate ?? DateTime.now();
    final time = _tempTime ?? TimeOfDay.now();
    final startTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    SessionService sessionService = getIt<SessionService>();
    final EventRepository eventRepository = getIt<EventRepository>();

    final currentUser = sessionService.currentUser;

    return EventEntity(
      eventID: '',
      name: _tempEventName ?? 'Başlıksız',
      info: 'Preview',
      hobbies: [_tempCategory ?? 'Genel'],

      creator: EventParticipantEntity(
        userID: currentUser!.userID,
        username: currentUser.username,
        profileImageUrl: currentUser.profileImageUrl,
        role: EventRoleEnum.organizer,
        eventScore: 5,
      ),

      status: EventStatusEnum.upcoming,
      capacity: 5,
      participantCount: 1,
      participants: [
        CompactUserEntity(
          userID: currentUser.userID,
          username: currentUser.username,
          profileImageUrl: currentUser.profileImageUrl,
        ),
      ],
      requestPool: [],
      rejectedUsers: [],
      startTime: startTime,
      endTime: startTime.add(const Duration(hours: 2)),
      location: _tempLocation ?? Geolocation(latitude: 42, longitude: 36),
      address: _tempAddress ?? 'Preview',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isLocked: false,
      geohash: GeoHasher().encode(
        _tempLocation?.longitude ?? 36,
        _tempLocation?.latitude ?? 42,
        precision: 7,
      ),
    );
  }
}

// --- YARDIMCI CLASS ---
class MarkerColorPair {
  const MarkerColorPair({required this.outer, required this.inner});
  final Color outer;
  final Color inner;
}

const List<MarkerColorPair> kMarkerPalette = [
  MarkerColorPair(outer: Color(0xFFC6D0D9), inner: Color(0xFF5B7A98)),
  MarkerColorPair(outer: Color(0xFFFFCCBC), inner: Color(0xFFFF7043)),
  MarkerColorPair(outer: Color(0xFFC8E6C9), inner: Color(0xFF66BB6A)),
  MarkerColorPair(outer: Color(0xFFFFF9C4), inner: Color(0xFFFDD835)),
  MarkerColorPair(outer: Color(0xFFE1BEE7), inner: Color(0xFFAB47BC)),
];
