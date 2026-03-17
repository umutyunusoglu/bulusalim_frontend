import 'package:outnest/application/service_locators/get_it_init.dart';
import 'package:outnest/domain/datasources/university_datasource.dart';
import 'package:outnest/domain/repositories/user_repository.dart';
import 'package:flutter/material.dart';

class DebugVerificationScreen extends StatefulWidget {
  const DebugVerificationScreen({super.key});

  @override
  State<DebugVerificationScreen> createState() =>
      _DebugVerificationScreenState();
}

class _DebugVerificationScreenState extends State<DebugVerificationScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isCodeSent = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _detectedUniversity; // Tespit edilen üniversite adı

  // E-posta her değiştiğinde üniversiteyi kontrol eder
  Future<void> _onEmailChanged(String email) async {
    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _detectedUniversity = null;
        _errorMessage = null;
      });
      return;
    }

    try {
      // Sizin yazdığınız datasource metodunu çağırıyoruz
      final uniNames = await getIt<UniversityDatasource>().getUniversityOfMail(
        email,
        'Turkiye',
      );

      setState(() {
        if (uniNames.isNotEmpty) {
          _detectedUniversity = uniNames.first;
          _errorMessage = null;
        } else {
          _detectedUniversity = null;
          _errorMessage =
              'Bu e-posta adresi tanınan bir üniversiteye ait değil.';
        }
      });
    } catch (e) {
      _logger('Uni Check Error: $e');
    }
  }

  // 1. ADIM: Cloud Function tetikleme
  Future<void> _handleSendCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await getIt<UserRepository>().sendVerificationEmail(
        _emailController.text.trim(),
      );

      _logger('OTP Gönderildi: ${_emailController.text}');
      setState(() => _isCodeSent = true);
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. ADIM: OTP Doğrulama
  Future<void> _handleVerifyOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await getIt<UserRepository>().verifyEmail(
        _emailController.text.trim(),
        _detectedUniversity!,
        _otpController.text.trim(),
      );

      _logger('Doğrulama Başarılı!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Başarıyla doğrulandı!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _logger(String msg) => print('[DEBUG_AUTH]: $msg');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Üniversite Doğrulama Debug')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              _isCodeSent ? Icons.verified_user : Icons.account_balance,
              size: 80,
              color: _detectedUniversity != null ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 32),

            if (!_isCodeSent) ...[
              TextField(
                controller: _emailController,
                onChanged: _onEmailChanged,
                decoration: InputDecoration(
                  labelText: 'Üniversite E-postası',
                  errorText: _errorMessage,
                  prefixIcon: const Icon(Icons.email),
                  border: const OutlineInputBorder(),
                  helperText: _detectedUniversity != null
                      ? 'Tespit Edildi: $_detectedUniversity'
                      : 'Lütfen .edu uzantılı mailinizi girin',
                  helperStyle: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (_isLoading || _detectedUniversity == null)
                    ? null
                    : _handleSendCode,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('DOĞRULAMA KODU GÖNDER'),
              ),
            ] else ...[
              Text(
                '${_emailController.text}\nadresine gönderilen kodu girin.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _otpController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  labelText: '6 Haneli Kod',
                  errorText: _errorMessage,
                  border: const OutlineInputBorder(),
                ),
                maxLength: 6,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleVerifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('KODU ONAYLA'),
              ),
              TextButton(
                onPressed: () => setState(() => _isCodeSent = false),
                child: const Text('E-postayı Düzenle'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
