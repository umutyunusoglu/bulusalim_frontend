import 'package:bulusalim/domain/usecases/upload_post_usecase.dart';
import 'package:get_it/get_it.dart';

extension UseCaseModule on GetIt {
  void registerUsecases() {
    this.registerLazySingleton<UploadPost>(
      () => UploadPost(
        fileService: this(),
        postRepository: this(),
        sessionService: this(),
        logger: this(),
      ),
    );
  }
}
