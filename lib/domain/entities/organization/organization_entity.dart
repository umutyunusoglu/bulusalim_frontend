import 'package:equatable/equatable.dart';

class OrganizationEntity extends Equatable {
  const OrganizationEntity({required this.name, required this.mailExtension});
  final String name;
  final List<String> mailExtension;

  @override
  List<Object?> get props => [name, mailExtension];
}
