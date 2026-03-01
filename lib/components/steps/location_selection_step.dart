import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/components/popup_next_button.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/geolocation/geolocation.dart';
import 'package:outnest/domain/repositories/map_repository.dart';
import 'package:uuid/uuid.dart';

class LocationSelectionStep extends StatefulWidget {
  const LocationSelectionStep({
    required this.onBack,
    required this.onNext,
    this.initialLocation,
    this.initialAddress,
    this.initialDisplayAddress,
    this.onClose,
    this.onHeaderTap,
    this.buttonText = 'ilerle',
    this.hideCloseButton = false,
    this.showCloseButton = true,
    super.key,
  });

  final VoidCallback onBack;
  final void Function(String, String, Geolocation, bool) onNext;
  final Geolocation? initialLocation;
  final String? initialAddress;
  final String? initialDisplayAddress;
  final VoidCallback? onClose;
  final VoidCallback? onHeaderTap;
  final String buttonText;
  final bool hideCloseButton;
  final bool showCloseButton;

  @override
  State<LocationSelectionStep> createState() => _LocationSelectionStepState();
}

class _LocationSelectionStepState extends State<LocationSelectionStep> {
  late TextEditingController _searchController;
  String? _selectedAddress;
  String? _selectedDisplayAddress;
  Geolocation? _selectedLocation;
  bool _isLocationSearchUsed = false;
  final MapRepository _mapRepository = getIt<MapRepository>();
  List<Place> _places = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  Timer? _debounce;
  String _sessionToken = '';
  String _selectedPlaceId = '';

  @override
  void initState() {
    super.initState();
    _selectedAddress = widget.initialAddress;
    _selectedDisplayAddress = widget.initialDisplayAddress;
    _selectedLocation = widget.initialLocation;
    _searchController = TextEditingController(
      text: widget.initialAddress ?? '',
    );
    _sessionToken = const Uuid().v4();
  }

  @override
  void didUpdateWidget(LocationSelectionStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLocation != oldWidget.initialLocation ||
        widget.initialAddress != oldWidget.initialAddress ||
        widget.initialDisplayAddress != oldWidget.initialDisplayAddress) {
      setState(() {
        _selectedLocation = widget.initialLocation;
        _selectedAddress = widget.initialAddress;
        _selectedDisplayAddress = widget.initialDisplayAddress;

        _isLocationSearchUsed = false;

        final newText = widget.initialAddress ?? '';
        if (_searchController.text != newText) {
          _searchController.text = newText;
        }

        if (widget.initialLocation != null) {
          _selectedPlaceId = '';
          _places = [];
          _hasSearched = false;
          _isLoading = false;
          _debounce?.cancel();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() => _selectedAddress = query);

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.isEmpty) {
      setState(() {
        _places = [];
        _isLoading = false;
        _hasSearched = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isLoading = true);
      try {
        //userın konumuna göre daha alakalı sonuçlar getirmek için proximity eklenebilir

        var results = <Place>[];
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          final position = await Geolocator.getCurrentPosition();
          final userLocation = Geolocation(
            latitude: position.latitude,
            longitude: position.longitude,
          );
          results = await _mapRepository.searchPlaces(
            query,
            _sessionToken,
            userLocation,
          );
        } else {
          results = await _mapRepository.searchPlaces(
            query,
            _sessionToken,
            null,
          );
        }

        if (mounted) {
          setState(() {
            _places = results;
            _isLoading = false;
            _hasSearched = true;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // 1. HEADER
        GestureDetector(
          onTap: widget.onHeaderTap,
          behavior: HitTestBehavior.opaque,
          child: _buildHeader(theme),
        ),

        SizedBox(height: 20.h),

        // 2. SEARCH AND LIST AREA
        SizedBox(
          height: 260.h,
          child: Column(
            children: [
              Container(
                height: 46.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14.sp,
                    color: AppColors.onBackgroundColor,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Konum ara...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14.sp,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.secondaryColor.withOpacity(0.6),
                      size: 22.sp,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),

              SizedBox(height: 12.h),

              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : (_places.isEmpty &&
                            _hasSearched &&
                            _searchController.text.isNotEmpty)
                      ? Center(
                          child: Text(
                            'Sonuç bulunamadı',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14.sp,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(
                            vertical: 12.h,
                            horizontal: 12.w,
                          ),
                          itemCount: _places.length,
                          separatorBuilder: (_, _) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Divider(
                              height: 1,
                              color: Colors.grey.shade200,
                            ),
                          ),
                          itemBuilder: (context, index) {
                            final place = _places[index];
                            final isSelected =
                                _selectedAddress == place.adresss;

                            return InkWell(
                              onTap: () async {
                                setState(() {
                                  _selectedAddress = place.adresss;
                                  _selectedPlaceId = place.id;
                                  _selectedDisplayAddress =
                                      place.displayAddress;

                                  _searchController.text = place.adresss;

                                  _isLocationSearchUsed = true;
                                });
                              },
                              borderRadius: BorderRadius.circular(8.r),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(6.w),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.secondaryColor
                                                .withOpacity(0.1)
                                          : Colors.grey.shade200,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.location_on_outlined,
                                      size: 16.sp,
                                      color: isSelected
                                          ? AppColors.onBackgroundColor
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        top: 2.h,
                                      ),
                                      child: Text(
                                        place.adresss,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontSize: 13.sp,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                              color: isSelected
                                                  ? AppColors.onBackgroundColor
                                                  : AppColors.onBackgroundColor
                                                        .withOpacity(0.7),
                                              height: 1.3,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // NEXT BUTTON
        PopupNextButton(
          text: widget.buttonText,
          onPressed: (_selectedAddress == null || _selectedAddress!.isEmpty)
              ? null
              : () async {
                  if (_selectedLocation == null &&
                      _selectedPlaceId.isNotEmpty) {
                    try {
                      setState(() => _isLoading = true);
                      _selectedLocation = await _mapRepository.getPlaceLocation(
                        _selectedPlaceId,
                        _sessionToken,
                      );
                      _sessionToken = const Uuid().v4();
                    } catch (e) {
                      // Hata yönetimi
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  }

                  if (_selectedLocation != null && _selectedAddress != null) {
                    final display =
                        _selectedDisplayAddress ?? _selectedAddress!;

                    getIt<LoggingService>().debug(
                      'Seçilen konum: $_selectedAddress, Lokasyon: $_selectedLocation',
                    );
                    widget.onNext(
                      _selectedAddress!,
                      display,
                      _selectedLocation!,
                      _isLocationSearchUsed,
                    );
                  }
                },
        ),

        SizedBox(height: 12.h),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: widget.onBack,
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.keyboard_backspace,
                size: 24.sp,
                color: AppColors.iconColor,
              ),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 22.sp,
              color: AppColors.iconColor,
            ),
            SizedBox(width: 6.w),
            Text(
              'Buluşma Konumu',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.onBackgroundColor,
              ),
            ),
          ],
        ),

        if (!widget.hideCloseButton && widget.showCloseButton)
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: widget.onClose ?? () {},
              child: Container(
                padding: EdgeInsets.all(8.w),
                child: Icon(
                  Icons.close,
                  size: 22.sp,
                  color: AppColors.iconColor,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
