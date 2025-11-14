import 'package:flutter/material.dart';
import 'package:bulusalim/application/providers/getIt_init.dart';
import 'package:bulusalim/domain/entities/user/user_entity.dart';
import 'package:bulusalim/domain/repositories/user_repository.dart';
import 'package:bulusalim/core/utils/types/types.dart';

class UserInfo extends StatefulWidget {
  final Identifier userID;
  final Widget Function(UserEntity user) builder;

  const UserInfo({
    super.key,
    required this.userID,
    required this.builder,
  });

  @override
  State<UserInfo> createState() => _UserInfoState();
}

class _UserInfoState extends State<UserInfo> {
  Future<UserEntity?>? _userFuture;

  @override
  void initState() {
    super.initState();
    //GetIt'ten UserRepository'yi al

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
          return const Text(
            "...",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          );
        }

        // Hata oluştuysa veya kullanıcı bulunamadıysa
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const Text(
            "Bilinmeyen Kullanıcı",
            style: TextStyle(
              fontSize: 12,
              color: Colors.red,
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
