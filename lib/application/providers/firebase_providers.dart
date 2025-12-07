import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';

extension FirebaseModule on GetIt {
  void registerFirebase() {
    this
      ..registerLazySingleton<FirebaseFirestore>(
        () => FirebaseFirestore.instance,
      )
      ..registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance)
      ..registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance)
      ..registerLazySingleton<FirebaseRemoteConfig>(
        () => FirebaseRemoteConfig.instance,
      );
  }
}
