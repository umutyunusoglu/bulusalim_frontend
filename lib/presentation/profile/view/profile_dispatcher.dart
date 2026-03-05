import 'package:flutter/material.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/enums/account_type_enum.dart';
import 'package:outnest/domain/entities/user/user_entity.dart'; // accountType'ı okumak için tam modeli import ediyoruz
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/session_service.dart';
import 'package:outnest/presentation/profile/view/community_profile_page.dart';
import 'package:outnest/presentation/profile/view/profile_page.dart';

class ProfileDispatcher extends StatefulWidget {
  const ProfileDispatcher({required this.profileUserID, super.key});
  final String profileUserID;

  @override
  State<ProfileDispatcher> createState() => _ProfileDispatcherState();
}

class _ProfileDispatcherState extends State<ProfileDispatcher> {
  bool _isLoading = true;
  AccountType _accountType = AccountType.personal;
  final LoggingService _logger = getIt<LoggingService>();

  @override
  void initState() {
    super.initState();
    _checkAccountType();
  }

  Future<void> _checkAccountType() async {
    try {
      final sessionService = getIt<SessionService>();
      final userRepository = getIt<UserRepository>();

      // 1. DURUM: Girdiğimiz profil KENDİ profilimiz mi?
      if (widget.profileUserID == sessionService.currentUser?.userID) {
        _accountType =
            sessionService.currentUser?.accountType ?? AccountType.personal;
        _logger.info('DISPATCHER: Kendi profilim. Tür: $_accountType');
      }
      // 2. DURUM: Girdiğimiz profil BAŞKASININ profili mi?
      else {
        final user = await userRepository.getUserPublicData(
          widget.profileUserID,
        );

        _accountType = user?.accountType ?? AccountType.personal;

        _logger.info('DISPATCHER: Başkasının profili. Tür: $_accountType');
      }
    } catch (e) {
      // Herhangi bir yetki veya çekme hatası olursa uygulamayı çökertmemek için personal'a düşür
      _logger.error('Profile DISPATCHER HATASI (Hesap türü okunamadı): $e');
      _accountType = AccountType.personal;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Veri çekilirken beyaz bir bekleme ekranı
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // YÖNLENDİRME ZAMANI
    if (_accountType == AccountType.community) {
      return CommunityProfilePage(profileUserID: widget.profileUserID);
    } else {
      return ProfilePage(profileUserID: widget.profileUserID);
    }
  }
}
