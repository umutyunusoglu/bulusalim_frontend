import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';

abstract class GroupRepository {
  /// Yeni bir grup oluşturur ve başlangıç üyelerini ekler.
  /// Grup ID'si, grup oluşturulurken kullanılan benzersiz ID formatına göre sağlanmalıdır.
  Future<void> createGroup(
    String groupName,
    List<CompactUserEntity> initialMembers,
  );

  /// Var olan bir gruba yeni bir üye ekler.
  /// Fonkiyon grup sahibi tarafından çağrılmalıdır.
  Future<void> addGroupMember(
    String groupName,
    CompactUserEntity newMember,
  );

  /// Var olan bir gruptan bir üyeyi çıkarır.
  /// Fonkiyon grup sahibi tarafından çağrılmalıdır.
  Future<void> removeGroupMember(
    String groupName,
    Identifier memberID,
  );

  /// Bir grubu ve içindeki tüm üyeleri siler.
  Future<void> deleteGroup(String groupName);

  /// Belirtilen grubun tüm üyelerini getirir.
  /// Fonkiyon grup sahibi tarafından çağrılmalıdır.
  Future<List<CompactUserEntity>> getGroupMembers(String groupName);

  /// Belirli bir kullanıcının bu grupta olup olmadığını O(1) maliyetle kontrol eder.
  /// Grup ID'si, grup oluşturulurken kullanılan benzersiz ID formatına göre sağlanmalıdır.
  /// Fonksiyon herkes tarafından çağrılabilir, grup üyesi olup olmama durumunu kontrol etmek için kullanılabilir.
  Future<bool> isGroupMember(
    String groupName,
    Identifier userIDToCheck,
  );
}
