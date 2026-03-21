import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dart_geohash/dart_geohash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart' hide Position;
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:outnest/application/service_locators/get_it_init.dart';
import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/enums/account_type_enum.dart';
import 'package:outnest/core/utils/types/enums/create_event_step_enum.dart';
import 'package:outnest/core/utils/types/enums/event_role_enum.dart';
import 'package:outnest/core/utils/types/enums/event_status_enum.dart';
import 'package:outnest/core/utils/types/enums/screen_enum.dart';
import 'package:outnest/core/utils/types/enums/visibility_enum.dart';
import 'package:outnest/core/utils/types/geolocation/geolocation.dart';
import 'package:outnest/domain/entities/feed/event/event_community_data.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/repositories/event_repository.dart';
import 'package:outnest/domain/repositories/group_repository.dart';
import 'package:outnest/domain/repositories/map_repository.dart';
import 'package:outnest/domain/services/analytics/analytics_service.dart';
import 'package:outnest/domain/services/analytics/event_configs/create_event_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/fail_event_creation_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/filter_map_by_time_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/filter_map_by_visibility_analytics_config.dart';
import 'package:outnest/domain/services/file_service.dart';
import 'package:outnest/domain/services/geocoding_service.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/domain/usecases/upload_community_event_photo_usecase.dart';
import 'package:outnest/presentation/map/view/components/create_event_popup.dart';
import 'package:outnest/presentation/map/view/components/map_people_filter.dart';
import 'package:outnest/presentation/map/view/components/map_time_filter.dart';
import 'package:outnest/presentation/map/view/components/steps/category_selection_step.dart';
import 'package:outnest/presentation/map/view/components/steps/event_name_step.dart';
import 'package:outnest/presentation/map/view/components/steps/event_summary_overlay.dart';
import 'package:outnest/presentation/map/view/components/steps/location_selection_step.dart';
import 'package:outnest/presentation/map/view/components/steps/time_selection_step.dart';
import 'package:outnest/presentation/map/view/components/steps/visibility_selection_step.dart';
import 'package:outnest/presentation/shared/action_buttons_speed_dial.dart';
import 'package:outnest/presentation/shared/category_filter_chip.dart';
import 'package:outnest/presentation/shared/dialogs/show_popups.dart';
import 'package:outnest/presentation/shared/event_card/view/event_card.dart';
import 'package:outnest/presentation/shared/navigation/navigate_to_camera.dart';

class MapPage extends StatefulWidget {
  const MapPage({
    super.key,
    this.isLocationPicker = false,
    this.isTimePicker = false,
    this.openCreateOnLoad = false,
  });

  final bool isLocationPicker;
  final bool isTimePicker;
  final bool openCreateOnLoad;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // --- DEPENDENCIES ---
  final PageController _pageController = PageController();
  final LoggingService _logger = getIt<LoggingService>();
  final MapRepository _mapRepository = getIt<MapRepository>();
  final GeocodingService _geocodingService = getIt<GeocodingService>();

  Geolocation? _userLocation = null;
  final ValueNotifier<bool> _isDialOpen = ValueNotifier(false);
  // --- STATE ---
  final Map<String, String> _categories = AppConfig.categories;
  String? _selectedCategory;
  bool _isCardVisible = false;
  EventEntity? _selectedEvent;
  DateTimeRange? _filterTimeRange;
  String? _tempCommunityDescription;
  String? _tempCommunityRules;
  String? _tempCommunityVenueInfo;
  String? _tempCommunityLink;
  int? _tempCommunityMaxParticipants;
  bool? _tempCommunityRequiresDocument;
  File? _tempCommunityImage;

  VisibilityEnum _filterPeople = VisibilityEnum.everyone;
  // --- WIZARD STATE ---
  int _createEventStep = 0;
  // 0:Kategori, 1:Konum, 2:Zaman, 3:Görünürlük, 4:İsim
  bool _isCreatePopupVisible = false;
  bool _isPickingFromMap = false;
  bool _isLocationPermissionGranted = false;

  // --- GEÇİCİ VERİLER ---
  String? _tempCategory;
  String? _tempAddress;
  String? _tempDisplayAddress;
  Geolocation? _tempLocation;
  DateTime? _tempDate;
  TimeOfDay? _tempTime;
  String? _tempEventName;
  VisibilityEnum? _tempVisibility;
  String? _tempVisibilityGroupID;
  PointAnnotation? _pickingMarker;
  String? _currentUserImageUrl;
  bool? _tempShowOnMap;

  bool _isCreating = false;

  bool _isLocationSearchUsed = false;
  bool _isNameSuggestionUsed = false;

  // --- MAPBOX ---
  late MapboxMap mapboxMap;
  PointAnnotationManager? pointAnnotationManager;
  Cancelable? _clickListener;

  // --- OPTIMIZATION & CACHE ---
  final Map<String, EventEntity> _markerEventMap = {};
  final Set<String> _loadedEventIds = {};
  final Map<String, Uint8List> _markerImageCache = {};
  CoordinateBounds? _lastFetchedBounds;
  // --- STATE --- bloğunun içine ekleyin
  List<EventEntity> _cachedEvents =
      []; // Sunucudan gelen tüm eventler burada duracak
  Timer? _debounceTimer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    if (widget.openCreateOnLoad) {
      _isCreatePopupVisible = true;
    }

    final imageURL = getIt<SessionService>().currentUser?.profileImageUrl;
    // Modlara göre başlangıç adımını ayarla
    if (imageURL != null) {
      _currentUserImageUrl = imageURL;
    } else {
      _currentUserImageUrl = FileService.defaultProfileImageUrl();
    }

    if (widget.isLocationPicker) {
      _isCreatePopupVisible = true;
      _createEventStep = 1; // Konum adımı
      _tempCategory = 'Genel';
    } else if (widget.isTimePicker) {
      _isCreatePopupVisible = true;
      _createEventStep = 2; // Zaman adımı
      _tempCategory = 'Genel';
      _isPickingFromMap = false;
    }

    _initializeLocation();
  }

  @override
  void didUpdateWidget(covariant MapPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.openCreateOnLoad && !oldWidget.openCreateOnLoad) {
      setState(() {
        _isCreatePopupVisible = true;
      });
    }
  }

  Future<void> _initializeLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _userLocation = Geolocation(
            latitude: position.latitude,
            longitude: position.longitude,
          );
          _isLocationPermissionGranted = true;
        });
        _logger.info(
          'Kullanıcı konumu alındı: (${position.latitude}, ${position.longitude})',
        );
      }

      _logger.info('Kullanıcı konumu alındı ve harita kaydırıldı.');
    } else {
      _logger.warn('Konum izni reddedildi. Harita konumu alınamayacak.');
      if (mounted) {
        showErrorPopup(
          context,
          message: 'Konum izni reddedildi. Harita konumu alınamayacak.',
        );

        setState(() {
          _userLocation = Geolocation(
            latitude: 40.9819,
            longitude: 29.0254,
          );
          _isLocationPermissionGranted = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    _clickListener?.cancel();
    _pageController.dispose();
    _markerImageCache.clear();
    _filterDebounce?.cancel();
    _isDialOpen.dispose();
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

  void _closeWizard(
    CreateEventStepEnum closedAtStep, {
    bool completed = false,
  }) {
    if (!completed) {
      getIt<AnalyticsService>().logFailEventCreation(
        FailEventCreationAnalyticsConfig(
          failStep: closedAtStep,
          category: _tempCategory,
          isLocationSearched: _tempLocation != null && _isLocationSearchUsed,
          hasStartTime: _tempDate != null && _tempTime != null,
          visibility: _tempVisibility ?? VisibilityEnum.everyone,
          showOnMap: _tempShowOnMap ?? false,
          isNameSuggestionUsed: _tempEventName != null && _isNameSuggestionUsed,
        ),
      );
    }
    _removePickingMarker();
    setState(() {
      _tempCategory = null;
      _tempAddress = null;
      _tempLocation = null;
      _tempDisplayAddress = null;
      _tempDate = null;
      _tempTime = null;
      _tempEventName = null;
      _isCreatePopupVisible = false;
      _createEventStep = 0;
      _isPickingFromMap = false;
    });
  }

  Future<void> _removePickingMarker() async {
    if (_pickingMarker != null && pointAnnotationManager != null) {
      try {
        await pointAnnotationManager!.delete(_pickingMarker!);
      } catch (e) {
        _logger.warn('Error removing picking marker: $e');
      }
      _pickingMarker = null;
    }
  }

  // --- HARİTADAN İŞARETLEME MANTIĞI ---
  Future<void> _handleMapPick(double lat, double lng) async {
    if (pointAnnotationManager == null) return;

    if (_pickingMarker != null) {
      try {
        await pointAnnotationManager!.delete(_pickingMarker!);
      } catch (e) {}
      _pickingMarker = null;
    }

    final customMarkerIcon = await _generateCustomMarkerImage(
      _currentUserImageUrl ?? '',
      scale: 1.5,
    );

    if (customMarkerIcon == null) return;

    try {
      final annotation = await pointAnnotationManager!.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(lng, lat)),
          image: customMarkerIcon,
          iconSize: 0.8,
          iconOffset: [0, -10],
        ),
      );

      final newLocation = Geolocation(latitude: lat, longitude: lng);

      setState(() {
        _pickingMarker = annotation;
        _tempLocation = newLocation;
      });

      // Display address'i GeocodingService ile senkron hesapla
      final localResult = _geocodingService.getCityDistrictFromGeolocation(
        newLocation,
      );
      if (localResult != null && mounted) {
        setState(() {
          _tempDisplayAddress = '${localResult.district}, ${localResult.city}';
        });
      }

      // Full address için Mapbox reverse geocode (arka planda)
      final place = await _mapRepository.geocodeLocation(newLocation);
      if (place != null && mounted) {
        setState(() {
          _tempAddress = place.adresss;
          // geocodeLocation zaten GeocodingService kullanıyor,
          // ama eğer localResult null idiyse displayAddress'i de güncelle
          if (localResult == null) {
            _tempDisplayAddress = place.displayAddress;
          }
        });
      }
    } catch (e) {
      _logger.error('Error creating picking marker: $e');
    }
  }

  bool _isWithinRange(DateTime dt, DateTimeRange range) {
    return !(dt.isBefore(range.start) || dt.isAfter(range.end));
  }

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

        for (final entry in markersToRemoveEntries) {
          _loadedEventIds.remove(entry.value.eventID);
          _markerEventMap.remove(entry.key);
        }

        final allAnnotations = await pointAnnotationManager!.getAnnotations();
        final annotationsToDelete = allAnnotations
            .where((a) => annotationIdsToDelete.contains(a.id))
            .toList();

        if (annotationsToDelete.isNotEmpty) {
          for (final annotation in annotationsToDelete) {
            await pointAnnotationManager!.delete(annotation);
          }
        }
      } catch (e) {
        _logger.warn('Marker silme hatası: $e');
      }
    }

    // Eklenecekler
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
      if (event.location == null) {
        _loadedEventIds.remove(event.eventID);
        return;
      }

      final annotation = await pointAnnotationManager!.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              event.location!.longitude,
              event.location!.latitude,
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
    } catch (e) {
      _loadedEventIds.remove(event.eventID);
      _logger.error('Marker ekleme hatası: $e');
    }
  }

  Future<Uint8List?> _generateCustomMarkerImage(
    String imageUrl, {
    double scale = 1.0,
  }) async {
    if (_markerImageCache.containsKey(imageUrl)) {
      return _markerImageCache[imageUrl];
    }
    try {
      ui.Image profileImage;
      final colorIndex = imageUrl.hashCode.abs() % kMarkerPalette.length;
      final colorPair = kMarkerPalette[colorIndex];
      if (!imageUrl.startsWith('http')) {
        profileImage = await _loadAssetImage(
          FileService.defaultProfileImageUrl(),
        );
      } else {
        try {
          final response = await http
              .get(Uri.parse(fixEmulatorUrl(imageUrl)))
              .timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final codec = await ui.instantiateImageCodec(response.bodyBytes);
            final fi = await codec.getNextFrame();
            profileImage = fi.image;
          } else {
            profileImage = await _loadAssetImage(
              'assets/images/default_user.png',
            );
          }
        } catch (e) {
          _logger.warn("Resim indirilemedi, default'a dönülüyor: $e");
          profileImage = await _loadAssetImage(
            'assets/images/default_user.png',
          );
        }
      }
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

  Future<ui.Image> _loadAssetImage(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final fi = await codec.getNextFrame();
    return fi.image;
  }

  // --- MAP INIT ---
  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;

    unawaited(
      mapboxMap.compass.updateSettings(CompassSettings(enabled: false)),
    );

    // Mapbox logosunu gizle
    unawaited(mapboxMap.logo.updateSettings(LogoSettings(enabled: false)));

    // Bilgi (i) butonunu gizle
    unawaited(
      mapboxMap.attribution.updateSettings(AttributionSettings(enabled: false)),
    );

    // Ölçek çubuğunu gizle
    unawaited(
      mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false)),
    );
    await mapboxMap.gestures.updateSettings(
      GesturesSettings(
        scrollEnabled: true,
        rotateEnabled: true,
        pitchEnabled: false,
      ),
    );
    await mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        puckBearingEnabled: true,
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

  // A) SADECE VERİ ÇEKME (Harita hareket edince çalışır)
  Future<void> _fetchVisibleEvents({bool forceRefresh = false}) async {
    if (_isDisposed || !mounted) return;
    try {
      final cameraState = await mapboxMap.getCameraState();
      // Zoom seviyesi kontrolü (isteğe bağlı)
      if (cameraState.zoom < 8.0) return;

      final bounds = await mapboxMap.coordinateBoundsForCamera(
        CameraOptions(center: cameraState.center, zoom: cameraState.zoom),
      );

      // Eğer sınırlar çok değişmediyse ve zorlama yoksa istek atma
      if (!forceRefresh && _isBoundsSimilar(bounds, _lastFetchedBounds)) return;

      _lastFetchedBounds = bounds;

      final dynamicPrecision = _getGeohashPrecision(cameraState.zoom);

      // 1. İSTEK AT
      final events = await _mapRepository.fetchEventsInBounds(
        bounds: bounds,
        precision: dynamicPrecision,
      );

      if (_isDisposed || !mounted) return;

      // 2. GELEN VERİYİ CACHE'LE
      _cachedEvents = events;

      // 3. FİLTRELERİ UYGULA (Markerları güncelle)
      _applyLocalFilters();
    } on Exception catch (e) {
      _logger.error('Error fetching visible events: $e');
    }
  }

  // B) SADECE FİLTRELEME (Filtre butonlarına basınca çalışır - İSTEK ATMAZ)
  void _applyLocalFilters() async {
    if (_isDisposed || !mounted) return;

    final sessionService = getIt<SessionService>();
    final currentUser = sessionService.currentUser;
    if (currentUser == null) return;

    //TODO: Move to server side later

    // Hafızadaki (_cachedEvents) veriyi süzüyoruz
    final List<EventEntity> filteredEvents = [];

    for (final e in _cachedEvents) {
      if (currentUser.userID == e.creator.userID) {
        filteredEvents.add(e);
        continue;
      }

      // 1) Kategori filtresi
      final byCategory =
          _selectedCategory == null || e.hobbies.contains(_selectedCategory);

      final isEventStarted = e.status == EventStatusEnum.ongoing;
      // 2) Zaman filtresi
      final byTime =
          (_filterTimeRange == null ||
              _isWithinRange(e.startTime, _filterTimeRange!)) ||
          isEventStarted;

      // 3) Kişi filtresi

      var byPeople = true;
      switch (_filterPeople) {
        case VisibilityEnum.everyone:
          byPeople = true;
        case VisibilityEnum.onlyFriends:
          final whoIFollow = sessionService.currentState.followees
              .map((u) => u.userID)
              .toSet();

          byPeople = whoIFollow.contains(e.creator.userID);

        case VisibilityEnum.university:
          if (currentUser.university == null) {
            byPeople = false;
          } else {
            byPeople = currentUser.university == e.creator.university;
          }

        case VisibilityEnum.custom:
          if (e.visibilityGroupID == null) {
            byPeople = false;
          } else {
            final groupID = e.visibilityGroupID!;
            byPeople = await getIt<GroupRepository>().isGroupMember(
              currentUser.userID,
              groupID,
            );
          }
      }

      if (byCategory && byTime && byPeople) {
        filteredEvents.add(e);
      }
    }

    // Süzülmüş listeyi markerlara gönder
    await _updateMarkers(filteredEvents);
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
    if (event.location == null) return;
    mapboxMap.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(
            event.location!.longitude,
            event.location!.latitude,
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

  Timer? _filterDebounce;
  // --- BUILD ---
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isSummaryStep = _createEventStep == 5;

    final popupTopNormal = 160.h;

    // Konum veya Zaman seçici modundaysak aşağıda dursun
    final collapsedHeight = (widget.isLocationPicker || widget.isTimePicker)
        ? 110.h
        : 180.h;

    final popupTopCollapsed = size.height - (collapsedHeight + bottomPadding);

    final canPop =
        !_isPickingFromMap &&
        _createEventStep == 0 &&
        !widget.isLocationPicker &&
        !widget.isTimePicker;

    if (_userLocation == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        setState(() {
          if (_isPickingFromMap) {
            _isPickingFromMap = false;
          } else if (_createEventStep > 0 && !widget.isTimePicker) {
            _createEventStep--;
          } else if (widget.isLocationPicker || widget.isTimePicker) {
            context.pop();
          }
        });
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // 1. ZEMİN: HARİTA
            Positioned.fill(
              child: MapWidget(
                key: const ValueKey('mapWidget'),
                cameraOptions: CameraOptions(
                  center: Point(
                    coordinates: Position(
                      _userLocation!.longitude,
                      _userLocation!.latitude,
                    ),
                  ),
                  zoom: 13,
                ),
                onMapCreated: _onMapCreated,
                styleUri:
                    "mapbox://styles/outnestdev/cmldktm5b002o01r0bnvqdjgu",
                onTapListener: _onMapBackgroundClick,
                onCameraChangeListener: _onCameraChangeListener,
              ),
            ),
            if (!_isCreatePopupVisible &&
                // /  !_isCardVisible &&
                !widget.isLocationPicker &&
                !widget.isTimePicker)
              Positioned(
                top: 20.h,
                left: 16.w,
                right: 16.w,
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween, // İki uca yaslar
                    children: [
                      // Zaman Filtresi
                      Expanded(
                        flex: 2,
                        child: MapTimeFilter(
                          onChanged: (range) {
                            // 1. Durumu güncelle
                            setState(() => _filterTimeRange = range);

                            // 2. Önceki zamanlayıcıyı iptal et
                            _filterDebounce?.cancel();

                            // 3. Debounce süresini 150-200ms civarında tutarak akıcılığı sağla
                            _filterDebounce = Timer(
                              const Duration(milliseconds: 150),
                              () {
                                // Filtreleri uygula
                                _applyLocalFilters();

                                // Analytics kaydı
                                getIt<AnalyticsService>().logFilterMapByTime(
                                  FilterMapByTimeAnalyticsConfig(time: range),
                                );
                              },
                            );
                          },
                        ),
                      ),

                      // Yeni Küçük Kişi Filtresi
                      Expanded(
                        flex: 1,
                        child: MapPeopleFilter(
                          options: const [
                            'herkes',
                            'takipçiler',
                            'okul',
                          ],
                          initial: 'herkes',
                          onChanged: (val) {
                            setState(
                              () =>
                                  _filterPeople = VisibilityEnum.fromTurkishUI(
                                    val,
                                  ),
                            );

                            if (_filterDebounce?.isActive ?? false)
                              _filterDebounce!.cancel();

                            _filterDebounce = Timer(
                              const Duration(milliseconds: 200),
                              () {
                                _applyLocalFilters();

                                getIt<AnalyticsService>()
                                    .logFilterMapByVisibility(
                                      FilterMapByVisibilityAnalyticsConfig(
                                        visibility: _filterPeople,
                                      ),
                                    );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // 2. KATEGORİ BAR
            if (!_isCreatePopupVisible &&
                //!_isCardVisible &&
                !widget.isLocationPicker &&
                !widget.isTimePicker)
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
                      separatorBuilder: (_, __) => SizedBox(width: 10.w),
                      itemBuilder: (_, index) {
                        final key = _categories.keys.elementAt(index);
                        return Center(
                          child: CategoryFilterChip(
                            label: key,
                            emoji: _categories[key] ?? '',
                            isSelected: _selectedCategory == key,
                            onTap: () {
                              setState(() {
                                _selectedCategory = _selectedCategory == key
                                    ? null
                                    : key;
                              });

                              if (_filterDebounce?.isActive ?? false) {
                                _filterDebounce!.cancel();
                              }

                              _filterDebounce = Timer(
                                const Duration(milliseconds: 200),
                                () {
                                  _applyLocalFilters();

                                  getIt<AnalyticsService>()
                                      .logFilterMapByVisibility(
                                        FilterMapByVisibilityAnalyticsConfig(
                                          visibility: _filterPeople,
                                        ),
                                      );
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

            // 3. ETKİNLİK KARTI
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutBack,
              bottom: _isCardVisible ? 0 : -400.h,
              left: 0,
              right: 0,
              child: _selectedEvent != null
                  ? EventCard(
                      key: ValueKey(
                        _selectedEvent!.eventID,
                      ),
                      event: _selectedEvent!,
                      participants: _selectedEvent!.participants,
                      screen: ScreenEnum.map,
                    )
                  : const SizedBox.shrink(),
            ),

            // 4. KARARTMA OVERLAY
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

            // 5. POPUP WIZARD
            if (_isCreatePopupVisible)
              if (isSummaryStep)
                Positioned.fill(
                  child: EventSummaryOverlay(
                    previewEvent: _createPreviewEvent(),
                    onCancel: () => _closeWizard(CreateEventStepEnum.summary),
                    onConfirm: _confirmEventCreation,
                    isLoading: _isCreating,
                  ),
                )
              else
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOutCubic,
                  top: _isPickingFromMap ? popupTopCollapsed : popupTopNormal,
                  left: 16.w,
                  right: 16.w,
                  child: SizedBox(
                    height: _isPickingFromMap ? size.height : null,
                    child: Stack(
                      children: [
                        // A) Asıl İçerik
                        CreateEventPopup(
                          child: _buildWizardContent(),
                        ),

                        // B) Dokunma Kalkanı (Sadece Picking Modunda Aktif)
                        if (_isPickingFromMap)
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () {
                                // Tıklandığında sadece yukarı kaldır
                                setState(() {
                                  _isPickingFromMap = false;
                                });
                              },
                              child: Container(
                                color: Colors.transparent,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

            // 6. HARİTADAN SEÇ BUTONU
            if (_isCreatePopupVisible &&
                _createEventStep == 1 &&
                !_isPickingFromMap)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOutCubic,
                top: popupTopNormal + 460.h,
                left: 0,
                right: 0,
                child: Center(child: _buildMapSelectionButton()),
              ),

            if (_isLocationPermissionGranted &&
                !_isCreatePopupVisible &&
                !_isCardVisible &&
                !widget.isLocationPicker &&
                !widget.isTimePicker)
              Positioned(
                bottom: 40.h,
                left: 16.w,
                child: GestureDetector(
                  onTap: () async {
                    try {
                      // A. Bilinen son konumu anında göster (Gecikme 0ms)
                      final lastKnown = await Geolocator.getLastKnownPosition();
                      if (lastKnown != null) {
                        await mapboxMap.flyTo(
                          CameraOptions(
                            center: Point(
                              coordinates: Position(
                                lastKnown.longitude,
                                lastKnown.latitude,
                              ),
                            ),
                            zoom: 17,
                          ),
                          MapAnimationOptions(duration: 1000),
                        );
                      }

                      // B. Güncel konumu orta hassasiyetle iste (Daha hızlı)
                      final position =
                          await Geolocator.getCurrentPosition(
                            desiredAccuracy: LocationAccuracy.medium,
                            timeLimit: const Duration(
                              seconds: 4,
                            ), // Zaman aşımı koymak hayat kurtarır
                          ).catchError(
                            (e) => lastKnown!,
                          ); // Hata alırsan eskisini kullan

                      mapboxMap.flyTo(
                        CameraOptions(
                          center: Point(
                            coordinates: Position(
                              position.longitude,

                              position.latitude,
                            ),
                          ),
                          zoom: 15.0,
                        ),
                        MapAnimationOptions(duration: 1000),
                      );
                      setState(() {
                        _userLocation = Geolocation(
                          latitude: position.latitude,
                          longitude: position.longitude,
                        );
                      });
                    } catch (e) {
                      _logger.error("Hata: $e");
                    }
                  },

                  child: Container(
                    width: 50.w, // Tıklanabilirlik için biraz büyüttüm
                    height: 50.w,
                    decoration: BoxDecoration(
                      color: Colors
                          .white, // Standart konum butonu genelde beyaz olur
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.my_location,
                      color: AppColors.darkPrimaryColor,
                      size: 24.sp,
                    ),
                  ),
                ),
              ),
            // 7. FAB
            if (!_isCreatePopupVisible &&
                !_isCardVisible &&
                !widget.isLocationPicker &&
                !widget.isTimePicker)
              Positioned(
                bottom: 40.h,
                right: 16.w,
                child: SafeArea(
                  child: ActionButtonsSpeedDial(
                    isDialOpen: _isDialOpen,
                    onCameraTap: () => navigateToCamera(context),
                    onLocationTap: () {
                      setState(() {
                        _isCreatePopupVisible = true;
                      });
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWizardContent() {
    switch (_createEventStep) {
      case 0: // Kategori
        return CategorySelectionStep(
          initialSelectedCategory: _tempCategory,
          categories: _categories,
          onClose: () => _closeWizard(CreateEventStepEnum.category),
          onNext: (c) => setState(() {
            _tempCategory = c;
            _createEventStep = 1;
          }),
        );
      case 1: // Konum
        return LocationSelectionStep(
          initialLocation: _tempLocation,
          initialAddress: _tempAddress,
          initialDisplayAddress: _tempDisplayAddress,

          onHeaderTap: () {
            // Popup aşağıdaysa ve header'a tıklanırsa yukarı çıkar
            if (_isPickingFromMap) {
              setState(() {
                _isPickingFromMap = false;
              });
            }
          },

          hideCloseButton: widget.isLocationPicker,

          onClose: () => _closeWizard(CreateEventStepEnum.location),
          // Picker modundaysak Geri butonu sayfayı kapatır
          onBack: widget.isLocationPicker
              ? () => context.pop()
              : () => setState(() => _createEventStep = 0),

          // Picker modundaysak İlerle butonu veriyi geri döndürür
          onNext: (address, displayAddress, location, isLocationSearched) {
            if (widget.isLocationPicker) {
              context.pop({
                'displayAddress': displayAddress,
                'address': address,
                'location': location,
                'isLocationSearched': isLocationSearched,
              });
            } else {
              setState(() {
                _tempLocation = location;
                _tempAddress = address;
                _tempDisplayAddress = displayAddress;
                _createEventStep = 2;
                _isLocationSearchUsed = isLocationSearched;
              });
            }
          },
        );
      case 2: // Zaman
        return TimeSelectionStep(
          // Geri butonu: TimePicker modundaysak sayfayı kapat, yoksa adım 1'e git
          onBack: widget.isTimePicker
              ? () => context.pop()
              : () => setState(() => _createEventStep = 1),

          // Kapat butonu: TimePicker modundaysak null yapıyoruz
          onClose: widget.isTimePicker
              ? null
              : () => _closeWizard(CreateEventStepEnum.time),

          // X Butonunu gizle
          hideCloseButton: widget.isTimePicker,

          // İlerle butonu
          onNext: (d, t, isUndefined) {
            if (widget.isTimePicker) {
              context.pop({
                'date': d,
                'time': t,
                'isTimeUndefined': isUndefined,
              });
            } else {
              setState(() {
                _tempDate = d;
                _tempTime = t;
                _createEventStep = 3;
              });
            }
          },
        );
      case 3: // Görünürlük
        return VisibilitySelectionStep(
          onBack: () => setState(() => _createEventStep = 2),
          onClose: () => _closeWizard(CreateEventStepEnum.visibility),
          onNext: (v, g, h) {
            _tempVisibility = VisibilityEnum.fromTurkishUI(v);
            if (_tempVisibility == VisibilityEnum.custom) {
              final currentUserID = getIt<SessionService>().currentUser!.userID;
              _tempVisibilityGroupID = '$currentUserID-$g';
            }
            _tempShowOnMap = !h;
            setState(
              () => _createEventStep = 4,
            );
          },
        );
      case 4: // İsim
        return EventNameStep(
          onBack: () => setState(() => _createEventStep = 3),
          onClose: () => _closeWizard(CreateEventStepEnum.name),
          onNext: (n, s) async {
            _tempEventName = n;
            _isNameSuggestionUsed = s;

            final isCommunity =
                getIt<SessionService>().currentUser?.accountType ==
                AccountType.community;

            if (isCommunity) {
              final result = await context.push<Map<String, dynamic>>(
                '/community-event-detail',
                extra: {
                  'eventName': n,
                  'displayAddress': _tempDisplayAddress ?? '',
                  'startTime': DateTime(
                    _tempDate!.year,
                    _tempDate!.month,
                    _tempDate!.day,
                    _tempTime!.hour,
                    _tempTime!.minute,
                  ),
                  'category': _tempCategory ?? '',
                },
              );

              // "onayla ve ilerle"ye basıldıysa result dolu gelir
              if (result != null && mounted) {
                setState(() {
                  _tempCommunityDescription = result['description'] as String;
                  _tempCommunityRules = result['rules'] as String;
                  _tempCommunityVenueInfo = result['venueInfo'] as String;
                  _tempCommunityLink = result['link'] as String;
                  _tempCommunityMaxParticipants =
                      result['maxParticipants'] as int;
                  _tempCommunityRequiresDocument =
                      result['requiresDocument'] as bool;
                  _tempCommunityImage = result['coverImage'] as File?;
                  _createEventStep = 5;
                });
              }
              // result null → kullanıcı geri döndü, wizard olduğu yerde kalır
            } else {
              setState(() => _createEventStep = 5);
            }
          },
          category: _tempCategory ?? 'Kahve',
        );
      default:
        return const SizedBox.shrink();
    }
  }

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
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
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

  // --- PREVIEW VE CONFIRM KISIMLARI ---
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
    final currentUser = getIt<SessionService>().currentUser!;

    return EventEntity(
      eventID: '',
      name: _tempEventName ?? 'Başlıksız',
      hobbies: [_tempCategory ?? 'Genel'],
      creator: EventParticipantEntity(
        userID: currentUser.userID,
        username: currentUser.username,
        profileImageUrl: currentUser.profileImageUrl,
        role: EventRoleEnum.creator,
        eventScore: 5,
        university: currentUser.university,
        accountType: currentUser.accountType,
      ),
      status: EventStatusEnum.upcoming,
      capacity: 5,
      participantCount: 1,
      participants: [],
      requestPool: [],
      rejectedUsers: [],
      startTime: startTime,
      endTime: startTime.add(const Duration(hours: 2)),
      location: _tempLocation ?? Geolocation(latitude: 42, longitude: 36),
      displayAddress: _tempDisplayAddress ?? 'Preview',
      address: _tempAddress ?? 'Preview',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isLocked: false,
      geohash: GeoHasher().encode(
        _tempLocation?.longitude ?? 36,
        _tempLocation?.latitude ?? 42,
        precision: 7,
      ),
      visibility: _tempVisibility ?? VisibilityEnum.everyone,
      showOnMap: _tempShowOnMap ?? true,
      accountType: currentUser.accountType,
    );
  }

  Future<void> _confirmEventCreation() async {
    if (_isCreating) return;
    setState(() => _isCreating = true);
    try {
      final eventRepository = getIt<EventRepository>();
      final currentUser = getIt<SessionService>().currentUser!;
      final date = _tempDate ?? DateTime.now();
      final time = _tempTime ?? TimeOfDay.now();
      final startTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      final currentUserCompact = CompactUserEntity(
        userID: currentUser.userID,
        username: currentUser.username,
        profileImageUrl: currentUser.profileImageUrl,
        university: currentUser.university,
        nameSurname: currentUser.nameSurname,
        isPrivate: currentUser.isPrivate,
        bio: currentUser.bio,
        accountType: currentUser.accountType,
        communityData: currentUser.communityData,
      );

      final geohash = GeoHasher().encode(
        _tempLocation!.longitude,
        _tempLocation!.latitude,
        precision: 7,
      );

      // 1. Kapak fotoğrafı varsa önce upload et
      String? coverImageUrl;
      if (_tempCommunityImage != null) {
        coverImageUrl = await getIt<UploadCommunityEventPhoto>().call(
          filePath: _tempCommunityImage!.path,
        );

        if (coverImageUrl == null) {
          throw Exception('Kapak fotoğrafı yüklenemedi.');
        }
      }

      // 2. Event'i URL ile birlikte oluştur
      final event = EventEntity(
        eventID: '',
        name: _tempEventName ?? '',
        hobbies: _tempCategory != null ? [_tempCategory!] : ['Genel'],
        creator: EventParticipantEntity(
          userID: currentUser.userID,
          username: currentUser.username,
          profileImageUrl: currentUser.profileImageUrl,
          role: EventRoleEnum.creator,
          eventScore: 0,
          university: currentUser.university,
          accountType: currentUser.accountType,
        ),
        capacity: AppConfig.eventCapacity,
        participants: [currentUserCompact],
        requestPool: [],
        status: EventStatusEnum.upcoming,
        rejectedUsers: [],
        startTime: startTime,
        endTime: null,
        location: _tempLocation!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        displayAddress: _tempDisplayAddress ?? '',
        address: _tempAddress ?? '',
        participantCount: 1,
        isLocked: false,
        geohash: geohash,
        visibility: _tempVisibility ?? VisibilityEnum.everyone,
        visibilityGroupID: _tempVisibility == VisibilityEnum.custom
            ? _tempVisibilityGroupID
            : null,
        showOnMap: _tempShowOnMap ?? true,
        accountType: currentUser.accountType ?? AccountType.personal,
        communityData: EventCommunityData(
          description: _tempCommunityDescription,
          rules: _tempCommunityRules,
          venueInfo: _tempCommunityVenueInfo,
          link: _tempCommunityLink,
          maxParticipants: _tempCommunityMaxParticipants,
          requiresDocument: _tempCommunityRequiresDocument,
          coverImageUrl: coverImageUrl,
        ),
      );

      await eventRepository.createEvent(event);

      getIt<AnalyticsService>().logCreateEvent(
        CreateEventAnalyticsConfig(
          category: _tempCategory ?? 'diğer',
          isLocationSearched: _isLocationSearchUsed,
          hasStartTime: _tempTime != null,
          visibility: _tempVisibility ?? VisibilityEnum.everyone,
          showOnMap: _tempShowOnMap ?? true,
          isNameSuggestionUsed: _isNameSuggestionUsed,
        ),
      );

      _closeWizard(CreateEventStepEnum.summary, completed: true);
    } catch (e) {
      _logger.error('Etkinlik oluşturulurken hata: $e');
      showErrorPopup(
        context,
        message: 'Etkinlik oluşturulurken bir hata oluştu.',
      );
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}

// Marker Renk Paleti
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
