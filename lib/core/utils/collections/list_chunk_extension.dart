// core/utils/collections/list_chunk_extension.dart

extension ListChunkExtension<T> on List<T> {
  /// Splits the list into consecutive sub-lists of at most [size] elements.
  ///
  /// The last chunk may be smaller. Returns an empty list if this list is
  /// empty. Throws [ArgumentError] if [size] is not positive.
  List<List<T>> chunked(int size) {
    if (size <= 0) {
      throw ArgumentError.value(size, 'size', 'must be greater than zero');
    }
    return List.generate(
      (length / size).ceil(),
      (i) =>
          sublist(i * size, (i + 1) * size > length ? length : (i + 1) * size),
    );
  }
}
