import 'package:bulusalim/application/providers/get_it_init.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/domain/entities/user/user_entity.dart';
import 'package:bulusalim/domain/repositories/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    // GetIt'ten UserRepository'yi al
    final userRepository = getIt<UserRepository>();

    // 'getUser' metodunu çağır
    _userFuture = userRepository.getUser(widget.userID);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserEntity?>(
      future: _userFuture,
      builder: (context, snapshot) {
        // Veri Yükleniyorsa
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(
            '...',
            style: TextStyle(
              fontSize: 12.sp, // Responsive boyut
              color: Colors.grey,
            ),
          );
        }

        // Hata oluştuysa veya kullanıcı bulunamadıysa
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Text(
            'Bilinmeyen Kullanıcı',
            style: TextStyle(
              fontSize: 12.sp,
              color: Theme.of(context).colorScheme.error, // Tema hata rengi
              fontWeight: FontWeight.bold,
            ),
          );
        }

        // Başarılı
        final user = snapshot.data!;

        return widget.builder(user);
      },
    );
  }
}
