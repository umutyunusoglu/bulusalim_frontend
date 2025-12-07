import 'package:bulusalim/application/providers/firebase_providers.dart';
import 'package:bulusalim/application/providers/repository_providers.dart';
import 'package:bulusalim/application/providers/service_providers.dart';
import 'package:bulusalim/application/providers/usecase_providers.dart';
import 'package:get_it/get_it.dart';

final GetIt getIt = GetIt.instance;

Future<void> getItSetup() async {
  getIt
    ..registerFirebase()
    ..registerServices()
    ..registerRepositories()
    ..registerUsecases();

  await getIt.allReady();
}
