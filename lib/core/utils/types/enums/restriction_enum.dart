enum RestrictionEnum {
  prohibited._('prohibited'),
  allowed._('allowed'),
  preferred._('preferred'),
  required._('required');

  const RestrictionEnum._(this.value);
  final String value;

  @override
  String toString() {
    switch (this) {
      case RestrictionEnum.prohibited:
        return 'Prohibited';
      case RestrictionEnum.allowed:
        return 'Allowed';
      case RestrictionEnum.preferred:
        return 'Preferred';
      case RestrictionEnum.required:
        return 'Required';
    }
  }
}
