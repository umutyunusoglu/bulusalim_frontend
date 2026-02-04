import 'package:cloud_functions/cloud_functions.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';

class SendEventInvitation {
  const SendEventInvitation({
    required LoggingService loggingService,
    required FirebaseFunctions functions,
  }) : _loggingService = loggingService,
       _functions = functions;

  final LoggingService _loggingService;
  final FirebaseFunctions _functions;

  Future<String?> call({
    required String toID,
    required String toUsername,
    required String toAvatarUrl,
    required String eventID,
    required String eventName,
  }) async {
    try {
      final result = await _functions.httpsCallable('sendEventInvitation').call(
        {
          'toID': toID,
          'toUsername': toUsername,
          'toAvatarUrl': toAvatarUrl,
          'eventID': eventID,
          'eventName': eventName,
        },
      );

      // Backend artık bir Map döndüğü için veriyi bu şekilde almalıyız
      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return data['message'] as String?;
      }

      return 'İşlem başarısız oldu.';
    } on FirebaseFunctionsException catch (e) {
      // Firebase'den gelen özel hataları (unauthenticated, invalid-argument vb.) yakala
      _loggingService.error('Cloud Function Hatası [${e.code}]: ${e.message}');
      rethrow;
    } catch (e) {
      _loggingService.error(
        'Etkinlik daveti gönderilirken beklenmedik hata: $e',
      );
      rethrow;
    }
  }
}
