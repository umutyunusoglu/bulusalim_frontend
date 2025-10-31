import 'package:bulusalim/domain/usecases/register_user_data_usecase.dart';
import 'package:bulusalim/domain/usecases/upload_user_photos_usecase.dart';
import 'package:get_it/get_it.dart';

extension UseCaseModule on GetIt {
  void registerUsecases() {
    this
      ..registerSingleton<UploadUserPhotos>(
        UploadUserPhotos(
          fileService: this(),
          logger: this(),
        ),
      )
      ..registerSingleton<RegisterUserData>(
        RegisterUserData(
          userRepository: this(),
          uploadUserPhotos: this(),
        ),
      );
  }
}
