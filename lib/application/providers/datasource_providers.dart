import 'package:bulusalim/data/datasources/university_datasource_impl.dart';
import 'package:bulusalim/domain/datasources/university_datasource.dart';
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
