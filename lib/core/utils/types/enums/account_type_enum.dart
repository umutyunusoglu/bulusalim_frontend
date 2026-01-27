enum AccountType {
  personal._('personal'),
  community._('community');

  const AccountType._(this.value);

  final String value;

  @override
  String toString() => value;

  static AccountType fromString(String value) {
    switch (value) {
      case 'personal':
        return personal;
      case 'community':
        return community;
      default:
        throw Exception('Unknown emote: $value');
    }
  }
}
