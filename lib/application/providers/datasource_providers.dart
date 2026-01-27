import 'package:outnest/data/datasources/university_datasource_impl.dart';
import 'package:outnest/domain/datasources/university_datasource.dart';
import 'package:get_it/get_it.dart';

extension RepositoryModule on GetIt {
  void registerDatasources() {
    this.registerLazySingleton<UniversityDatasource>(
      () => UniversityDataSourceImpl(
        logger: this(),
      ),
    );
  }
}
