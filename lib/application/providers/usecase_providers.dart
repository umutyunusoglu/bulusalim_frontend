import 'package:outnest/domain/usecases/force_start_event_usecase.dart';
import 'package:outnest/domain/usecases/force_stop_event_usecase.dart';
import 'package:outnest/domain/usecases/upload_post_usecase.dart';
import 'package:outnest/domain/usecases/upload_profile_picture_usecase.dart';
import 'package:get_it/get_it.dart';

extension UseCaseModule on GetIt {
  void registerUsecases() {
    this
      ..registerLazySingleton<UploadPost>(
        () => UploadPost(
          fileService: this(),
          postRepository: this(),
          sessionService: this(),
          logger: this(),
        ),
      )
      ..registerLazySingleton<ForceStartEvent>(
        () => ForceStartEvent(
          logger: this(),
          eventRepository: this(),
          userRepository: this(),
        ),
      )
      ..registerLazySingleton<ForceStopEvent>(
        () => ForceStopEvent(
          logger: this(),
          eventRepository: this(),
          userRepository: this(),
        ),
      )
      ..registerLazySingleton<UploadProfilePicture>(
        () => UploadProfilePicture(
          fileService: this(),
          loggingService: this(),
        ),
      );
  }
}
