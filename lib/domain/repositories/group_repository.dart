import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';

abstract class GroupRepository {
  /// Creates a new group and adds the initial members.
  /// The group ID must be provided according to the unique ID format used when creating the group.
  Future<void> createGroup(
    String groupName,
    List<CompactUserEntity> initialMembers,
  );

  /// Adds a new member to an existing group.
  /// The function must be called by the group owner.
  Future<void> addGroupMemberToMyGroup(
    String groupName,
    CompactUserEntity newMember,
  );

  /// Removes a member from an existing group.
  /// The function must be called by the group owner.
  Future<void> removeGroupMemberToMyGroup(
    String groupName,
    Identifier memberID,
  );

  /// Deletes a group and all the members inside it.
  Future<void> deleteGroup(String groupName);

  /// Gets all the groups belonging to the current user.
  Future<List<String>> getMyGroups();

  /// Gets all members of the specified group.
  /// The function must be called by the group owner.
  Future<List<CompactUserEntity>> getMembersOfMyGroup(String groupName);

  /// Checks whether a specific user is in this group with an O(1) cost.
  /// The group ID must be provided according to the unique ID format used when creating the group.
  /// The function can be called by everyone, it can be used to check the status of whether someone is a group member or not.
  Future<bool> isGroupMember(
    String groupID,
    Identifier userIDToCheck,
  );
}
