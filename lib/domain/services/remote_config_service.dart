abstract class RemoteConfigService {
  Future<void> init();
  Future<T> getValue<T>(String key);
}
