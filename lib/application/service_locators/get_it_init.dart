import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:outnest/application/service_locators/datasource_providers.dart';
import 'package:outnest/application/service_locators/firebase_providers.dart';
import 'package:outnest/application/service_locators/hive_providers.dart';
import 'package:outnest/application/service_locators/repository_providers.dart';
import 'package:outnest/application/service_locators/service_providers.dart';
import 'package:outnest/application/service_locators/usecase_providers.dart';

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
  getIt.registerSingleton<ValueNotifier<int>>(
    ValueNotifier(0),
    instanceName: 'homeScrollTrigger',
  );
}
