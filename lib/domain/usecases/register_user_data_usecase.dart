import 'dart:io';

import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/domain/entities/user/index.dart';
import 'package:bulusalim/domain/repositories/user_repository.dart';
import 'package:bulusalim/domain/usecases/upload_user_photos_usecase.dart';

class RegisterUserData {
  RegisterUserData({
    required UserRepository userRepository,
    required UploadUserPhotos uploadUserPhotos,
  }) : _userRepository = userRepository,
       _uploadUserPhotos = uploadUserPhotos;

  final UserRepository _userRepository;
  final UploadUserPhotos _uploadUserPhotos;

  Future<void> call(
    Identifier userID,
    UserEntity user,
    List<File> newPhotos,
  ) async {
    final photoUrls = await _uploadUserPhotos(
      newPhotos,
      userID,
    );

    return _userRepository.createUser(
      userID,
      user.copyWith(
        profileImageUrl: photoUrls[0], //TODO
      ),
    );
  }
}
