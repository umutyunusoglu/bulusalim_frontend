import 'package:outnest/application/providers/datasource_providers.dart';
import 'package:outnest/application/providers/firebase_providers.dart';
import 'package:outnest/application/providers/hive_providers.dart';
import 'package:outnest/application/providers/repository_providers.dart';
import 'package:outnest/application/providers/service_providers.dart';
import 'package:outnest/application/providers/usecase_providers.dart';
import 'package:get_it/get_it.dart';

final GetIt getIt = GetIt.instance;

Future<void> getItSetup() async {
  await getIt.registerHive();

  getIt
    ..registerFirebase()
    ..registerRepositories()
    ..registerServices()
    ..registerDatasources()
    ..registerUsecases();
  await getIt.allReady();
}
