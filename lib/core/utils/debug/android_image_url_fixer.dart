import 'dart:io';

import 'package:outnest/core/constants/configs/app_config.dart';

String fixEmulatorUrl(String url) {
  // Sadece Android ve URL içinde 'localhost' varsa işlem yap
  if (!Platform.isAndroid || !url.contains('localhost')) {
    return url;
  }

  try {
    final isPhysicalDevice = AppConfig.isPhysicalDevice;

    if (isPhysicalDevice) {
      // FİZİKSEL CİHAZ (Telefon):
      // Telefon 'localhost' kelimesini çözemediği için hata alıyorsun.
      // Bunu '127.0.0.1' ile değiştiriyoruz.
      // NOT: Terminalde 'adb reverse tcp:8080 tcp:8080' komutunu çalıştırırsan
      // telefonun 127.0.0.1:8080'i, bilgisayarının 8080 portuna bağlanır.
      return url.replaceFirst('localhost', '127.0.0.1');
    } else {
      // EMULATOR:
      // Emülatörün bilgisayarı görmesi için standart IP.
      return url.replaceFirst('localhost', '10.0.2.2');
    }
  } on Exception {
    return url;
  }
}
