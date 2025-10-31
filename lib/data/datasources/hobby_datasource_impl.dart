import 'package:bulusalim/domain/datasources/hobby_datasource.dart';
import 'package:bulusalim/domain/entities/hobby/index.dart';

class HobbyDataSourceImpl implements HobbyDataSource {
  const HobbyDataSourceImpl();

  static const _hobbies = <HobbyEntity>[];

  /// Tüm hobi kategorilerini döndürür.
  @override
  Future<List<HobbyEntity>> getHobbies() async {
    return _hobbies;
  }
}
