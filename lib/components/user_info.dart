import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/user/user_entity.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:flutter/material.dart';

class UserInfo extends StatefulWidget {
  const UserInfo({
    required this.userID,
    required this.builder,
    super.key,
  });

  final Identifier userID;
  final Widget Function(UserEntity user) builder;

  @override
  State<UserInfo> createState() => _UserInfoState();
}

class _UserInfoState extends State<UserInfo> {
  Future<UserEntity?>? _userFuture;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  @override
  void didUpdateWidget(covariant UserInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userID != widget.userID) {
      _fetchUser();
    }
  }

  void _fetchUser() {
    // Repository çağrısı
    _userFuture = getIt<UserRepository>().getUser(widget.userID);
  }

  @override
  Widget build(BuildContext context) {
    // Tema Bağlantısı
    final theme = Theme.of(context);

    // Yükleniyor/Hata durumları için ortak küçük stil (12px Urbanist)
    final placeholderStyle = theme.textTheme.bodySmall?.copyWith(
      fontFamily: 'Urbanist',
      fontSize: 12,
      color: Colors.grey.shade500,
    );

    return FutureBuilder<UserEntity?>(
      future: _userFuture,
      builder: (context, snapshot) {
        // 1. Yükleniyor
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(
            '...',
            style: placeholderStyle,
          );
        }

        // 2. Hata veya Boş Veri
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Text(
            'Bilinmeyen Kullanıcı',
            style: placeholderStyle?.copyWith(
              color: theme.colorScheme.error, // Temadan hata rengi (Kırmızı)
              fontWeight: FontWeight.w600,
            ),
          );
        }

        // 3. Başarılı
        final user = snapshot.data!;
        return widget.builder(user);
      },
    );
  }
}
