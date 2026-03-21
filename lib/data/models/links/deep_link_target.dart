enum DeepLinkType { profile, post, event, unknown }

class DeepLinkTarget {
  final DeepLinkType type;
  final String? id;

  DeepLinkTarget({
    required this.type,
    this.id,
  });

  const DeepLinkTarget.unknown() : type = DeepLinkType.unknown, id = null;
}
