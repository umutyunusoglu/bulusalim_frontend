import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:outnest/data/repositories/search_repository_impl.dart';
import 'package:outnest/domain/repositories/search_repository.dart';

final Provider<SearchRepository> searchRepositoryProvider = Provider(
  (ref) => SearchRepositoryImpl(),
);
