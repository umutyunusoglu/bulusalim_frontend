import 'dart:io';

import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/domain/entities/feed/event/event_entity.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/repositories/event_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:outnest/domain/services/file_service.dart';

// --- UI VERİ MODELİ ---
class ParticipantItem {
  ParticipantItem({
    required this.userId,
    required this.username,
    required this.imageUrl,
    required this.status,
    required this.university,
    this.requestTime,
  });

  final String userId;
  final String username;
  final String imageUrl;
  final String status;
  final DateTime? requestTime;
  final String? university;

  // Zaman farkı hesaplayıcı
  String get timeAgo {
    if (requestTime == null) return '';
    final diff = DateTime.now().difference(requestTime!);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}dk';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}sa';
    } else {
      return '${diff.inDays}gn';
    }
  }
}

class EventStatusAccordion extends StatefulWidget {
  const EventStatusAccordion({
    required this.event,
    required this.pendingCount,
    super.key,
  });

  final EventEntity event;
  final int pendingCount;

  @override
  State<EventStatusAccordion> createState() => _EventStatusAccordionState();
}

class _EventStatusAccordionState extends State<EventStatusAccordion> {
  bool _isLoading = false;
  bool _dataLoaded = false;
  final bool _isExpanded = false; // Accordion durumu takibi için

  List<ParticipantItem> _pendingUsers = [];
  List<ParticipantItem> _approvedUsers = [];
  final EventRepository _eventRepository = getIt<EventRepository>();

  // --- VERİ ÇEKME ---
  Future<void> _fetchParticipants() async {
    if (_dataLoaded || _isLoading) return;
    if (!mounted) return;

    setState(() => _isLoading = true);

    final loadedParticipants = <ParticipantItem>[];

    for (final participant in widget.event.participants) {
      try {
        final ParticipantItem userItem = ParticipantItem(
          userId: participant.userID,
          username: participant.username,
          imageUrl: participant.profileImageUrl,
          status: 'approved',
          university: participant.university,
        );
        loadedParticipants.add(userItem);
      } catch (e) {
        debugPrint('User fetch error: $e');
      }
    }

    final pendingParticipants = <ParticipantItem>[];

    for (final request in widget.event.requestPool) {
      try {
        final ParticipantItem userItem = ParticipantItem(
          userId: request.userID,
          username: request.username,
          imageUrl: request.profileImageUrl,
          status: 'pending',
          university: request.university,
        );
        pendingParticipants.add(userItem);
      } catch (e) {
        debugPrint('Pending user fetch error: $e');
      }
    }

    if (!mounted) return;

    try {
      setState(() {
        _pendingUsers = pendingParticipants.toList();

        _approvedUsers = loadedParticipants.toList();

        _dataLoaded = true;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Hata: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- İŞLEM YÖNETİMİ ---
  Future<void> _handleRequest(String userId, bool isAccepted) async {
    // Optimistic UI Update
    final int userIndex = _pendingUsers.indexWhere((u) => u.userId == userId);
    if (userIndex == -1) return;

    final user = _pendingUsers[userIndex];

    setState(() {
      _pendingUsers.removeAt(userIndex);
      if (isAccepted) {
        _approvedUsers.add(
          ParticipantItem(
            userId: user.userId,
            username: user.username,
            imageUrl: user.imageUrl,
            status: 'approved',
            requestTime: user.requestTime,
            university: user.university,
          ),
        );
      }
    });
    final compactUser = CompactUserEntity(
      userID: user.userId,
      username: user.username,
      profileImageUrl: user.imageUrl,
      university: user.university,
    );

    try {
      if (isAccepted) {
        await _eventRepository.acceptParticipant(
          widget.event.eventID,
          compactUser,
        );
      } else {
        await _eventRepository.rejectRequest(
          widget.event.eventID,
          compactUser,
        );
      }
    } catch (e) {
      debugPrint('Update error: $e');
    }
  }

  // Onaylı kullanıcıyı kaldırma (Opsiyonel)
  Future<void> _removeParticipant(String userId) async {
    final user = _approvedUsers.firstWhere(
      (u) => u.userId == userId,
      orElse: () => ParticipantItem(
        userId: '',
        username: '',
        imageUrl: '',
        status: '',
        university: '',
      ),
    );
    setState(() {
      _approvedUsers.removeWhere((u) => u.userId == userId);
    });

    try {
      final compactUser = CompactUserEntity(
        userID: user.userId,
        username: user.username,
        profileImageUrl: user.imageUrl,
        university: user.university,
      );

      await _eventRepository.removeParticipant(
        widget.event.eventID,
        compactUser,
      );
    } catch (e) {
      debugPrint("Remove error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      decoration: BoxDecoration(
        color: AppColors.accordionBackground, // Açık mavi/gri zemin
        borderRadius: BorderRadius.circular(16.r),
        // Tasarımdaki gibi hafif border eklenebilir
        border: Border.all(color: Colors.transparent),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, // Varsayılan çizgiyi kaldır
          splashColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          childrenPadding: EdgeInsets.only(bottom: 12.h),
          iconColor: Colors.black87,
          collapsedIconColor: Colors.black87,
          onExpansionChanged: (expanded) {
            if (expanded) _fetchParticipants();
          },
          title: Row(
            children: [
              Expanded(
                child: Text(
                  'Bekleyen İstekler ve Onaylı Katılımcılar',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              // Kırmızı Bildirim Rozeti (Sadece sayı varsa)
              if (widget.pendingCount > 0) ...[
                SizedBox(width: 8.w),
                Container(
                  width: 20.w,
                  height: 20.w,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryColor, // Turuncu/Pembe renk
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    widget.pendingCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator(strokeWidth: 2))
            else
              Column(
                children: [
                  // 1. BEKLEYENLER LİSTESİ
                  ..._pendingUsers.map((u) => _buildPendingRow(u)),

                  // 2. ONAYLANANLAR LİSTESİ
                  ..._approvedUsers.map((u) => _buildApprovedRow(u)),

                  // BOŞ DURUM
                  if (_pendingUsers.isEmpty && _approvedUsers.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Text(
                        "Henüz katılımcı yok.",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12.sp,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // --- BEKLEYEN SATIRI (YEŞİL TİK / GRİ ÇARPI) ---
  Widget _buildPendingRow(ParticipantItem user) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          // Avatar
          _buildAvatar(user.imageUrl),
          SizedBox(width: 12.w),

          // İsim ve Zaman
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    user.username,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (user.timeAgo.isNotEmpty) ...[
                  SizedBox(width: 6.w),
                  Text(
                    user.timeAgo,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 11.sp,
                      color: Colors.grey.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // BUTONLAR: Yeşil Tik ve Gri Çarpı
          Row(
            children: [
              // Kabul Et (Yeşil Dolu Daire)
              GestureDetector(
                onTap: () => _handleRequest(user.userId, true),
                child: Container(
                  width: 26.w,
                  height: 26.w,
                  decoration: const BoxDecoration(
                    color: AppColors.successGreen, // Yeşil
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: Colors.white, size: 16.sp),
                ),
              ),
              SizedBox(width: 12.w),
              // Reddet (Gri Dolu Daire)
              GestureDetector(
                onTap: () => _handleRequest(user.userId, false),
                child: Container(
                  width: 26.w,
                  height: 26.w,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400, // Gri
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 16.sp),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- ONAYLI SATIRI (PEMBE EKSİ) ---
  Widget _buildApprovedRow(ParticipantItem user) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          _buildAvatar(user.imageUrl),
          SizedBox(width: 12.w),

          Expanded(
            child: Text(
              user.username,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 14.sp,
                fontWeight:
                    FontWeight.w500, // Onaylılar biraz daha ince olabilir
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // BUTON: Kaldır (Açık Pembe Zemin, Koyu Pembe İkon)
          GestureDetector(
            onTap: () => _removeParticipant(user.userId),
            child: Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.3), // Açık pembe
                shape: BoxShape.circle,
              ),
              // Icon olarak 'remove' (tire) kullanıyoruz
              child: Icon(
                Icons.remove,
                size: 14.sp,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String url) {
    // URL'nin geçerli olup olmadığını kontrol et
    final bool hasValidUrl = url.isNotEmpty && url.startsWith('http');

    return Container(
      width: 36.w,
      height: 36.w,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ClipOval(
        child: hasValidUrl
            ? CachedNetworkImage(
                imageUrl: fixEmulatorUrl(url),
                fadeInDuration: Duration.zero,
                fit: BoxFit.cover,
                memCacheHeight: 100,
                memCacheWidth: 100,
                placeholder: (c, u) => Container(color: AppColors.lightCloud),
                errorWidget: (c, u, e) => Image.asset(
                  FileService.defaultProfileImageUrl(), // Fallback resmi
                  fit: BoxFit.cover,
                ),
              )
            : Image.asset(
                FileService.defaultProfileImageUrl(),
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}
