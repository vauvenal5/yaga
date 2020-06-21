abstract class Service<T extends Service<T>> {
  Future<T> init() async => this;
}