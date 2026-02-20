enum CreateEventStepEnum {
  category._('category'),
  location._('location'),
  time._('time'),
  visibility._('visibility'),
  name._('name'),
  summary._('summary');

  const CreateEventStepEnum._(this.value);
  final String value;

  @override
  String toString() => value;

  static CreateEventStepEnum fromString(String value) {
    switch (value) {
      case 'category':
        return category;
      case 'location':
        return location;
      case 'time':
        return time;
      case 'visibility':
        return visibility;
      case 'name':
        return name;
      case 'summary':
        return summary;
      default:
        throw ArgumentError('Unknown create event step: $value');
    }
  }
}
