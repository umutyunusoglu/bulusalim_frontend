abstract class Model<T> {
  Model();

  factory Model.fromEntity() {
    // factory constructor body cannot be empty in abstract class
    // Abstract class factories usually throw or return a concrete subclass
    throw UnimplementedError();
  }

  factory Model.fromFirestore() {
    // Abstract class cannot instantiate directly
    throw UnimplementedError();
  }
  T toEntity();

  Map<String, dynamic> toFirestore();
}
