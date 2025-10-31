import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/domain/entities/user/index.dart';
import 'package:bulusalim/domain/entities/user/user_entity.dart';
import 'package:bulusalim/domain/entities/user/user_event_entity.dart';
import 'package:bulusalim/domain/entities/user/user_hobby_entity.dart';

abstract class UserRepository {
  // === User CRUD ===
  Future<UserEntity?> getUser(Identifier userID);
  Future<void> createUser(Identifier userID, UserEntity user);
  Future<void> updateUser(
    Identifier userID,
    Map<String, dynamic> updates,
  );
  Future<void> deleteUser(Identifier userID);

  // === Hobbies Subcollection ===
  Future<void> addHobby(
    Identifier userID,
    UserHobbyEntity hobby,
  );
  Future<void> updateHobby(
    Identifier userID,
    String hobbyName,
    Map<String, dynamic> updates,
  );
  Future<void> deleteHobby(
    Identifier userID,
    String hobbyName,
  );

  Future<List<UserHobbyEntity>> getUserHobbies(
    Identifier userID,
  );

  // === Events Subcollection ===
  Future<void> addEvent(
    Identifier userID,
    UserEventEntity event,
  );
  Future<List<UserEventEntity>> getUserEvents(
    Identifier userID,
  );
  Future<void> deleteEvent(
    Identifier userID,
    Identifier eventID,
  );

  // === Query & Search ===
  Future<List<UserEntity>> searchUsersByName(String name);
  Future<List<UserEntity>> getUsersByOrg(String org);
}
