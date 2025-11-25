enum EmoteEnum {
  heart._('heart'),
  clap._('clap'),
  egg._('egg');

  const EmoteEnum._(this.value);

  final String value;

  @override
  String toString() => value;

  static EmoteEnum fromString(String value) {
    switch (value) {
      case 'heart':
        return heart;
      case 'clap':
        return clap;
      case 'egg':
        return egg;
      default:
        throw Exception('Unknown emote: $value');
    }
  }
}
