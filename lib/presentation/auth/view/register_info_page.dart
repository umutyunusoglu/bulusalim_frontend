import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/types/enums/account_type_enum.dart';
import 'package:outnest/core/utils/types/enums/gender_enum.dart';
import 'package:outnest/domain/datasources/university_datasource.dart';
import 'package:outnest/domain/entities/user/user_entity.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/analytics/analytics_service.dart';
import 'package:outnest/domain/services/analytics/event_configs/select_gender_analytics_config.dart';
import 'package:outnest/domain/services/analytics/event_configs/select_hobbies_analytics_config.dart';
import 'package:outnest/domain/services/auth_service.dart';
import 'package:outnest/domain/usecases/upload_profile_picture_usecase.dart';
import 'package:outnest/presentation/auth/view/components/otp_row.dart';
import 'package:outnest/presentation/auth/view/components/register_step_view.dart';
import 'package:outnest/presentation/shared/bottom_sheet_option.dart';
import 'package:outnest/presentation/shared/category_filter_chip.dart';
import 'package:outnest/presentation/shared/form/formatters/name_surname_formatter.dart';
import 'package:outnest/presentation/shared/form/formatters/username_formatter.dart';
import 'package:outnest/presentation/shared/form/validators/validate_date_of_birth.dart';
import 'package:outnest/presentation/shared/form/validators/validate_name_surname.dart';
import 'package:outnest/presentation/shared/form/validators/validate_university_mail.dart';
import 'package:outnest/presentation/shared/form/validators/validate_username.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class RegisterInfoPage extends StatefulWidget {
  const RegisterInfoPage({super.key});

  @override
  State<RegisterInfoPage> createState() => _RegisterInfoPageState();
}

enum RegisterStep {
  username,
  name,
  dob,
  universityEmail,
  universityOtp,
  gender,
  profilePhoto,
  interests,
  permissions,
}

final Map<RegisterStep, RegisterStep> backSteps = {
  RegisterStep.name: RegisterStep.username,
  RegisterStep.dob: RegisterStep.name,
  RegisterStep.universityEmail: RegisterStep.dob,
  RegisterStep.universityOtp: RegisterStep.universityEmail,
  RegisterStep.gender: RegisterStep.universityEmail,
  RegisterStep.profilePhoto: RegisterStep.gender,
  RegisterStep.interests: RegisterStep.profilePhoto,
  RegisterStep.permissions: RegisterStep.interests,
};

class _RegisterInfoPageState extends State<RegisterInfoPage>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();

  // --- CONTROLLER'LAR ---
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _universityController = TextEditingController();
  final _genderDisplayController = TextEditingController();
  final _friendSearchController = TextEditingController();
  // --- İZİN STATE'LERİ (Varsayılan Kapalı) ---
  bool _permNotifications = false;
  bool _permBluetooth = false;
  bool _permLocation = false;
  bool _permCamera = false;
  bool _permPhotos = false;

  final _logger = getIt<LoggingService>();

  final List<TextEditingController> _eduOtpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  final List<String> _selectedInterests = [];
  final Map<String, String> _categories = AppConfig.categories;
  int _currentIndex = 0;
  final bool _isLoadingConfig = false;
  DateTime? _selectedDate;

  String? _detectedUniversity;
  bool _isSendingEmail = false;
  bool _isVerifyingEmail = false;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _syncAllPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _usernameController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _universityController.dispose();
    _genderDisplayController.dispose();
    _friendSearchController.dispose();
    for (final c in _eduOtpControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama arka plandan ön plana geldiğinde (ayarlardan dönünce)
    if (state == AppLifecycleState.resumed) {
      _syncAllPermissions();
    }
  }

  void _nextPage() {
    final currentStep = RegisterStep.values[_currentIndex];
    final analytics = getIt<AnalyticsService>();

    switch (currentStep) {
      case RegisterStep.username:
        // Burada username kontrolü yapılacak
        break;
      case RegisterStep.name:
        // Ad soyad validasyonu yapılacak
        break;
      case RegisterStep.dob:
        // Doğum tarihi validasyonu yapılacak
        break;
      case RegisterStep.universityEmail:
        // Üniversite maili validasyonu yapılacak
        break;
      case RegisterStep.universityOtp:
        // OTP validasyonu yapılacak
        break;
      case RegisterStep.gender:
        final chosenGenderText = _genderDisplayController.text.trim();
        GenderEnum? chosenGender;
        if (chosenGenderText.isEmpty) {
          // Hata mesajı göster
          chosenGender = null;
        } else {
          chosenGender = GenderEnum.fromString(chosenGenderText);
        }

        analytics.logSelectGender(
          SelectGenderAnalyticsConfig(value: chosenGender, previousValue: null),
        );
        break;
      case RegisterStep.profilePhoto:
        // Fotoğraf seçimi validasyonu yapılacak
        break;
      case RegisterStep.interests:
        final selectedCategories = _selectedInterests;

        analytics.logSelectHobbies(
          SelectHobbiesAnalyticsConfig(
            value: _selectedInterests,
            previousValue: [],
          ),
        );

        break;
      case RegisterStep.permissions:
        // İzinler ile ilgili bilgilendirme yapılacak
        break;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      final currentStep = RegisterStep.values[_currentIndex];
      final backStep = backSteps[currentStep]!;
      final backIndex = RegisterStep.values.indexOf(backStep);

      if (_currentIndex - backIndex > 1) {
        _pageController.jumpToPage(
          backIndex,
        );
      } else {
        _pageController.animateToPage(
          backIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      context.pop();
    }
  }

  bool _isRegistering = false;

  // --- KAYIT BİTİRME FONKSİYONU ---
  Future<void> _finishRegistration() async {
    // Burada API'ye kayıt isteği atılmalı ve SessionService güncellenmeli.
    // Başarılı olduktan sonra Home'a yönlendiriyoruz:
    if (_isRegistering) return; // Çift tıklamayı önle

    setState(() => _isRegistering = true);

    try {
      final username = _usernameController.text.trim();
      final name = _nameController.text.trim();
      final dob = _selectedDate!;
      GenderEnum gender;
      gender = GenderEnum.fromString(_genderDisplayController.text);

      final interests = _selectedInterests;
      final File? profilePhoto; // Fotoğraf seçme işlemi eklenmeli.
      final uploadUseCase = getIt<UploadProfilePicture>();
      var profileImageUrl = '';
      if (_selectedImage != null) {
        profileImageUrl =
            await uploadUseCase.call(
              userID: getIt<FirebaseAuth>().currentUser!.uid,
              filePath: _selectedImage!.path,
            ) ??
            '';
      }
      final isEmailVerified = _detectedUniversity != null;
      final university = isEmailVerified ? _detectedUniversity! : null;
      final universityEmail = isEmailVerified
          ? _universityController.text.trim()
          : null;

      final userRepository = getIt<UserRepository>();

      final newUser = UserEntity(
        userID: getIt<FirebaseAuth>().currentUser!.uid,
        username: username,
        nameSurname: name,
        email: universityEmail ?? '',
        birthDate: dob,
        gender: gender,
        university: university,
        universityEmail: universityEmail,
        isUniversityVerified: isEmailVerified,
        profileImageUrl: profileImageUrl,
        bio: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
        followeeCount: 0,
        hobbies: interests,
        followerCount: 0,
        accountType: AccountType.personal,
        phoneNumber: getIt<AuthService>().getUserPhoneNumber(),
        instagram: '',
      );

      await userRepository.createUser(
        newUser,
      );

      if (!mounted) return; // Eklemen gereken satır
      context.go('/splash', extra: UniqueKey());
    } catch (e, stackTrace) {
      // Konsola detaylı bas ki hatayı görebilelim
      debugPrint('HATA OLUŞTU: $e');
      debugPrint('Stack Trace: $stackTrace');

      getIt<LoggingService>().error('Kayıt tamamlanamadı: $e');

      // EKRANA HATA MESAJI BASAN KOD BU:
      if (mounted) {
        _showError('Bir sorun oluştu: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  void _toggleInterest(String category) {
    setState(() {
      if (_selectedInterests.contains(category)) {
        _selectedInterests.remove(category);
      } else {
        _selectedInterests.add(category);
      }
    });
  }

  // --- CUPERTINO DATE PICKER ---
  void _showDatePicker() {
    final initialDate = DateTime.now().subtract(const Duration(days: 365 * 18));
    final maxDate = DateTime.now();
    final minDate = DateTime(1920);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (BuildContext builder) {
        return SizedBox(
          height: 300.h,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text(
                        'Tamam',
                        style: TextStyle(
                          color: AppColors.tertiaryColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        _selectedDate ??= initialDate;
                        final formattedDate = DateFormat(
                          'dd/MM/yyyy',
                        ).format(_selectedDate!);
                        _dobController.text = formattedDate;
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDate ?? initialDate,
                  minimumDate: minDate,
                  maximumDate: maxDate,
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      _selectedDate = newDate;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- BOTTOM SHEETS ---
  void _selectGender(String gender) {
    setState(() => _genderDisplayController.text = gender);
    Navigator.pop(context);
  }

  void _showGenderPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return CustomActionBottomSheet(
          options: [
            BottomSheetOption(
              icon: Icons.female,
              text: 'Kadın',
              onTap: () => _selectGender('Kadın'),
            ),
            BottomSheetOption(
              icon: Icons.male,
              text: 'Erkek',
              onTap: () => _selectGender('Erkek'),
            ),

            BottomSheetOption(
              icon: Icons.block_outlined,
              text: 'Belirtmek İstemiyorum',
              onTap: () => _selectGender('Belirtmek İstemiyorum'),
            ),
            BottomSheetOption(
              icon: Icons.circle_outlined,
              text: 'Özel',
              onTap: () => _selectGender('Özel'),
            ),
          ],
        );
      },
    );
  }

  void _showPhotoPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return CustomActionBottomSheet(
          options: [
            BottomSheetOption(
              icon: Icons.add_a_photo_outlined,
              text: 'Fotoğraf Çek',
              onTap: () => _pickImage(ImageSource.camera),
            ),
            BottomSheetOption(
              icon: Icons.image_outlined,
              text: 'Fotoğraflardan Seç',
              onTap: () => _pickImage(ImageSource.gallery),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: _currentIndex == 0
              ? null
              : IconButton(
                  icon: Icon(Icons.undo, color: Colors.black, size: 24.sp),
                  onPressed: _prevPage,
                ),
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) => setState(() => _currentIndex = index),
          children: [
            // 1. KULLANICI ADI
            RegisterStepView(
              title: 'Kullanıcı Adı',
              controller: _usernameController,
              onNext: () async {
                final username = _usernameController.text.trim();

                // 2. Async kontrolü burada yap
                final exists = await getIt<UserRepository>().doesUsernameExist(
                  username,
                );

                getIt<LoggingService>().warn(exists.toString());

                if (exists) {
                  // Hata mesajını göster (SnackBar veya bir state değişkeni ile)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bu kullanıcı adı zaten alınmış!'),
                    ),
                  );
                } else {
                  // 3. Her şey yolundaysa genel _nextPage fonksiyonunu çağır
                  _nextPage();
                }
              },
              description:
                  'Uygulama içerisinde insanlar sizi bu isimle görecek.',
              hintText: '@kullaniciadi',
              inputFormatters: [UsernameFormatter()],
              validator: () =>
                  validateUsername(_usernameController.text.trim()),
            ),

            // 2. AD SOYAD
            RegisterStepView(
              title: 'Ad - Soyad',
              controller: _nameController,
              onNext: _nextPage,
              hintText: 'Adınız ve Soyadınız',
              description:
                  'Gerçek adınızı kullanmanızı öneririz, böylece arkadaşlarınız sizi daha kolay bulabilir.',
              inputFormatters: [NameSurnameFormatter()],
              validator: () => validateNameSurname(_nameController.text.trim()),
            ),

            // 3. DOĞUM TARİHİ
            RegisterStepView(
              title: 'Doğum Tarihi',
              controller: _dobController,
              onNext: _nextPage,
              hintText: 'GG/AA/YYYY',
              description:
                  'Outnest topluluğuna katılabilmek için 18 yaşını doldurmuş olman gerekmektedir.',
              readOnly: true,
              onTapInput: _showDatePicker,
              validator: () => validateDateOfBirth(_selectedDate),
            ),

            // 4. ÜNİVERSİTE MAİL
            RegisterStepView(
              title: 'Üniversite Doğrulama',
              controller: _universityController,
              hintText: '@edu.tr',
              enabled: !_isSendingEmail,
              buttonText: _isSendingEmail ? 'gönderiliyor...' : 'kod gönder',
              // Kullanıcı maili yazarken anlık kontrol:
              onChanged: _onUniversityEmailChanged,
              description: _detectedUniversity != null
                  ? 'Tespit Edilen: $_detectedUniversity'
                  : "Üniversiteni doğruladığında, üniversite bilgin profilinde otomatik olarak görünür. Yalnızca Türkiye'deki üniversiteler desteklenmektedir.",

              validator: () => validateUniversityMail(
                _universityController.text.trim(),
                _detectedUniversity,
              ),

              onNext: () async {
                if (_isSendingEmail) return;
                setState(() => _isSendingEmail = true);
                try {
                  print(FirebaseAuth.instance.currentUser?.uid);
                  await getIt<UserRepository>().sendVerificationEmail(
                    _universityController.text.trim(),
                  );
                  if (!mounted) return;
                  _nextPage(); // Başarılıysa OTP sayfasına geç
                } on FirebaseFunctionsException catch (error) {
                  if (mounted) {
                    if (error.code == 'resource-exhausted') {
                      _showError(
                        'Çok fazla mail yollama isteği gönderdiniz. Lütfen 1 dakika sonra tekrar deneyin!',
                      );

                      _logger.error(
                        'FirebaseAuthException: ${error.code} - ${error.message}',
                      );
                    } else {
                      _logger.error(
                        'Bir hata oluştu: ${error.code} - ${error.message}',
                      );
                    }
                    _logger.error('Verification email gönderilemedi: $error');
                  }
                } finally {
                  if (mounted) setState(() => _isSendingEmail = false);
                }
              },
              onSkip: !_isSendingEmail
                  ? () => _pageController.jumpToPage(RegisterStep.gender.index)
                  : null,

              footerWidget: TextButton(
                onPressed: () async {
                  final Uri url = Uri.parse(
                    'https://forms.gle/KfpyB3Y2SeiX28R47',
                  );
                  launchUrl(url, mode: LaunchMode.inAppWebView);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600, // Silik, tatlı bir gri
                ),
                child: Text(
                  'Üniversitenizi bulamıyor musunuz? Bize bildirin.',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 12.sp,
                    decoration:
                        TextDecoration.underline, // Tıklanabilir hissi verir
                  ),
                ),
              ),
            ),

            RegisterStepView(
              title: 'Doğrulama Kodu',
              buttonText: 'onayla',
              enabled: !_isVerifyingEmail,
              description:
                  '${_universityController.text} adresine gelen kodu giriniz.',
              customContent: OtpRow(controllers: _eduOtpControllers),

              onNext: () async {
                if (_isVerifyingEmail) return;
                setState(() => _isVerifyingEmail = true);
                final otpCode = _eduOtpControllers.map((c) => c.text).join();
                try {
                  // Debug ekranındaki verifyEmail logic'i:
                  print('otpCode: $otpCode');
                  await getIt<UserRepository>().verifyEmail(
                    _universityController.text.trim(),
                    _detectedUniversity!,
                    otpCode,
                  );

                  if (!mounted) return;
                  setState(() => _isVerifyingEmail = false);
                  _nextPage(); // Başarılıysa devam et
                } catch (e) {
                  if (mounted) {
                    _showError('Kod hatalı veya geçersiz: $e');
                    setState(() => _isVerifyingEmail = true);
                  }
                }
              },
            ),

            // 6. CİNSİYET
            RegisterStepView(
              title: 'Cinsiyet',
              controller: _genderDisplayController,
              hintText: 'lütfen seçiniz',
              onNext: _nextPage,
              readOnly: true,
              onTapInput: _showGenderPicker,
              onSkip: _nextPage,
            ),

            RegisterStepView(
              title: 'Profil Fotoğrafı',
              onNext: _nextPage,
              customContent: GestureDetector(
                onTap: _showPhotoPicker, // Mevcut modalını kullanacağız
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 140.w,
                      height: 140.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F5),
                        shape: BoxShape.circle,
                        image: _selectedImage != null
                            ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 2,
                        ),
                      ),
                      child: _selectedImage == null
                          ? Icon(
                              Icons.camera_alt_outlined,
                              size: 45.sp,
                              color: Colors.grey.shade400,
                            )
                          : null,
                    ),
                    if (_selectedImage != null)
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // 8. İLGİ ALANLARI
            RegisterStepView(
              title: 'İlgi Alanların',
              description: 'En az 3 adet seçmenizi öneririz.',
              onNext: _nextPage,
              onSkip: _nextPage,
              customContent: _isLoadingConfig
                  ? SizedBox(
                      height: 100.h,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      ),
                    )
                  : _categories.isEmpty
                  ? Center(
                      child: Text(
                        'Kategoriler yüklenemedi.\nLütfen internet bağlantınızı kontrol edin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                      ),
                    )
                  : Wrap(
                      spacing: 12.w,
                      runSpacing: 12.h,
                      alignment: WrapAlignment.center,
                      children: _categories.entries.map((entry) {
                        final categoryName = entry.key;
                        final categoryEmoji = entry.value;
                        final isSelected = _selectedInterests.contains(
                          categoryName,
                        );

                        return CategoryFilterChip(
                          label: categoryName.toLowerCase(),
                          emoji: categoryEmoji,
                          isSelected: isSelected,
                          onTap: () => _toggleInterest(categoryName),
                        );
                      }).toList(),
                    ),
            ),

            // 9. ARKADAŞLARINI EKLE
            /*
            RegisterStepView(
              title: 'Arkadaşlarını Ekle',
              onNext: _nextPage,
              onSkip: _nextPage,
              buttonText: 'devam',
              customContent: Column(
                children: [
                  AuthInput(
                    controller: _friendSearchController,
                    hintText: 'Ara',
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  _buildActionRow(
                    Icons.contact_phone_outlined,
                    'Kişilerinden ara',
                  ),
                  Divider(color: Colors.grey.shade200),
                  _buildActionRow(Icons.camera_alt_outlined, 'Instagram bağla'),
                ],
              ),
            ),
            */
            // 10. CİHAZ İZİNLERİ
            RegisterStepView(
              title: 'Cihaz İzinleri',
              onNext: _finishRegistration,
              buttonText: 'bitir',
              customContent: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPermissionTile(
                    title: 'Bildirimler',
                    description:
                        'Outnest uygulamasına bu cihaza güncellemeler ve önemli bildirimler göndermesine izin verilir.',
                    permission: Permission.notification,
                    value: _permNotifications,
                  ),
                  /*
                  _buildPermissionTile(
                    title: 'Bluetooth',
                    description:
                        "Outnest uygulamasına yakındaki cihazlarla bağlantı kurmak için Bluetooth'u kullanmasına izin verilir.",
                    permission: Permission.bluetooth,
                    value: _permBluetooth,
                  ),*/
                  _buildPermissionTile(
                    title: 'Konum Servisleri',
                    description:
                        'Bulunduğun konuma göre içerik sunabilmemiz için konum bilgine erişilir.',
                    permission: Permission.locationWhenInUse,
                    value: _permLocation,
                  ),

                  _buildPermissionTile(
                    title: 'Kamera',
                    description:
                        'Fotoğraf ve video çekebilmek için kameraya erişim gerekir.',
                    permission: Permission.camera,
                    value: _permCamera,
                  ),

                  _buildPermissionTile(
                    title: 'Fotoğraflar',
                    description:
                        'Galerinden içerik seçebilmek için fotoğraflara erişim gerekir.',
                    permission: Permission.photos,
                    value: _permPhotos,
                  ),

                  // ALT BİLGİLENDİRME METİNLERİ
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Gizlilik ve veri kullanımı hakkında daha fazla bilgi al',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 12.sp,
                          color: AppColors.tertiaryColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Cihaz izinlerinizi daha sonra Ayarlar sayfasından düzenleyebilirsiniz.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF8E8E93),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Icon(icon, color: Colors.black, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.black, size: 24.sp),
        ],
      ),
    );
  }

  Timer? _debounce;

  void _onUniversityEmailChanged(String email) {
    if (_isSendingEmail) return;
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _checkUniversity(email);
    });
  }

  Future<void> _checkUniversity(String email) async {
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _detectedUniversity = null);
      return;
    }
    try {
      final uniNames = await getIt<UniversityDatasource>().getUniversityOfMail(
        email,
        'Turkiye',
      );
      setState(() {
        _detectedUniversity = uniNames.isNotEmpty ? uniNames.first : null;
      });
    } catch (_) {
      setState(() => _detectedUniversity = null);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 14.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent.shade400,
        behavior: SnackBarBehavior.floating, // Havada asılı durması için
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(20.w), // Kenarlardan boşluk
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _syncAllPermissions() async {
    final notification = await Permission.notification.status;
    final bluetooth = await Permission.bluetooth.status;
    final location = await Permission.locationWhenInUse.status;
    final camera = await Permission.camera.status;
    final photos = await Permission.photos.status;

    if (!mounted) return;

    setState(() {
      _permNotifications = notification.isGranted;
      _permBluetooth = bluetooth.isGranted;
      _permLocation = location.isGranted;
      _permCamera = camera.isGranted;
      _permPhotos = photos.isGranted || photos.isLimited;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000, // Performans için resmi boyutlandırıyoruz
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (!mounted) return;
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        if (!mounted) return;
        Navigator.pop(context); // Modal'ı kapat
      }
    } catch (e) {
      if (mounted) _showError('Resim seçilirken bir hata oluştu: $e');
    }
  } // --- İZİN YARDIMCI FONKSİYONLARI ---

  Future<void> _handlePermissionTap(Permission permission) async {
    final status = await permission.status;

    // EĞER İZİN ZATEN VERİLDİYSE, FONKSİYONU DURDUR (KAPANAMAZ MANTIĞI)
    if (status.isGranted || status.isLimited) {
      return;
    }

    // İzin verilmemişse süreci başlat
    final result = await permission.request();

    if (!mounted) return;

    if (result.isPermanentlyDenied) {
      _showSettingsDialog();
    }

    await _syncAllPermissions();
  }

  Widget _buildPermissionTile({
    required String title,
    required String description,
    required Permission permission,
    required bool value, // Bu değer _syncAllPermissions'dan geliyor
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      // DEĞİŞİKLİK: Eğer değer true (izin verilmiş) ise onTap null olsun
      onTap: value ? null : () => _handlePermissionTap(permission),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      // DEĞİŞİKLİK: İzin verilince rengi hafifçe soluklaştırabilirsin (opsiyonel)
                      color: value ? Colors.black87 : Colors.black,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade500,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Row(
              children: [
                Icon(
                  value ? Icons.check_circle : Icons.cancel,
                  color: value ? AppColors.primaryColor : Colors.grey.shade400,
                  size: 20.sp,
                ),
                SizedBox(width: 6.w),
                Text(
                  value ? 'İzin Verildi' : 'Kapalı',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: value
                        ? AppColors.primaryColor
                        : Colors.grey.shade500,
                  ),
                ),
                SizedBox(width: 6.w),

                if (!value)
                  Icon(
                    Icons.chevron_right,
                    size: 18.sp,
                    color: Colors.grey.shade400,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'İzin Gerekli',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontWeight: FontWeight.w600,
            fontSize: 17.sp,
            color: Colors.black,
          ),
        ),
        content: Text(
          "Bu özelliği kullanabilmek için cihaz ayarlarından Outnest'e izin vermeniz gerekmektedir.",
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 14.sp,
            color: Colors.grey.shade700,
            height: 1.3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: Text(
              'Ayarlara Git',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
