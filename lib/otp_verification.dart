import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:developer';
import 'api_service.dart';
import 'services/auth_token_storage.dart';

enum OtpPurpose { registration, login, passwordReset }
class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final OtpPurpose purpose;
  final String? password;

  const OtpVerificationScreen({super.key, required this.email, required this.purpose, this.password});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final int otpLength = 6;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  bool _isLoading = false;
  bool _isBulkFilling = false;
  late DateTime _otpExpiry;
  late Duration _remaining;
  Timer? _timer;
  bool _canRegenerate = false;

  /// Matches [verifyOtp] / password-reset API normalization.
  String get _contactForApi {
    final raw = widget.email.trim();
    return raw.contains('@') ? raw.toLowerCase() : raw;
  }

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(otpLength, (_) => FocusNode());
    _startOtpTimer();
  }

  void _startOtpTimer({DateTime? serverExpiryUtc}) {
    if (serverExpiryUtc != null) {
      _otpExpiry =
          serverExpiryUtc.isUtc ? serverExpiryUtc : serverExpiryUtc.toUtc();
    } else {
      _otpExpiry = DateTime.now().add(const Duration(minutes: 10));
    }
    _remaining = _otpExpiry.difference(DateTime.now());
    _canRegenerate = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remaining = _otpExpiry.difference(DateTime.now());
        if (_remaining.inSeconds <= 0) {
          _canRegenerate = true;
          _timer?.cancel();
        }
      });
    });
  }

  String _formatRemaining(Duration d) {
    if (d <= Duration.zero) return '00:00';
    final totalSecs = d.inSeconds;
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _regenerateOtp() async {
    setState(() => _isLoading = true);
    Map<String, dynamic> result;
    switch (widget.purpose) {
      case OtpPurpose.registration:
        result = await sendVerificationOtp(_contactForApi);
        break;
      case OtpPurpose.login:
        result = await sendVerificationOtp(_contactForApi);
        break;
      case OtpPurpose.passwordReset:
        final c = _contactForApi;
        final isEmail = c.contains('@');
        result =
            await sendPasswordResetOtp(isEmail ? c : null, isEmail ? null : c);
        break;
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result['error'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New OTP sent to your email!')),
      );
      DateTime? serverExp;
      final iso = result['otpExpiresAt']?.toString();
      if (iso != null && iso.isNotEmpty) {
        serverExp = DateTime.tryParse(iso);
      }
      if (result['otpHashTruncated'] == true) {
        log(
          'OTP resent but server reports hash truncation — ALTER users.otp to VARCHAR(128)',
          name: 'otp_verification',
        );
      }
      _startOtpTimer(serverExpiryUtc: serverExp);
      for (var c in _controllers) { c.clear(); }
      _focusNodes[0].requestFocus();
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) { c.dispose(); }
    for (var f in _focusNodes) { f.dispose(); }
    _timer?.cancel();
    super.dispose();
  }

  void _onOtpChanged(int idx, String value) {
    if (_isBulkFilling) return;

    final sanitized = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (sanitized.length > 1) {
      _applyBulkOtpInput(sanitized);
      return;
    }

    if (sanitized.isEmpty) {
      _controllers[idx].clear();
      if (idx > 0) {
        _focusNodes[idx - 1].requestFocus();
      }
      return;
    }

    if (sanitized != value) {
      _isBulkFilling = true;
      _controllers[idx]
        ..text = sanitized
        ..selection = TextSelection.collapsed(offset: sanitized.length);
      _isBulkFilling = false;
    }

    if (idx < otpLength - 1) {
      _focusNodes[idx + 1].requestFocus();
    } else {
      _focusNodes[idx].unfocus();
    }
  }

  void _applyBulkOtpInput(String rawInput) {
    final digitsOnly = rawInput.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return;

    final trimmed = digitsOnly.length > otpLength
        ? digitsOnly.substring(0, otpLength)
        : digitsOnly;

    _isBulkFilling = true;
    for (int i = 0; i < otpLength; i++) {
      final char = i < trimmed.length ? trimmed[i] : '';
      _controllers[i]
        ..text = char
        ..selection = TextSelection.collapsed(offset: char.length);
    }
    _isBulkFilling = false;

    final focusIndex = trimmed.length >= otpLength ? otpLength - 1 : trimmed.length;
    if (focusIndex >= 0 && focusIndex < _focusNodes.length) {
      _focusNodes[focusIndex].requestFocus();
    }
  }

  Future<void> _verifyPasswordReset(String otpRaw) async {
    final otpDigits = otpRaw.replaceAll(RegExp(r'[^0-9]'), '');
    if (otpDigits.length != otpLength) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete OTP')),
      );
      return;
    }

    final newPassword = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _PasswordResetDialog(),
    );

    if (!mounted || newPassword == null) return;

    setState(() => _isLoading = true);
    final result = await resetPassword(_contactForApi, otpDigits, newPassword);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['error'] != null) {
      final errorCode = result['code']?.toString();
      final errorMsg = result['error'].toString().toLowerCase();
      String displayMsg;
      if (errorCode == 'ACCOUNT_DEACTIVATED') {
        displayMsg = result['error'].toString();
      } else if (errorCode == 'OTP_EXPIRED' || errorMsg.contains('expired')) {
        displayMsg = 'The OTP has expired. Generate a new OTP.';
      } else if (errorCode == 'OTP_INVALID' || errorMsg.contains('invalid')) {
        displayMsg = 'Incorrect OTP. Check and try again.';
      } else if (errorCode == 'OTP_PAYLOAD_INVALID') {
        displayMsg = result['error'].toString();
      } else {
        displayMsg = result['error'].toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(displayMsg), backgroundColor: Colors.red),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password updated. Please log in.')),
    );
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length != otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete OTP')),
      );
      return;
    }

    if (widget.purpose == OtpPurpose.passwordReset) {
      await _verifyPasswordReset(otp);
      return;
    }

    setState(() => _isLoading = true);
    final result = await verifyOtp(_contactForApi, otp);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result['error'] != null) {
      final errorCode = result['code']?.toString();
      String errorMsg = result['error'].toString().toLowerCase();
      String displayMsg;

      // Check if account is suspended by admin
      if (errorCode == 'ACCOUNT_DEACTIVATED') {
        displayMsg = result['error'].toString();
      } else if (errorCode == 'OTP_EXPIRED' || errorMsg.contains('expired')) {
        displayMsg = 'The OTP has expired. Please generate a new OTP.';
      } else if (errorCode == 'OTP_PAYLOAD_INVALID') {
        displayMsg = result['error'].toString();
      } else if (errorCode == 'OTP_INVALID' || errorMsg.contains('invalid') || errorMsg.contains('incorrect')) {
        displayMsg = 'Incorrect OTP. Please check and retry.';
      } else {
        displayMsg = result['error'].toString();
      }
      final ref = result['debugRef']?.toString();
      if (ref != null && ref.isNotEmpty) {
        displayMsg = '$displayMsg (ref: $ref)';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(displayMsg), backgroundColor: Colors.red),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP verified! Logging you in...')),
      );

      // Save token and user info from OTP verification response
      if (result['token'] != null) {
        await AuthTokenStorage.writeJwt(result['token']);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No token received after OTP verification.'), backgroundColor: Colors.red),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandColor = const Color(0xFF00CA44);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.purpose == OtpPurpose.passwordReset
              ? 'Verify OTP'
              : 'Verify Email',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: brandColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.purpose == OtpPurpose.passwordReset
                  ? 'Enter the 6-digit OTP sent to your email to reset your password'
                  : 'Enter the 6-digit OTP sent to your email',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: brandColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _canRegenerate
                  ? 'OTP expired. You can generate a new one.'
                  : 'OTP expires in: ${_formatRemaining(_remaining)}',
              style: TextStyle(fontSize: 16, color: _canRegenerate ? Colors.red : Colors.black54),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                // Calculate responsive box size based on available width
                final availableWidth = constraints.maxWidth;
                // Each box has 3px margin on left and right = 6px total per box
                // 6 boxes = 36px total margin
                final totalMargin = 6.0 * otpLength;
                // Calculate box width that will actually fit
                final calculatedBoxWidth = (availableWidth - totalMargin) / otpLength;
                // Use calculated width directly (no clamp) to ensure it fits
                final boxWidth = calculatedBoxWidth > 44.0 ? 44.0 : calculatedBoxWidth;
                final boxHeight = boxWidth * 1.27;
                final fontSize = boxWidth * 0.5;
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(otpLength, (idx) => Container(
                    width: boxWidth,
                    height: boxHeight,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: brandColor.withAlpha(20), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                      border: Border.all(color: brandColor.withAlpha(128), width: 1.5),
                    ),
                    child: Center(
                      child: TextField(
                        controller: _controllers[idx],
                        focusNode: _focusNodes[idx],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLengthEnforcement: MaxLengthEnforcement.none,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textInputAction:
                            idx == otpLength - 1 ? TextInputAction.done : TextInputAction.next,
                        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onChanged: (val) => _onOtpChanged(idx, val),
                        onTap: () => _controllers[idx].selection = TextSelection(baseOffset: 0, extentOffset: _controllers[idx].text.length),
                      ),
                    ),
                  )),
                );
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading || _canRegenerate ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verify', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: _isLoading ? null : () {
                for (var c in _controllers) { c.clear(); }
                _focusNodes[0].requestFocus();
              },
              child: Text('Clear OTP', style: TextStyle(color: brandColor, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _canRegenerate && !_isLoading ? _regenerateOtp : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canRegenerate ? brandColor : Colors.grey,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Generate New OTP'),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Collects new password after OTP in the forgot-password flow.
class _PasswordResetDialog extends StatefulWidget {
  const _PasswordResetDialog();

  @override
  State<_PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<_PasswordResetDialog> {
  static const _brandColor = Color(0xFF00CA44);

  final _formKey = GlobalKey<FormState>();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  String? _validatePw(String? value) {
    if (value == null || value.isEmpty) return 'Enter a new password';
    if (value.length < 6 || value.length > 11) {
      return 'Password must be 6–11 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Include at least one uppercase letter';
    }
    return null;
  }

  InputDecoration _passwordDecoration({
    required String label,
    required bool obscure,
    required VoidCallback onToggleVisibility,
    required ColorScheme cs,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: cs.primary, fontWeight: FontWeight.w500),
      hintText: label == 'New password' ? '6–11 chars, one uppercase letter' : null,
      hintStyle: TextStyle(
        color: cs.onSurface.withValues(alpha: 0.45),
        fontSize: 13,
      ),
      filled: true,
      fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.35),
      prefixIcon: Icon(Icons.lock_outline_rounded, color: cs.primary),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: cs.onSurface.withValues(alpha: 0.55),
        ),
        onPressed: onToggleVisibility,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _brandColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isTablet = MediaQuery.sizeOf(context).width > 600;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: isTablet ? 48 : 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 28 : 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.lock_reset_rounded, color: cs.primary, size: 44),
                const SizedBox(height: 14),
                Text(
                  'Choose new password',
                  style: TextStyle(
                    fontSize: isTablet ? 22 : 20,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Use 6–11 characters with at least one uppercase letter.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: cs.onSurface.withValues(alpha: 0.72),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _pw,
                  obscureText: _obscureNew,
                  textInputAction: TextInputAction.next,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: _passwordDecoration(
                    label: 'New password',
                    obscure: _obscureNew,
                    onToggleVisibility: () =>
                        setState(() => _obscureNew = !_obscureNew),
                    cs: cs,
                  ),
                  validator: _validatePw,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pw2,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: _passwordDecoration(
                    label: 'Confirm password',
                    obscure: _obscureConfirm,
                    onToggleVisibility: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    cs: cs,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirm your password';
                    if (v != _pw.text) return 'Passwords do not match';
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(context, _pw.text);
                    }
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.primary,
                          side: BorderSide(color: cs.primary.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            Navigator.pop(context, _pw.text);
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _brandColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

