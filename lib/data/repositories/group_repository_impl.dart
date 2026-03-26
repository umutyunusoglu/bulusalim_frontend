import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/utils/types/types.dart';
import 'package:outnest/domain/entities/user/compact_user_entity.dart';
import 'package:outnest/domain/repositories/group_repository.dart';
import 'package:outnest/domain/services/session_service.dart';
// Kendi importlarını buraya ekle (GroupRepository, getIt, SessionService, CompactUserEntity, Identifier vb.)

class GroupRepositoryImpl implements GroupRepository {
  final FirebaseFirestore _firestore = getIt<FirebaseFirestore>();

  // Ortak Group ID üretme ve Session kontrol fonksiyonu
  String _generateGroupId(String groupName) {
    final sessionService = getIt<SessionService>();
    final myUserId = sessionService.currentUser?.userID;

    if (myUserId == null) {
      throw Exception('Aktif bir kullanıcı oturumu bulunamadı.');
    }

    return '$myUserId-$groupName';
  }

  @override
  Future<void> createGroup(
    String groupName,
    List<CompactUserEntity> initialMembers,
  ) async {
    final groupIdStr = _generateGroupId(groupName);
    final groupRef = _firestore.collection('groups').doc(groupIdStr);

    // Aynı isimde grup varsa işlemin ezilmesini engelliyoruz
    final docSnapshot = await groupRef.get();
    if (docSnapshot.exists) {
      throw Exception('Bu isimde bir grubunuz zaten mevcut.');
    }

    final batch = _firestore.batch();

    final sessionService = getIt<SessionService>();
    final myUserId = sessionService.currentUser?.userID;

    // Grubun ana metadatasını kaydet
    batch.set(groupRef, {
      'ownerID': myUserId.toString(),
      'name': groupName,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Başlangıç üyelerini alt koleksiyona (members) batch ile ekle
    for (final member in initialMembers) {
      final memberRef = groupRef.collection('members').doc(member.userID);
      batch.set(memberRef, member.toMap());
    }

    await batch.commit();
  }

  @override
  Future<void> addGroupMemberToMyGroup(
    String groupName,
    CompactUserEntity newMember,
  ) async {
    final String groupIdStr = _generateGroupId(groupName);

    final memberRef = _firestore
        .collection('groups')
        .doc(groupIdStr)
        .collection('members')
        .doc(newMember.userID);

    await memberRef.set(newMember.toMap());
  }

  @override
  Future<void> removeGroupMemberToMyGroup(
    String groupName,
    Identifier memberID,
  ) async {
    final String groupIdStr = _generateGroupId(groupName);

    final memberRef = _firestore
        .collection('groups')
        .doc(groupIdStr)
        .collection('members')
        .doc(memberID);

    await memberRef.delete();
  }

  @override
  Future<void> deleteGroup(String groupName) async {
    final groupIdStr = _generateGroupId(groupName);

    final groupRef = _firestore.collection('groups').doc(groupIdStr);
    final membersRef = groupRef.collection('members');

    final membersSnapshot = await membersRef.get();
    final batch = _firestore.batch();

    for (final doc in membersSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Ardından asıl grubu siliyoruz
    batch.delete(groupRef);

    await batch.commit();
  }

  @override
  Future<List<String>> getMyGroups() async {
    final sessionService = getIt<SessionService>();
    final userID = sessionService.currentUser?.userID;

    final groupsSnapshot = await _firestore
        .collection('groups')
        .where('ownerID', isEqualTo: userID)
        .get();

    return groupsSnapshot.docs.map((doc) => doc['name'] as String).toList();
  }

  @override
  Future<List<CompactUserEntity>> getMembersOfMyGroup(String groupName) async {
    final groupIdStr = _generateGroupId(groupName);

    final snapshot = await _firestore
        .collection('groups')
        .doc(groupIdStr)
        .collection('members')
        .get();

    return snapshot.docs.map((doc) {
      return CompactUserEntity.fromMap(doc.data());
    }).toList();
  }

  @override
  Future<bool> isGroupMember(String groupID, Identifier userIDToCheck) async {
    final memberRef = _firestore
        .collection('groups')
        .doc(groupID)
        .collection('members')
        .doc(userIDToCheck);

    final docSnapshot = await memberRef.get();

    return docSnapshot.exists;
  }
}
