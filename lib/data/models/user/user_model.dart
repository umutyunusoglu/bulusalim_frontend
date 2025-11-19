import 'package:bulusalim/core/constants/Configs/app_config.dart';
// GenderEnum importunun doğru olduğundan emin ol
import 'package:bulusalim/core/utils/types/enums/gender_enum.dart';
import 'package:bulusalim/core/utils/types/types.dart';
import 'package:bulusalim/data/models/model.dart';
import 'package:bulusalim/domain/entities/user/user_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserModel extends Model<UserEntity> {
  UserModel({
    required this.userID,
    required this.username,
    required this.email,
    required this.birthDate,
    required this.gender,
    required this.organization,
    required this.profileImageUrl,
    required this.bio,
    required this.permissions,
    required this.createdAt,
    required this.updatedAt,
    required this.lastActiveAt,
  });

  @override
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      userID: entity.userID,
      email: entity.email,
      username: entity.username,
      birthDate: entity.birthDate,
      gender: entity.gender,
      organization: entity.organization,
      profileImageUrl: entity.profileImageUrl,
      bio: entity.bio,
      permissions: entity.permissions,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      lastActiveAt: entity.lastActiveAt,
    );
  }

  /// -----------------------------------------------------------------
  /// GÜNCELLENMİŞ VE GÜVENLİ HALE GETİRİLMİŞ METOT
  /// -----------------------------------------------------------------
  static Future<UserModel> fromFirestore(Map<String, dynamic> doc) async {
    // 1. Güvenli profil resmi okuma (null kontrolü eklendi)
    late final String profileImageUrl;
    if (kDebugMode) {
      profileImageUrl = (doc['profileImageUrl'] as String? ?? '').replaceAll(
        'localhost',
        AppConfig.host,
      );
    } else {
      profileImageUrl = doc['profileImageUrl'] as String? ?? '';
    }

    // 2. Güvenli Timestamp okuma (Null hatası çözümü)
    final birthDate = (doc['birthDate'] as Timestamp? ?? Timestamp.now())
        .toDate();
    final createdAt = (doc['createdAt'] as Timestamp? ?? Timestamp.now())
        .toDate();
    final updatedAt = (doc['updatedAt'] as Timestamp? ?? Timestamp.now())
        .toDate();
    final lastActiveAt = (doc['lastActiveAt'] as Timestamp? ?? Timestamp.now())
        .toDate();

    // 3. Güvenli Gender okuma (String -> int hatası çözümü)
    // Veriyi 'String' olarak oku, null ise varsayılan olarak 'other' kullan
    final String genderString = doc['gender'] as String? ?? 'other';

    GenderEnum gender;
    try {
      // Senin 'fromString' metodunu kullanarak enum'a çevir
      gender = GenderEnum.fromString(genderString);
    } catch (e) {
      // Eğer 'fromString' hata verirse (örn: "unknown") varsayılanı kullan
      gender = GenderEnum.other;
    }

    // 4. Modeli oluştururken diğer alanlar için de null kontrolleri ekleyelim
    return UserModel(
      userID: doc['userID'] as String,
      email: doc['email'] as String? ?? '', // email de null olabilir
      username:
          doc['username'] as String? ?? 'Bilinmeyen Kullanıcı', // username de
      birthDate: birthDate, // Güvenli
      gender: gender, // Güvenli (Düzeltildi)
      organization: doc['organization'] as String? ?? '',
      profileImageUrl: profileImageUrl, // Güvenli
      bio:
          doc['bio']
              as String?, // bio zaten 'String?' (nullable) olduğu için OK
      permissions: userPermissionsFromFirestore(
        doc['permissions'] as Map<String, dynamic>? ??
            {}, // permissions null ise
      ),
      createdAt: createdAt, // Güvenli
      updatedAt: updatedAt, // Güvenli
      lastActiveAt: lastActiveAt, // Güvenli
    );
  }

  /// -----------------------------------------------------------------
  /// GÜVENLİ YARDIMCI METOT
  /// -----------------------------------------------------------------
  static UserPermissions userPermissionsFromFirestore(
    Map<String, dynamic> doc,
  ) {
    // Bu yardımcı metodu da daha güvenli hale getirelim
    return UserPermissions(
      locationEnabled: doc['locationEnabled'] as bool? ?? false,
      notificationsEnabled: doc['notificationsEnabled'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    // Firestore'a yazarken 'gender' için .value kullanmalısın
    // (veya .index değil, senin enum'una göre .value daha mantıklı)
    final profileImageUrlFirestore = profileImageUrl.replaceAll(
      AppConfig.host,
      'localhost',
    );
    return {
      'userID': userID,
      'email': email,
      'username': username,
      'birthDate': Timestamp.fromDate(birthDate),
      'gender': gender.value, // DİKKAT: .index yerine .value ("male", "female")
      'organization': organization,
      'profileImageUrl': profileImageUrlFirestore,
      'bio': bio,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'permissions': permissions.toMap(),
    };
  }

  @override
  UserEntity toEntity() {
    return UserEntity(
      userID: userID,
      email: email,
      username: username,
      birthDate: birthDate,
      gender: gender,
      organization: organization,
      profileImageUrl: profileImageUrl,
      bio: bio,
      permissions: permissions,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastActiveAt: lastActiveAt,
    );
  }

  final Identifier userID;
  final String email;
  final String username;
  final DateTime birthDate;
  final GenderEnum gender;
  final String organization;
  final String profileImageUrl;
  final String? bio;
  final UserPermissions permissions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastActiveAt;
}
// import 'package:bulusalim/core/constants/Configs/app_config.dart';
// import 'package:bulusalim/core/utils/types/enums/gender_enum.dart';
// import 'package:bulusalim/core/utils/types/types.dart';
// import 'package:bulusalim/data/models/model.dart';
// import 'package:bulusalim/domain/entities/user/user_entity.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';

// class UserModel extends Model<UserEntity> {
//   UserModel({
//     required this.userID,
//     required this.username,
//     required this.email,
//     required this.birthDate,
//     required this.gender,
//     required this.organization,
//     required this.profileImageUrl,
//     required this.bio,
//     required this.permissions,
//     required this.createdAt,
//     required this.updatedAt,
//     required this.lastActiveAt,
//   });

//   @override
//   factory UserModel.fromEntity(UserEntity entity) {
//     return UserModel(
//       userID: entity.userID,
//       email: entity.email,
//       username: entity.username,
//       birthDate: entity.birthDate,
//       gender: entity.gender,
//       organization: entity.organization,
//       profileImageUrl: entity.profileImageUrl,
//       bio: entity.bio,
//       permissions: entity.permissions,
//       createdAt: entity.createdAt,
//       updatedAt: entity.updatedAt,
//       lastActiveAt: entity.lastActiveAt,
//     );
//   }

//   static Future<UserModel> fromFirestore(Map<String, dynamic> doc) async {
//     late final String profileImageUrl;
//     if (kDebugMode) {
//       profileImageUrl = (doc['profileImageUrl'] as String).replaceAll(
//         'localhost',
//         AppConfig.host,
//       );
//     } else {
//       profileImageUrl = doc['profileImageUrl'] as String;
//     }
//     return UserModel(
//       userID: doc['userID'] as String,
//       email: doc['email'] as String,
//       username: doc['username'] as String,
//       birthDate: (doc['birthDate'] as Timestamp).toDate(),
//       gender: GenderEnum.values[doc['gender'] as int],
//       organization: doc['organization'] as String,
//       profileImageUrl: profileImageUrl,
//       bio: doc['bio'] as String?,
//       permissions: userPermissionsFromFirestore(
//         doc['permissions'] as Map<String, dynamic>,
//       ),
//       createdAt: (doc['createdAt'] as Timestamp).toDate(),
//       updatedAt: (doc['updatedAt'] as Timestamp).toDate(),
//       lastActiveAt: (doc['lastActiveAt'] as Timestamp).toDate(),
//     );
//   }

//   static UserPermissions userPermissionsFromFirestore(
//     Map<String, dynamic> doc,
//   ) {
//     return UserPermissions(
//       locationEnabled: doc['locationEnabled'] as bool,
//       notificationsEnabled: doc['notificationsEnabled'] as bool,
//     );
//   }

//   @override
//   Map<String, dynamic> toFirestore() {
//     profileImageUrl.replaceAll(
//       AppConfig.host,
//       'localhost',
//     );
//     return {
//       'userID': userID,
//       'email': email,
//       'username': username,
//       'birthDate': Timestamp.fromDate(birthDate),
//       'gender': gender.index,
//       'organization': organization,
//       'profileImageUrl': profileImageUrl,
//       'bio': bio,
//       'createdAt': Timestamp.fromDate(createdAt),
//       'updatedAt': Timestamp.fromDate(updatedAt),
//       'lastActiveAt': Timestamp.fromDate(lastActiveAt),
//       'permissions': permissions.toMap(),
//     };
//   }

//   @override
//   UserEntity toEntity() {
//     return UserEntity(
//       userID: userID,
//       email: email,
//       username: username,
//       birthDate: birthDate,
//       gender: gender,
//       organization: organization,
//       profileImageUrl: profileImageUrl,
//       bio: bio,
//       permissions: permissions,
//       createdAt: createdAt,
//       updatedAt: updatedAt,
//       lastActiveAt: lastActiveAt,
//     );
//   }

//   final Identifier userID;
//   final String email;
//   final String username;
//   final DateTime birthDate;
//   final GenderEnum gender;
//   final String organization;
//   final String profileImageUrl;
//   final String? bio;
//   final UserPermissions permissions;
//   final DateTime createdAt;
//   final DateTime updatedAt;
//   final DateTime lastActiveAt;
// }
