abstract class RemoteConfigService {
  Future<T> getValue<T>(String key);
}
