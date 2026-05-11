import 'package:equatable/equatable.dart';

class OrganizationEntity extends Equatable {
  const OrganizationEntity({
    required this.name,
    required this.mailExtension,
    this.similarDomains = const [],
  });

  final String name;
  final List<String> mailExtension;
  final List<String> similarDomains;

  @override
  List<Object?> get props => [name, mailExtension, similarDomains];
}
