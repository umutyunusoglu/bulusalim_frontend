import 'dart:async';
import 'dart:convert';
import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/components/popup_next_button.dart';
import 'package:bulusalim/core/constants/theme/color_themes.dart';
import 'package:bulusalim/core/utils/logging/logging_service.dart';
import 'package:bulusalim/core/utils/types/geolocation/geolocation.dart';
import 'package:bulusalim/domain/repositories/map_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
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
    super.key,
  });

  final VoidCallback onBack;
  final Function(String, String, Geolocation) onNext;
  final Geolocation? initialLocation;
  final String? initialAddress;
  final String? initialDisplayAddress;
  final VoidCallback? onClose;
  final VoidCallback? onHeaderTap;

  @override
  State<LocationSelectionStep> createState() => _LocationSelectionStepState();
}

class _LocationSelectionStepState extends State<LocationSelectionStep> {
  late TextEditingController _searchController;
  String? _selectedAddress;
  String? _selectedDisplayAddress;
  Geolocation? _selectedLocation;

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

        final newText = widget.initialAddress ?? '';
        if (_searchController.text != newText) {
          _searchController.text = newText;
        }

        // If location is provided directly (e.g. Map Pick), we don't need to fetch by ID
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
        final results = await _mapRepository.searchPlaces(query, _sessionToken);

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

        // 2. ARAMA VE LİSTE ALANI
        SizedBox(
          height: 260.h,
          child: Column(
            children: [
              // A. ARAMA KUTUSU
              Container(
                height: 46.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  // Border Rengi: Odaklanınca Mavi, Değilse Gri
                  border: Border.all(
                    color: _isFocused
                        ? AppColors.secondaryColor
                        : Colors.grey.shade200,
                    width: _isFocused ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                // ÖNEMLİ DÜZELTME: ClipRRect eklendi
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    12.r,
                  ), // Container ile aynı radius
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14.sp,
                      color: AppColors.onBackgroundColor,
                      fontWeight: FontWeight.w500,
                    ),
                    cursorColor: AppColors.secondaryColor,
                    decoration: InputDecoration(
                      hintText: 'Konum ara...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14.sp,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: _isFocused
                            ? AppColors.secondaryColor
                            : AppColors.secondaryColor.withOpacity(0.6),
                        size: 22.sp,
                      ),
                      // TextField'ın kendi borderlarını kapattık (Container kontrol ediyor)
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    onChanged: (val) => setState(() => _selectedLocation = val),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),

              SizedBox(height: 12.h),

              // B. Liste Alanı
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
                          separatorBuilder: (_, __) => Padding(
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
                                });
                              },
                              borderRadius: BorderRadius.circular(8.r),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Konum İkonu (Yuvarlak arka planlı)
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

                                  // Konum Metni
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

        PopupNextButton(
          text: 'ilerle',
          onPressed: (_selectedAddress == null || _selectedAddress!.isEmpty)
              ? null
              : () async {
                  // 1. If we don't have a location but have a placeId (from search), fetch it.
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
                      // Handle error silently or show snackbar
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  }

                  // 2. Validate and Proceed
                  if (_selectedLocation != null && _selectedAddress != null) {
                    final display =
                        _selectedDisplayAddress ?? _selectedAddress!;

                    final logger = getIt<LoggingService>();
                    logger.debug(
                      'Seçilen konum: $_selectedAddress, Lokasyon: $_selectedLocation',
                    );
                    widget.onNext(
                      _selectedAddress!,
                      display,
                      _selectedLocation!,
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
              child: Icon(Icons.undo, size: 22.sp, color: AppColors.iconColor),
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
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: widget.onClose ?? () {},
            child: Container(
              padding: EdgeInsets.all(8.w),
              child: Icon(Icons.close, size: 22.sp, color: AppColors.iconColor),
            ),
          ),
        ),
      ],
    );
  }
}
