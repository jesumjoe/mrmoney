import 'package:hive/hive.dart';

abstract class BaseRepository<T extends HiveObject> {
  Box<T> box;

  BaseRepository(this.box);

  Future<void> add(T item) async {
    await box.add(item);
  }

  Future<void> update(dynamic key, T item) async {
    await box.put(key, item);
  }

  Future<void> delete(dynamic key) async {
    await box.delete(key);
  }

  List<T> getAll() {
    return box.values.toList();
  }

  T? get(dynamic key) {
    return box.get(key);
  }

  Future<void> clear() async {
    await box.clear();
  }
}
