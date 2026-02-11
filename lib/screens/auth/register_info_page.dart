import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:outnest/application/providers/get_it_init.dart';
import 'package:outnest/components/auth_input.dart';
import 'package:outnest/components/bottomsheetoption.dart';
import 'package:outnest/components/map_filter_chip.dart';
import 'package:outnest/components/otp_row.dart';
import 'package:outnest/components/register_step_view.dart';
import 'package:outnest/core/constants/configs/app_config.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/core/utils/logging/logging_service.dart';
import 'package:outnest/core/utils/title_case_formatter.dart';
import 'package:outnest/core/utils/types/enums/account_type_enum.dart';
import 'package:outnest/core/utils/types/enums/gender_enum.dart';
import 'package:outnest/domain/datasources/university_datasource.dart';
import 'package:outnest/domain/entities/user/user_entity.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:outnest/domain/services/auth_service.dart';
import 'package:outnest/domain/usecases/upload_profile_picture_usecase.dart';
import 'package:permission_handler/permission_handler.dart';

class RegisterInfoPage extends StatefulWidget {
  const RegisterInfoPage({super.key});

  @override
  State<RegisterInfoPage> createState() => _RegisterInfoPageState();
}

class _RegisterInfoPageState extends State<RegisterInfoPage> {
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

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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

      switch (_genderDisplayController.text.trim().toLowerCase()) {
        case 'kadın':
          gender = GenderEnum.female;
        case 'erkek':
          gender = GenderEnum.male;

        case 'belirtmek istemiyorum':
          gender = GenderEnum.other;
        case 'özel':
          gender = GenderEnum.preferNotToSay;
        default:
          gender = GenderEnum.preferNotToSay;
      }

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
      context.go('/home');
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

                final logger = getIt<LoggingService>()..warn(exists.toString());

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
              inputFormatters: [
                // 1. Sadece küçük harf, rakam, nokta ve alt tire yazılmasına izin ver
                FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9._]')),

                // 2. Yazılan her şeyi anında küçük harfe çevir
                TextInputFormatter.withFunction((oldValue, newValue) {
                  return newValue.copyWith(text: newValue.text.toLowerCase());
                }),
              ],
              validator: () {
                final text = _usernameController.text.trim();

                // 1. Boşluk kontrolü
                if (text.isEmpty) return 'Kullanıcı adı boş olamaz';

                // 2. Uzunluk kontrolü
                if (text.length < 3) return 'En az 3 karakter olmalı';
                if (text.length > 30) return 'En fazla 30 karakter olmalı';
                // 3. Karakter kontrolü (Küçük harf, rakam, nokta ve alt tire)
                // ^ : Başlangıç, $ : Bitiş, [a-z0-0._] : İzin verilenler, + : En az bir tane
                final usernameRegExp = RegExp(r'^[a-z0-9._]+$');

                if (!usernameRegExp.hasMatch(text)) {
                  return 'Sadece küçük harf, rakam, "." ve "_" kullanabilirsiniz';
                }

                return null; // Her şey yolunda
              },
            ),

            // 2. AD SOYAD
            RegisterStepView(
              title: 'Ad - Soyad',
              controller: _nameController,
              onNext: _nextPage,
              hintText: 'Adınız ve Soyadınız',
              description:
                  'Gerçek adınızı kullanmanızı öneririz, böylece arkadaşlarınız sizi daha kolay bulabilir.',
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r"[a-zA-ZğüşöçıİĞÜŞÖÇ\s'-]"),
                ),
                TitleCaseFormatter(),
              ],
              validator: () {
                final text = _nameController.text.trim();
                if (text.isEmpty) return 'Ad - Soyad boş olamaz';

                final words = text
                    .split(' ')
                    .where((w) => w.isNotEmpty)
                    .toList();
                if (words.length < 2) {
                  return 'Lütfen adınızı ve soyadınızı tam giriniz';
                }

                if (text.length < 2) return 'En az 2 karakter olmalı';
                if (text.length > 50) return 'En fazla 50 karakter olmalı';

                return null;
              },
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
              validator: () {
                if (_selectedDate == null) {
                  return 'Lütfen doğum tarihinizi seçin';
                }
                // Bugünün tarihi
                final now = DateTime.now();
                //TODO: 28 şubat
                // 18 yıl önceki aynı günün tarihi
                final eighteenYearsAgo = DateTime(
                  now.year - 18,
                  now.month,
                  now.day,
                );

                // Eğer seçilen tarih, 18 yıl önceki tarihten sonra ise (yani daha gençse)
                if (_selectedDate!.isAfter(eighteenYearsAgo)) {
                  return "Outnest'e katılmak için 18 yaşını doldurmuş olmalısın";
                }

                return null; // Her şey yolunda
              },
            ),

            // 4. ÜNİVERSİTE MAİL
            RegisterStepView(
              title: 'Üniversite Doğrulama',
              controller: _universityController,
              hintText: '@edu.tr',
              buttonText: _isSendingEmail ? 'gönderiliyor...' : 'kod gönder',
              // Kullanıcı maili yazarken anlık kontrol:
              onChanged: _onUniversityEmailChanged,
              description: _detectedUniversity != null
                  ? 'Tespit Edilen: $_detectedUniversity'
                  : "Üniversiteni doğruladığında, üniversite bilgin profilinde otomatik olarak görünür. Yalnızca Türkiye'deki üniversiteler desteklenmektedir.",

              validator: () {
                final email = _universityController.text.trim();
                if (email.isEmpty) return 'Mail adresi boş olamaz';
                if (_detectedUniversity == null) {
                  return 'Tanınan bir üniversite maili giriniz';
                }
                return null;
              },

              onNext: () async {
                setState(() => _isSendingEmail = true);
                try {
                  print(FirebaseAuth.instance.currentUser?.uid);
                  await getIt<UserRepository>().sendVerificationEmail(
                    _universityController.text.trim(),
                  );
                  if (!mounted) return;
                  _nextPage(); // Başarılıysa OTP sayfasına geç
                } catch (e) {
                  if (mounted) _showError(e.toString());
                } finally {
                  if (mounted) setState(() => _isSendingEmail = false);
                }
              },
              onSkip: () => _pageController.jumpToPage(5),
            ),

            RegisterStepView(
              title: 'Doğrulama Kodu',
              buttonText: 'onayla',
              description:
                  '${_universityController.text} adresine gelen kodu giriniz.',
              customContent: OtpRow(controllers: _eduOtpControllers),

              onNext: () async {
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
                  _nextPage(); // Başarılıysa devam et
                } catch (e) {
                  if (mounted) _showError('Kod hatalı veya geçersiz: $e');
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

                        return MapFilterChip(
                          label: categoryName.toLowerCase(),
                          emoji: categoryEmoji,
                          isSelected: isSelected,
                          onTap: () => _toggleInterest(categoryName),
                        );
                      }).toList(),
                    ),
            ),

            // 9. ARKADAŞLARINI EKLE
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

            // 10. CİHAZ İZİNLERİ
            RegisterStepView(
              title: 'Cihaz İzinleri',
              onNext: _finishRegistration,
              buttonText: 'bitir',
              customContent: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPermissionRow(
                    title: 'Bildirimler',
                    description:
                        'Outnest uygulamasına bu cihaza güncellemeler ve önemli bildirimler göndermesine izin verilir.',
                    value: _permNotifications,
                    onChanged: (val) => _handlePermissionToggle(
                      val,
                      Permission.notification,
                      (newState) => _permNotifications = newState,
                    ),
                  ),
                  _buildPermissionRow(
                    title: 'Bluetooth',
                    description:
                        "Outnest uygulamasına yakındaki cihazlarla bağlantı kurmak için Bluetooth'u kullanmasına izin verilir.",
                    value: _permBluetooth,
                    onChanged: (val) => _handlePermissionToggle(
                      val,
                      Permission.bluetooth,
                      (newState) => _permBluetooth = newState,
                    ),
                  ),
                  _buildPermissionRow(
                    title: 'Konum Servisleri',
                    description:
                        'Outnest uygulamasına bulunduğun konuma göre içerik ve öneriler sunmak için konum bilgine erişmesine izin verilir.',
                    value: _permLocation,
                    onChanged: (val) => _handlePermissionToggle(
                      val,
                      Permission.location,
                      (newState) => _permLocation = newState,
                    ),
                  ),
                  _buildPermissionRow(
                    title: 'Kamera',
                    description:
                        'Outnest uygulamasına fotoğraf ve video çekerek paylaşım yapabilmen için kameraya erişmesine izin verilir.',
                    value: _permCamera,
                    onChanged: (val) => _handlePermissionToggle(
                      val,
                      Permission.camera,
                      (newState) => _permCamera = newState,
                    ),
                  ),
                  _buildPermissionRow(
                    title: 'Fotoğraflar',
                    description:
                        'Outnest uygulamasına galerinden fotoğraf ve video seçip paylaşabilmen için fotoğraflarına erişmesine izin verilir.',
                    value: _permPhotos,
                    onChanged: (val) => _handlePermissionToggle(
                      val,
                      Permission.photos,
                      (newState) => _permPhotos = newState,
                    ),
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

  Widget _buildPermissionRow({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
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
                    fontFamily: 'SF Pro Display',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 12.sp,
                    color: Colors.grey.shade400,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),

          // SWITCH
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42.w,
              height: 24.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.h),
                color: value ? AppColors.primaryColor : Colors.grey.shade300,
              ),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    left: value ? (42.w - 20.h - 2.w) : 2.w,
                    child: Container(
                      width: 20.h,
                      height: 20.h,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePermissionToggle(
    bool newValue,
    Permission permission,
    ValueChanged<bool> onStateChanged,
  ) async {
    if (newValue) {
      // İzni açmak istiyor, sistem popup'ını göster
      final status = await permission.request();

      if (status.isGranted) {
        setState(() => onStateChanged(true));
      } else if (status.isPermanentlyDenied) {
        // Kalıcı reddedilmişse ayarlara yönlendir
        _showSettingsDialog();
        setState(() => onStateChanged(false));
      } else {
        // Sadece reddedildi, switch kapalı kalsın
        setState(() => onStateChanged(false));
      }
    } else {
      // İzni kapatmak istiyor. (Sistem izni kodla kapanmaz ama app içi state kapanır)
      setState(() => onStateChanged(false));
    }
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
