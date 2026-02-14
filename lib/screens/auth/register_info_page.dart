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

  // --- İZİN STATE'LERİ ---
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
  DateTime? _selectedDate;
  String? _detectedUniversity;
  bool _isSendingEmail = false;
  bool _isRegistering = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print("DEBUG: Sayfa açıldı, ilk izin kontrolü yapılıyor...");
    _checkAllPermissions();
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
    _debounce?.cancel();
    for (final c in _eduOtpControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print(
        "DEBUG: Uygulama ön plana geldi (RESUMED). İzinler tekrar taranıyor...",
      );
      _checkAllPermissions();
    }
  }

  Future<void> _checkAllPermissions() async {
    // Sistem ayarlarındaki değişikliğin yansıması için küçük bir bekleme iyi oluyor
    await Future.delayed(const Duration(milliseconds: 700));

    try {
      final nStatus = await Permission.notification.status;
      final bStatus = await Permission.bluetooth.status;
      final lStatus = await Permission.location.status;
      final cStatus = await Permission.camera.status;
      final pStatus = await Permission.photos.status;

      if (mounted) {
        setState(() {
          _permNotifications = nStatus.isGranted;
          _permBluetooth = bStatus.isGranted;
          _permLocation = lStatus.isGranted;
          _permCamera = cStatus.isGranted;
          _permPhotos = pStatus.isGranted;
        });
      }

      print(
        "DEBUG: Senkronizasyon Tamamlandı. Bildirim: ${nStatus.isGranted}, Bluetooth: ${bStatus.isGranted}, Konum: ${lStatus.isGranted}, Kamera: ${cStatus.isGranted}, Fotoğraflar: ${pStatus.isGranted}",
      );
    } catch (e) {
      print("DEBUG ERROR: _checkAllPermissions sırasında hata: $e");
    }
  }

  // Genel permission request helper:
  // - Eğer izin zaten varsa true döner.
  // - Eğer izin istenebiliyorsa request eder.
  // - Eğer kalıcı reddedildiyse openAppSettings() çağırır ve false döner.
  Future<bool> _ensurePermission(
    Permission permission, {
    bool showSettingsIfPermanentlyDenied = true,
  }) async {
    try {
      final status = await permission.status;
      if (status.isGranted) return true;

      if (status.isPermanentlyDenied || status.isRestricted) {
        if (showSettingsIfPermanentlyDenied) {
          _showOpenSettingsDialog(permission);
        }
        return false;
      }

      // request
      final result = await permission.request();
      if (result.isGranted) return true;

      if (result.isPermanentlyDenied && showSettingsIfPermanentlyDenied) {
        _showOpenSettingsDialog(permission);
      }
      return false;
    } catch (e) {
      print("DEBUG ERROR: _ensurePermission hata: $e");
      return false;
    } finally {
      // küçük gecikmeyle izinleri tekrar eşitle
      Future.delayed(const Duration(milliseconds: 400), _checkAllPermissions);
    }
  }

  void _showOpenSettingsDialog(Permission permission) {
    // Kullanıcıyı ayarlara yönlendirmeden önce onay alabiliriz
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İzin Gerekli'),
        content: const Text(
          'Bu işlemi yapmak için uygulama ayarlarından izni açmanız gerekiyor. Ayarlara gitmek ister misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await openAppSettings();
              // Ayarlardan dönüşte kontroller lifecycle veya _checkAllPermissions ile güncellenecek
              Future.delayed(
                const Duration(milliseconds: 700),
                _checkAllPermissions,
              );
            },
            child: const Text('Ayarlar'),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePermissionToggle(
    bool newValue,
    Permission permission,
    void Function(bool) updateState,
  ) async {
    print("DEBUG: ${permission.toString()} tıklatıldı. Yeni değer: $newValue");

    try {
      var status = await permission.status;
      print("DEBUG: İşlem öncesi sistem durumu: $status");

      if (newValue) {
        // Kullanıcı izni "açmak" istiyor
        if (status.isGranted) {
          // Zaten verilmiş
          updateState(true);
          return;
        }

        if (status.isPermanentlyDenied || status.isRestricted) {
          // Kalıcı reddedilmiş -> Ayarlara yönlendir (kullanıcı onayı ile)
          _showOpenSettingsDialog(permission);
          return;
        }

        // Diğer durumlarda (denied vb.) permission.request() deneyelim
        final granted = await _ensurePermission(permission);
        if (granted) {
          updateState(true);
        } else {
          updateState(false);
        }
      } else {
        // Kullanıcı izni kapatmak istiyor - uygulama içinden kapatma yok, Ayarlar'a yönlendir
        _showOpenSettingsDialog(permission);
      }
    } catch (e) {
      print("DEBUG ERROR: _handlePermissionToggle sırasında hata: $e");
    } finally {
      // İzin değişmiş olabilir; kontrol et
      if (mounted) {
        Future.delayed(
          const Duration(milliseconds: 600),
          () => _checkAllPermissions(),
        );
      }
    }
  }

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
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 13.sp,
                    color: Colors.grey.shade500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          CupertinoSwitch(
            value: value,
            activeColor: const Color(0xFFF27954), // Turuncu tonu
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // --- KAYIT BİTİRME ---
  Future<void> _finishRegistration() async {
    if (_isRegistering) return;
    setState(() => _isRegistering = true);
    print("DEBUG: Kayıt işlemi başlatıldı...");
    try {
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

      final newUser = UserEntity(
        userID: getIt<FirebaseAuth>().currentUser!.uid,
        username: _usernameController.text.trim(),
        nameSurname: _nameController.text.trim(),
        email: _detectedUniversity != null
            ? _universityController.text.trim()
            : '',
        birthDate: _selectedDate ?? DateTime.now(),
        gender: GenderEnum.fromString(_genderDisplayController.text),
        university: _detectedUniversity,
        universityEmail: _detectedUniversity != null
            ? _universityController.text.trim()
            : null,
        isUniversityVerified: _detectedUniversity != null,
        profileImageUrl: profileImageUrl,
        bio: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
        followeeCount: 0,
        hobbies: List.from(_selectedInterests),
        followerCount: 0,
        accountType: AccountType.personal,
        phoneNumber: getIt<AuthService>().getUserPhoneNumber(),
        instagram: '',
      );

      await getIt<UserRepository>().createUser(newUser);
      print("DEBUG: Kayıt BAŞARILI. Ana sayfaya yönlendiriliyor...");
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      print("DEBUG ERROR: Kayıt sırasında hata: $e");
      if (mounted) _showError('Kayıt tamamlanamadı: $e');
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  // --- YARDIMCI FONKSİYONLAR ---
  void _onUniversityEmailChanged(String email) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => _checkUniversity(email),
    );
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
      setState(
        () => _detectedUniversity = uniNames.isNotEmpty ? uniNames.first : null,
      );
    } catch (_) {
      setState(() => _detectedUniversity = null);
    }
  }

  void _showDatePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        height: 300.h,
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          initialDateTime: DateTime.now().subtract(
            const Duration(days: 365 * 18),
          ),
          onDateTimeChanged: (d) => setState(() {
            _selectedDate = d;
            _dobController.text = DateFormat('dd/MM/yyyy').format(d);
          }),
        ),
      ),
    );
  }

  void _showGenderPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomActionBottomSheet(
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
            icon: Icons.block,
            text: 'Belirtmek İstemiyorum',
            onTap: () => _selectGender('Belirtmek İstemiyorum'),
          ),
        ],
      ),
    );
  }

  void _selectGender(String gender) {
    setState(() => _genderDisplayController.text = gender);
    Navigator.pop(context);
  }

  void _toggleInterest(String interest) {
    setState(() {
      _selectedInterests.contains(interest)
          ? _selectedInterests.remove(interest)
          : _selectedInterests.add(interest);
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent.shade400,
      ),
    );
  }

  void _nextPage() => _pageController.nextPage(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );
  void _prevPage() => _currentIndex > 0
      ? _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        )
      : context.pop();

  // Helpers for picking images with permission flow
  Future<void> _pickFromCamera() async {
    final granted = await _ensurePermission(Permission.camera);
    if (!granted) return;
    try {
      final picked = await _picker.pickImage(source: ImageSource.camera);
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
        _checkAllPermissions();
      }
    } catch (e) {
      print("DEBUG ERROR: _pickFromCamera hata: $e");
      _showError('Kamera ile fotoğraf alınırken hata oluştu.');
    }
  }

  Future<void> _pickFromGallery() async {
    final granted = await _ensurePermission(Permission.photos);
    if (!granted) return;
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
        _checkAllPermissions();
      }
    } catch (e) {
      print("DEBUG ERROR: _pickFromGallery hata: $e");
      _showError('Galeriden fotoğraf seçilirken hata oluştu.');
    }
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
            RegisterStepView(
              title: 'Kullanıcı Adı',
              controller: _usernameController,
              onNext: () async {
                if (await getIt<UserRepository>().doesUsernameExist(
                  _usernameController.text.trim(),
                )) {
                  _showError('Bu kullanıcı adı alınmış!');
                } else {
                  _nextPage();
                }
              },
              hintText: '@kullaniciadi',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9._]')),
                TextInputFormatter.withFunction(
                  (old, newVal) =>
                      newVal.copyWith(text: newVal.text.toLowerCase()),
                ),
              ],
            ),
            RegisterStepView(
              title: 'Ad - Soyad',
              controller: _nameController,
              onNext: _nextPage,
              inputFormatters: [TitleCaseFormatter()],
            ),
            RegisterStepView(
              title: 'Doğum Tarihi',
              controller: _dobController,
              onNext: _nextPage,
              readOnly: true,
              onTapInput: _showDatePicker,
            ),
            RegisterStepView(
              title: 'Üniversite Doğrulama',
              controller: _universityController,
              onChanged: _onUniversityEmailChanged,
              onNext: () async {
                setState(() => _isSendingEmail = true);
                try {
                  await getIt<UserRepository>().sendVerificationEmail(
                    _universityController.text.trim(),
                  );
                  _nextPage();
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
              customContent: OtpRow(controllers: _eduOtpControllers),
              onNext: () async {
                try {
                  await getIt<UserRepository>().verifyEmail(
                    _universityController.text.trim(),
                    _detectedUniversity!,
                    _eduOtpControllers.map((c) => c.text).join(),
                  );
                  _nextPage();
                } catch (e) {
                  if (mounted) _showError('Kod hatalı!');
                }
              },
            ),
            RegisterStepView(
              title: 'Cinsiyet',
              controller: _genderDisplayController,
              onNext: _nextPage,
              readOnly: true,
              onTapInput: _showGenderPicker,
            ),
            // PROFIL FOTOĞRAFI ADIMI - geliştirildi
            RegisterStepView(
              title: 'Profil Fotoğrafı',
              onNext: _nextPage,
              customContent: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => CustomActionBottomSheet(
                      options: [
                        BottomSheetOption(
                          icon: Icons.camera_alt,
                          text: 'Fotoğraf Çek',
                          onTap: () async {
                            Navigator.pop(context);
                            await _pickFromCamera();
                          },
                        ),
                        BottomSheetOption(
                          icon: Icons.image,
                          text: 'Fotoğraflardan Seç',
                          onTap: () async {
                            Navigator.pop(context);
                            await _pickFromGallery();
                          },
                        ),
                      ],
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 70.r,
                  backgroundColor: Colors.grey.shade100,
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : null,
                  child: _selectedImage == null
                      ? Icon(
                          Icons.camera_alt,
                          size: 45.sp,
                          color: Colors.grey.shade600,
                        )
                      : null,
                ),
              ),
            ),
            RegisterStepView(
              title: 'İlgi Alanların',
              onNext: _nextPage,
              customContent: Wrap(
                spacing: 12.w,
                runSpacing: 12.h,
                children: _categories.entries
                    .map(
                      (e) => MapFilterChip(
                        label: e.key.toLowerCase(),
                        emoji: e.value,
                        isSelected: _selectedInterests.contains(e.key),
                        onTap: () => _toggleInterest(e.key),
                      ),
                    )
                    .toList(),
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
                    onChanged: (bool val) {
                      _handlePermissionToggle(
                        val,
                        Permission.notification,
                        (s) => setState(() => _permNotifications = s),
                      );
                    },
                  ),
                  _buildPermissionRow(
                    title: 'Bluetooth',
                    description:
                        'Outnest uygulamasına yakındaki cihazlarla bağlantı kurmak için Bluetooth’u kullanmasına izin verilir.',
                    value: _permBluetooth,
                    onChanged: (bool val) {
                      _handlePermissionToggle(
                        val,
                        Permission.bluetooth,
                        (s) => setState(() => _permBluetooth = s),
                      );
                    },
                  ),
                  _buildPermissionRow(
                    title: 'Konum Servisleri',
                    description:
                        'Outnest uygulamasına bulunduğun konuma göre içerik ve öneriler sunmak için konum bilgine erişmesine izin verilir.',
                    value: _permLocation,
                    onChanged: (bool val) {
                      _handlePermissionToggle(
                        val,
                        Permission.location,
                        (s) => setState(() => _permLocation = s),
                      );
                    },
                  ),
                  _buildPermissionRow(
                    title: 'Kamera',
                    description:
                        'Outnest uygulamasına fotoğraf ve video çekerek paylaşım yapabilmen için kameraya erişmesine izin verilir.',
                    value: _permCamera,
                    onChanged: (bool val) {
                      _handlePermissionToggle(
                        val,
                        Permission.camera,
                        (s) => setState(() => _permCamera = s),
                      );
                    },
                  ),
                  _buildPermissionRow(
                    title: 'Fotoğraflar',
                    description:
                        'Outnest uygulamasına galerinden fotoğraf ve video seçip paylaşabilmen için fotoğraflarına erişmesine izin verilir.',
                    value: _permPhotos,
                    onChanged: (bool val) {
                      _handlePermissionToggle(
                        val,
                        Permission.photos,
                        (s) => setState(() => _permPhotos = s),
                      );
                    },
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'Gizlilik ve veri kullanımı hakkında daha fazla bilgi al',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 12.sp,
                      color: AppColors.tertiaryColor,
                    ),
                  ),
                  SizedBox(height: 30.h),
                  Text(
                    'Cihaz izinlerinizi daha sonra Ayarlar sayfasından düzenleyebilirsiniz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 10.sp,
                      color: const Color(0xFF8E8E93),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
