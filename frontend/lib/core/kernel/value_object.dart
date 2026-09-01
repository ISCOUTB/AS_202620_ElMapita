// lib/core/kernel/value_object.dart

abstract class ValueObject {
  const ValueObject();

  List<Object?> get props;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValueObject && runtimeType == other.runtimeType && props == other.props;

  @override
  int get hashCode => Object.hashAll(props);
}
