import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/provider/auth_provider.dart';
import 'package:retro_vibes/screens/bottom_navigation.dart';
import 'package:retro_vibes/services/otp_service.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String? name;
  final String? password;
  final String? role;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.name,
    this.password,
    this.role,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _digitControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _digitFocusNodes = List.generate(4, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  int _cooldownSeconds = 60;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startCooldownTimer();
  }

  void _startCooldownTimer() {
    setState(() {
      _cooldownSeconds = 60;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        setState(() {
          _cooldownSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    for (var controller in _digitControllers) {
      controller.dispose();
    }
    for (var node in _digitFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _enteredOtpCode {
    return _digitControllers.map((c) => c.text.trim()).join();
  }

  Future<void> _handleVerifyOtp() async {
    final code = _enteredOtpCode;

    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all 4 digits of the OTP code.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final isValid = await OtpService.instance.verifyOtp(
        email: widget.email,
        enteredOtp: code,
      );

      if (isValid && mounted) {
        final authProvider = context.read<AuthProvider>();
        bool success = false;

        // ONLY NOW create Firebase account after 4-digit OTP is verified!
        if (widget.name != null && widget.password != null) {
          success = await authProvider.signUp(
            name: widget.name!,
            email: widget.email,
            password: widget.password!,
            role: widget.role ?? 'user',
          );
        } else {
          success = await authProvider.loginWithOtpVerifiedEmail(widget.email);
        }

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email Verified & Account Created Successfully!'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const BottomNavigation()),
            (route) => false,
          );
        } else if (mounted) {
          setState(() => _isVerifying = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Account creation failed. Please try again.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
      });
      if (mounted) {
        final errText = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errText),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleResendOtp() async {
    if (_cooldownSeconds > 0 || _isResending) return;

    setState(() {
      _isResending = true;
    });

    try {
      await OtpService.instance.sendOtpToEmail(widget.email, userName: widget.name);
      _startCooldownTimer();

      if (mounted) {
        setState(() {
          _isResending = false;
          for (var c in _digitControllers) {
            c.clear();
          }
        });
        _digitFocusNodes[0].requestFocus();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('A new 4-digit OTP has been sent to ${widget.email}'),
            backgroundColor: AppTheme.cardBackground,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResending = false);
        final errText = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errText), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double mediaHeight = MediaQuery.of(context).size.height;
    double mediaWidth = MediaQuery.of(context).size.width;

    final boxSize = (mediaWidth * 0.16).clamp(52.0, 72.0);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.white, size: mediaWidth * 0.055),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: mediaWidth * 0.07),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: mediaHeight * 0.02),

              // Header Branding
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.cardBackground,
                  border: Border.all(color: AppTheme.primaryAccent, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryAccent.withValues(alpha: 0.25),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(Icons.mark_email_read, color: AppTheme.primaryAccent, size: mediaWidth * 0.12),
              ),

              SizedBox(height: mediaHeight * 0.03),

              Text(
                'Verify Your Email',
                style: TextStyle(
                  color: AppTheme.white,
                  fontSize: mediaWidth * 0.065,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: mediaHeight * 0.01),

              Text(
                "We've sent a 4-digit verification code to:",
                style: TextStyle(color: AppTheme.white38, fontSize: mediaWidth * 0.033),
              ),
              const SizedBox(height: 2),
              Text(
                OtpService.instance.maskEmail(widget.email),
                style: TextStyle(
                  color: AppTheme.primaryAccent,
                  fontSize: mediaWidth * 0.04,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: mediaHeight * 0.04),

              // 4 Individual Digit Input Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  return SizedBox(
                    width: boxSize,
                    height: boxSize,
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.backspace &&
                            _digitControllers[index].text.isEmpty &&
                            index > 0) {
                          _digitFocusNodes[index - 1].requestFocus();
                        }
                      },
                      child: TextField(
                        controller: _digitControllers[index],
                        focusNode: _digitFocusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: TextStyle(
                          color: AppTheme.white,
                          fontSize: mediaWidth * 0.065,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: AppTheme.cardBackground,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Colors.white24, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppTheme.primaryAccent, width: 2),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 3) {
                            _digitFocusNodes[index + 1].requestFocus();
                          }
                          if (value.isEmpty && index > 0) {
                            _digitFocusNodes[index - 1].requestFocus();
                          }
                          if (_enteredOtpCode.length == 4) {
                            _handleVerifyOtp();
                          }
                        },
                      ),
                    ),
                  );
                }),
              ),

              SizedBox(height: mediaHeight * 0.04),

              // Verify OTP Main Action Button
              SizedBox(
                width: double.infinity,
                height: mediaHeight * 0.065,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  onPressed: _isVerifying ? null : _handleVerifyOtp,
                  child: _isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Verify OTP',
                          style: TextStyle(
                            color: AppTheme.white,
                            fontSize: mediaWidth * 0.045,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              SizedBox(height: mediaHeight * 0.03),

              // Resend OTP Section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the OTP? ",
                    style: TextStyle(color: AppTheme.white38, fontSize: mediaWidth * 0.035),
                  ),
                  GestureDetector(
                    onTap: (_cooldownSeconds > 0 || _isResending) ? null : _handleResendOtp,
                    child: Text(
                      _cooldownSeconds > 0 ? 'Resend in ${_cooldownSeconds}s' : 'Resend OTP',
                      style: TextStyle(
                        color: _cooldownSeconds > 0 ? AppTheme.white38 : AppTheme.primaryAccent,
                        fontSize: mediaWidth * 0.035,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: mediaHeight * 0.04),
            ],
          ),
        ),
      ),
    );
  }
}
