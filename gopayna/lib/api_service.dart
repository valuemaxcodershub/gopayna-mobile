import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

// Production API URL
const String _productionApiOrigin = 'https://api.gopayna.com';

// Set to true to use production API, false for local development
const bool _useProductionApi = true;

// Dynamic API origin based on platform and build mode:
String get apiOrigin {
  // Always use production when _useProductionApi is true (regardless of debug mode or platform)
  if (_useProductionApi) {
    return _productionApiOrigin;
  }

  // Development mode with local API (only when _useProductionApi is false)
  if (!kDebugMode) {
    return _productionApiOrigin;
  }

  if (kIsWeb) {
    return 'http://localhost:3000';
  }
  // For mobile platforms
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:3000';
  }
  // iOS simulator and macOS use localhost
  return 'http://localhost:3000';
}

String get baseUrl => '$apiOrigin/api/auth';
String get paystackBaseUrl => '$apiOrigin/api/paystack';

Future<Map<String, dynamic>> sendVerificationOtp(String email) async {
  try {
    // If input contains '@', treat as email, else as phone
    final isEmail = email.contains('@');
    final response = await http.post(
      Uri.parse('$baseUrl/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(isEmail ? {'email': email} : {'phone': email}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {'error': 'Failed to send OTP'};
    }
  } catch (e) {
    return {'error': 'An error occurred while sending OTP'};
  }
}

Future<Map<String, dynamic>> registerUser(String firstName, String lastName,
    String phone, String email, String password, String referralCode) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'email': email,
        'password': password,
        'referralCode': referralCode,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      // Log error details to console
      log('Registration error: status ${response.statusCode}, body: ${response.body}',
          name: 'api_service');
      return {
        'error': _extractErrorMessage(response.body, response.statusCode),
        'status': response.statusCode,
      };
    }
  } catch (e) {
    log('An exception occurred during registration: $e', name: 'api_service');
    return {'error': 'An error occurred during registration'};
  }
}

Future<Map<String, dynamic>> loginUser(
    String usernameOrEmail, String password) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identifier': usernameOrEmail, // <-- use 'identifier'
        'password': password,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      // Log error details to console
      log('Login error: status ${response.statusCode}, body: ${response.body}',
          name: 'api_service');
      
      // Parse response to extract error and email (for OTP verification redirect)
      try {
        final decoded = jsonDecode(response.body);
        return {
          'error': decoded['error']?.toString() ?? _extractErrorMessage(response.body, response.statusCode),
          'email': decoded['email'], // Include email for OTP redirect
          'code': decoded['code'],   // Include error code (e.g., ACCOUNT_DEACTIVATED)
          'status': response.statusCode,
        };
      } catch (e) {
        return {
          'error': _extractErrorMessage(response.body, response.statusCode),
          'status': response.statusCode,
        };
      }
    }
  } catch (e) {
    log('Login exception: $e', name: 'api_service');
    return {'error': 'Unable to connect. Please check your internet connection.'};
  }
}

String _extractErrorMessage(String body, int statusCode) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map && decoded.containsKey('error')) {
      return decoded['error'].toString();
    } else if (decoded is Map && decoded.containsKey('message')) {
      return decoded['message'].toString();
    } else {
      return body;
    }
  } catch (e) {
    return 'HTTP $statusCode: $body';
  }
}

/// Cached platform settings
PlatformSettings? _cachedPlatformSettings;
DateTime? _settingsCacheTime;
const _settingsCacheDuration = Duration(minutes: 5);

/// Platform settings model
class PlatformSettings {
  final bool maintenanceMode;
  final bool allowRegistrations;
  final double maxWalletBalance;
  final double maxFundingAmount;
  final double minFundingAmount;
  final double referralBonusAmount;

  PlatformSettings({
    this.maintenanceMode = false,
    this.allowRegistrations = true,
    this.maxWalletBalance = 100000,
    this.maxFundingAmount = 40000,
    this.minFundingAmount = 100,
    this.referralBonusAmount = 6,
  });

  factory PlatformSettings.fromJson(Map<String, dynamic> json) {
    return PlatformSettings(
      maintenanceMode: json['maintenanceMode'] == true,
      allowRegistrations: json['allowRegistrations'] != false,
      maxWalletBalance: (json['maxWalletBalance'] ?? 100000).toDouble(),
      maxFundingAmount: (json['maxFundingAmount'] ?? 40000).toDouble(),
      minFundingAmount: (json['minFundingAmount'] ?? 100).toDouble(),
      referralBonusAmount: (json['referralBonusAmount'] ?? 6).toDouble(),
    );
  }

  /// Default settings for fallback
  static PlatformSettings get defaults => PlatformSettings();
}

/// Fetch platform settings from API (cached for 5 minutes)
Future<PlatformSettings> fetchPlatformSettings({bool forceRefresh = false}) async {
  // Return cached if valid
  if (!forceRefresh &&
      _cachedPlatformSettings != null &&
      _settingsCacheTime != null &&
      DateTime.now().difference(_settingsCacheTime!) < _settingsCacheDuration) {
    return _cachedPlatformSettings!;
  }

  try {
    final response = await http.get(
      Uri.parse('$baseUrl/platform-settings'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _cachedPlatformSettings = PlatformSettings.fromJson(data);
      _settingsCacheTime = DateTime.now();
      return _cachedPlatformSettings!;
    } else {
      log('Failed to fetch platform settings: ${response.statusCode}',
          name: 'api_service');
      return _cachedPlatformSettings ?? PlatformSettings.defaults;
    }
  } catch (e) {
    log('Error fetching platform settings: $e', name: 'api_service');
    return _cachedPlatformSettings ?? PlatformSettings.defaults;
  }
}

Future<Map<String, dynamic>> forgotPassword(String email) async {
  try {
    final res = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      return {'error': 'Failed to send reset link. Please try again.'};
    }
  } catch (e) {
    return {'error': 'An error occurred. Please try again later.'};
  }
}

Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
  try {
    // If input contains '@', treat as email, else as phone
    final isEmail = email.contains('@');
    final response = await http.post(
      Uri.parse('$baseUrl/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(isEmail
          ? {'email': email, 'otp': otp}
          : {'phone': email, 'otp': otp}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      // Parse response to extract error and code
      try {
        final decoded = json.decode(response.body);
        return {
          'error': decoded['error']?.toString() ?? 'Failed to verify OTP',
          'code': decoded['code'],
        };
      } catch (e) {
        return {'error': 'Failed to verify OTP'};
      }
    }
  } catch (e) {
    return {'error': 'An error occurred while verifying OTP'};
  }
}

Future<Map<String, dynamic>> sendPasswordResetOtp(
    String? email, String? phone) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/send-password-reset-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      // Parse response to extract error and code
      try {
        final decoded = json.decode(response.body);
        return {
          'error': decoded['error']?.toString() ?? 'Failed to send OTP',
          'code': decoded['code'],
        };
      } catch (e) {
        return {'error': 'Failed to send OTP'};
      }
    }
  } catch (e) {
    return {'error': 'An error occurred while sending OTP'};
  }
}

Future<Map<String, dynamic>> resetPassword(
    String email, String otp, String newPassword) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      // Parse response to extract error and code
      try {
        final decoded = json.decode(response.body);
        return {
          'error': decoded['error']?.toString() ?? 'Failed to reset password',
          'code': decoded['code'],
        };
      } catch (e) {
        return {'error': 'Failed to reset password'};
      }
    }
  } catch (e) {
    return {'error': 'An error occurred while resetting password'};
  }
}

Future<Map<String, dynamic>> fetchUserProfile(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: _authorizedJsonHeaders(token),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    return {
      'error': _extractErrorMessage(response.body, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Fetch profile failed: $e', name: 'api_service');
    return {'error': 'Unable to load profile'};
  }
}

Future<Map<String, dynamic>> uploadProfilePhoto({
  required String token,
  required File photo,
}) async {
  try {
    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$baseUrl/profile/photo'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    final ext = p.extension(photo.path).replaceFirst('.', '').toLowerCase();
    final mediaType = MediaType('image', ext.isEmpty ? 'jpeg' : ext);
    request.files.add(
      await http.MultipartFile.fromPath(
        'photo',
        photo.path,
        contentType: mediaType,
      ),
    );
    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
      return jsonDecode(body);
    }
    return {
      'error': _extractErrorMessage(body, streamed.statusCode),
      'status': streamed.statusCode,
    };
  } catch (e) {
    log('Upload profile photo failed: $e', name: 'api_service');
    return {'error': 'Unable to upload profile photo'};
  }
}

Future<double?> fetchWalletBalance(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/wallet'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('wallet_balance')) {
        return double.tryParse(data['wallet_balance'].toString());
      }
    } else if (response.statusCode == 404) {
      log('Wallet endpoint not found (404)', name: 'api_service');
      return null;
    } else {
      log('Wallet fetch error: status ${response.statusCode}, body: ${response.body}',
          name: 'api_service');
      return null;
    }
    return null;
  } catch (e) {
    log('Failed to fetch wallet balance: $e', name: 'api_service');
    return null;
  }
}

Map<String, String> _jsonHeaders() => {
      'Content-Type': 'application/json',
    };

Map<String, String> _authorizedJsonHeaders(String token) => {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

// ===========================
// Request Signing for Security
// ===========================

/// App secret key for request signing (must match server's APP_SIGNING_SECRET)
///
/// Build-time configuration via --dart-define:
///   flutter run --dart-define=APP_SIGNING_SECRET=your_secret_here
///   flutter build apk --dart-define=APP_SIGNING_SECRET=your_secret_here
///
/// IMPORTANT: Never commit the production secret to version control!
const String _appSigningKey = String.fromEnvironment(
  'APP_SIGNING_SECRET',
  defaultValue:
      'GPN_VTU_8f3K9mL2pR7xQ4wN1vB6jH0tY5sA3dE8cU2iO9gF4zX7nM1kJ6bW0qP5rT',
);

/// App identifier for the mobile app
const String _appId = 'gopayna_mobile_v1';

/// Generate a signature for the request
/// Uses HMAC-SHA256 with timestamp to prevent replay attacks
/// Algorithm matches backend's verifyRequestSignature middleware
String _generateRequestSignature({
  required String timestamp,
  String? body,
}) {
  // Create body hash (SHA256 of the JSON body)
  final bodyString = body ?? '{}';
  final bodyHash = sha256.convert(utf8.encode(bodyString)).toString();

  // Data to sign: timestamp + bodyHash (must match backend algorithm)
  final dataToSign = '$timestamp$bodyHash';

  // Generate HMAC-SHA256 signature
  final hmac = Hmac(sha256, utf8.encode(_appSigningKey));
  final digest = hmac.convert(utf8.encode(dataToSign));

  return digest.toString();
}

/// Get signed headers for sensitive API calls (purchases, wallet operations)
/// Includes HMAC-SHA256 signature that backend verifies
Map<String, String> _signedAuthorizedHeaders(
  String token, {
  String? body,
}) {
  final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
  final signature = _generateRequestSignature(
    timestamp: timestamp,
    body: body,
  );

  // Format: "timestamp.signature" to match backend expectation
  final signatureHeader = '$timestamp.$signature';

  return {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
    'X-App-Id': _appId,
    'X-Request-Timestamp': timestamp,
    'X-Request-Signature': signatureHeader,
  };
}

Future<Map<String, dynamic>> initializePaystackPayment({
  required String token,
  required int amount,
  String? reference,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$paystackBaseUrl/initialize'),
      headers: _authorizedJsonHeaders(token),
      body: jsonEncode({
        'amount': amount,
        if (reference != null) 'reference': reference,
      }),
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded['data'] ?? decoded};
    }
    return {
      'error': decoded['error'] ??
          _extractErrorMessage(response.body, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Initialize Paystack payment failed: $e', name: 'api_service');
    return {'error': 'Unable to start Paystack checkout. Please try again.'};
  }
}

Future<Map<String, dynamic>> verifyPaystackPayment({
  required String token,
  required String reference,
}) async {
  try {
    final response = await http.get(
      Uri.parse('$paystackBaseUrl/verify/$reference'),
      headers: _authorizedJsonHeaders(token),
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {
        'success': true,
        'data': decoded,
      };
    }
    return {
      'error': decoded['error'] ??
          _extractErrorMessage(response.body, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Verify Paystack payment failed: $e', name: 'api_service');
    return {'error': 'Unable to verify payment status. Please try again.'};
  }
}

Future<Map<String, dynamic>> fetchWalletTransactions({
  required String token,
  int limit = 10,
}) async {
  try {
    final response = await http.get(
      Uri.parse('$paystackBaseUrl/transactions?limit=$limit'),
      headers: _authorizedJsonHeaders(token),
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data =
          (decoded['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return {'success': true, 'data': data};
    }
    return {
      'error': decoded['error'] ??
          _extractErrorMessage(response.body, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Fetch wallet transactions failed: $e', name: 'api_service');
    return {'error': 'Unable to fetch wallet transactions. Please try again.'};
  }
}

Future<Map<String, dynamic>> fetchPaystackBanks({
  required String token,
}) async {
  try {
    final response = await http.get(
      Uri.parse('$paystackBaseUrl/banks'),
      headers: _authorizedJsonHeaders(token),
    );
    final body = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final banks =
          (decoded['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return {'success': true, 'data': banks};
    }
    return {
      'error':
          decoded['error'] ?? _extractErrorMessage(body, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Fetch Paystack banks failed: $e', name: 'api_service');
    return {'error': 'Unable to load banks at the moment. Please try again.'};
  }
}

Future<Map<String, dynamic>> resolveBankAccount({
  required String token,
  required String accountNumber,
  required String bankCode,
}) async {
  try {
    final response = await http.get(
      Uri.parse(
          '$paystackBaseUrl/resolve-account?account_number=$accountNumber&bank_code=$bankCode'),
      headers: _authorizedJsonHeaders(token),
    );
    final body = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded['data'] ?? decoded};
    }
    return {
      'error':
          decoded['error'] ?? _extractErrorMessage(body, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Resolve bank account failed: $e', name: 'api_service');
    return {'error': 'Unable to verify bank account. Please try again.'};
  }
}

Future<Map<String, dynamic>> withdrawToBank({
  required String token,
  required double amount,
  required String accountNumber,
  required String bankCode,
  required String pin,
  String? bankName,
  String? accountName,
  String? reason,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$paystackBaseUrl/withdraw'),
      headers: _authorizedJsonHeaders(token),
      body: jsonEncode({
        'amount': amount,
        'accountNumber': accountNumber,
        'bankCode': bankCode,
        'pin': pin,
        if (bankName != null) 'bankName': bankName,
        if (accountName != null) 'accountName': accountName,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      }),
    );
    final body = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded};
    }
    return {
      'error':
          decoded['error'] ?? _extractErrorMessage(body, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Withdraw to bank failed: $e', name: 'api_service');
    return {'error': 'Unable to complete withdrawal at the moment.'};
  }
}

Future<Map<String, dynamic>> sendWithdrawalPinOtpRequest(String token) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/withdrawal-pin/send-otp'),
      headers: _authorizedJsonHeaders(token),
    );
    final body = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded};
    }
    return {
      'error':
          decoded['error'] ?? _extractErrorMessage(body, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Send withdrawal pin OTP failed: $e', name: 'api_service');
    return {'error': 'Unable to send OTP right now. Please try again.'};
  }
}

Future<Map<String, dynamic>> setWithdrawalPin({
  required String token,
  required String pin,
  required String otp,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$paystackBaseUrl/set-pin'),
      headers: _authorizedJsonHeaders(token),
      body: jsonEncode({'pin': pin, 'otp': otp}),
    );
    final body = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded};
    }
    return {
      'error':
          decoded['error'] ?? _extractErrorMessage(body, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Set withdrawal pin failed: $e', name: 'api_service');
    return {'error': 'Unable to update withdrawal PIN. Please try again.'};
  }
}

Future<Map<String, dynamic>> fetchWithdrawalPinStatus({
  required String token,
}) async {
  try {
    final response = await http.get(
      Uri.parse('$paystackBaseUrl/pin/status'),
      headers: _authorizedJsonHeaders(token),
    );
    final body = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final pinSet = decoded['pinSet'] == true || decoded['pin_set'] == true;
      return {
        'success': true,
        'pinSet': pinSet,
      };
    }
    return {
      'error':
          decoded['error'] ?? _extractErrorMessage(body, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Fetch withdrawal pin status failed: $e', name: 'api_service');
    return {'error': 'Unable to check withdrawal PIN status right now.'};
  }
}

Future<Map<String, dynamic>> requestAccountDeactivation({
  required String token,
  String? reason,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/deactivate-request'),
      headers: _authorizedJsonHeaders(token),
      body: jsonEncode({
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      }),
    );
    final body = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded};
    }
    return {
      'error':
          decoded['error'] ?? _extractErrorMessage(body, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Account deactivation request failed: $e', name: 'api_service');
    return {
      'error':
          'Unable to submit deactivation request right now. Please try again.'
    };
  }
}

Future<Map<String, dynamic>> fetchReferralHistory({
  required String token,
  int limit = 20,
}) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/referrals/history?limit=$limit'),
      headers: _authorizedJsonHeaders(token),
    );
    final body = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data =
          (decoded['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return {'success': true, 'data': data};
    }
    return {
      'error':
          decoded['error'] ?? _extractErrorMessage(body, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Fetch referral history failed: $e', name: 'api_service');
    return {'error': 'Unable to load referral history. Please try again.'};
  }
}

Future<Map<String, dynamic>> transferReferralEarnings({
  required String token,
  double? amount,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/referrals/withdraw'),
      headers: _authorizedJsonHeaders(token),
      body: jsonEncode({
        if (amount != null) 'amount': amount,
      }),
    );
    final body = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded};
    }
    return {
      'error':
          decoded['error'] ?? _extractErrorMessage(body, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Referral withdrawal failed: $e', name: 'api_service');
    return {'error': 'Unable to withdraw referral earnings right now.'};
  }
}

Future<Map<String, dynamic>> submitContactForm({
  required String name,
  required String email,
  required String message,
  String? mobile,
}) async {
  try {
    final body = {
      'name': name,
      'email': email,
      'message': message,
    };
    if (mobile != null && mobile.isNotEmpty) {
      body['mobile'] = mobile;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/contact'),
      headers: _jsonHeaders(),
      body: jsonEncode(body),
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded};
    }
    return {
      'error': decoded['error'] ??
          _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Contact form submission failed: $e', name: 'api_service');
    return {
      'error':
          'Unable to send message. Please check your connection and try again.'
    };
  }
}

// ===========================
// NelloByte VTU API Methods
// ===========================

String get vtuBaseUrl => '$apiOrigin/api/clubkonnect';

/// Check VTU API status
Future<Map<String, dynamic>> checkVtuStatus() async {
  try {
    final response = await http.get(
      Uri.parse('$vtuBaseUrl/status'),
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    return {'success': true, 'data': decoded};
  } catch (e) {
    log('Check VTU status failed: $e', name: 'api_service');
    return {'error': 'Unable to check VTU status.'};
  }
}

// ===========================
// Pricing Endpoints (from admin database)
// ===========================

/// Fetch airtime pricing/discounts from admin database
Future<Map<String, dynamic>> fetchAirtimePricing() async {
  try {
    final response = await http.get(
      Uri.parse('$vtuBaseUrl/pricing/airtime'),
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded['data'] ?? []};
    }
    return {'error': _extractErrorMessage(responseBody, response.statusCode)};
  } catch (e) {
    log('Fetch airtime pricing failed: $e', name: 'api_service');
    return {'error': 'Unable to fetch airtime pricing.'};
  }
}

/// Fetch data plans pricing from admin database
Future<Map<String, dynamic>> fetchDataPricing({String? network}) async {
  try {
    String url = '$vtuBaseUrl/pricing/data';
    if (network != null) {
      url += '?network=$network';
    }
    final response = await http.get(Uri.parse(url));
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'plans': decoded['plans'] ?? []};
    }
    return {'error': _extractErrorMessage(responseBody, response.statusCode)};
  } catch (e) {
    log('Fetch data pricing failed: $e', name: 'api_service');
    return {'error': 'Unable to fetch data pricing.'};
  }
}

/// Fetch TV subscription pricing from admin database
Future<Map<String, dynamic>> fetchTvPricing({String? provider}) async {
  try {
    String url = '$vtuBaseUrl/pricing/tv';
    if (provider != null) {
      url += '?provider=$provider';
    }
    final response = await http.get(Uri.parse(url));
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {
        'success': true,
        'data': decoded['data'] ?? [],
        'packages': decoded['packages'] ?? [],
      };
    }
    return {'error': _extractErrorMessage(responseBody, response.statusCode)};
  } catch (e) {
    log('Fetch TV pricing failed: $e', name: 'api_service');
    return {'error': 'Unable to fetch TV pricing.'};
  }
}

/// Fetch electricity discos pricing from admin database
Future<Map<String, dynamic>> fetchElectricityPricing() async {
  try {
    final response = await http.get(
      Uri.parse('$vtuBaseUrl/pricing/electricity'),
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {
        'success': true,
        'data': decoded['data'] ?? [],
        'serviceCharge': decoded['serviceCharge'] ?? 100,
      };
    }
    return {'error': _extractErrorMessage(responseBody, response.statusCode)};
  } catch (e) {
    log('Fetch electricity pricing failed: $e', name: 'api_service');
    return {'error': 'Unable to fetch electricity pricing.'};
  }
}

/// Fetch exam/education pricing from admin database
Future<Map<String, dynamic>> fetchExamPricing() async {
  try {
    final response = await http.get(
      Uri.parse('$vtuBaseUrl/pricing/exam'),
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded['data'] ?? []};
    }
    return {'error': _extractErrorMessage(responseBody, response.statusCode)};
  } catch (e) {
    log('Fetch exam pricing failed: $e', name: 'api_service');
    return {'error': 'Unable to fetch exam pricing.'};
  }
}

/// Fetch available airtime networks with discounts
Future<Map<String, dynamic>> fetchAirtimeNetworks(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$vtuBaseUrl/airtime-networks'),
      headers: _authorizedJsonHeaders(token),
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded};
    }
    return {
      'error': decoded['error'] ??
          _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Fetch airtime networks failed: $e', name: 'api_service');
    return {'error': 'Unable to fetch airtime networks. Please try again.'};
  }
}

/// Fetch available data plans for a network
Future<Map<String, dynamic>> fetchDataPlans(
    String token, String network) async {
  try {
    final response = await http.get(
      Uri.parse('$vtuBaseUrl/data-plans?network=$network'),
      headers: _authorizedJsonHeaders(token),
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded};
    }
    return {
      'error': decoded['error'] ??
          _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Fetch data plans failed: $e', name: 'api_service');
    return {'error': 'Unable to fetch data plans. Please try again.'};
  }
}

/// Fetch available TV subscription packages
Future<Map<String, dynamic>> fetchTVPackages(
    String token, String provider) async {
  try {
    final response = await http.get(
      Uri.parse('$vtuBaseUrl/tv-packages?provider=$provider'),
      headers: _authorizedJsonHeaders(token),
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded};
    }
    return {
      'error': decoded['error'] ??
          _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Fetch TV packages failed: $e', name: 'api_service');
    return {'error': 'Unable to fetch TV packages. Please try again.'};
  }
}

/// Fetch available electricity distribution companies (discos)
Future<Map<String, dynamic>> fetchDiscos(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$vtuBaseUrl/discos'),
      headers: _authorizedJsonHeaders(token),
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded};
    }
    return {
      'error': decoded['error'] ??
          _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Fetch discos failed: $e', name: 'api_service');
    return {
      'error': 'Unable to fetch electricity providers. Please try again.'
    };
  }
}

/// Fetch available exam bodies for education pins (WAEC, JAMB)
Future<Map<String, dynamic>> fetchExamBodies(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$vtuBaseUrl/exam-bodies'),
      headers: _authorizedJsonHeaders(token),
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded};
    }
    return {
      'error': decoded['error'] ??
          _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Fetch exam bodies failed: $e', name: 'api_service');
    return {'error': 'Unable to fetch exam bodies. Please try again.'};
  }
}

/// Verify meter number
/// meterType: '01' for Prepaid, '02' for Postpaid
Future<Map<String, dynamic>> verifyMeter(
    String token, String disco, String meterNumber,
    {String? meterType}) async {
  try {
    String url =
        '$vtuBaseUrl/verify-meter?disco=$disco&meterNumber=$meterNumber';
    if (meterType != null) {
      url += '&meterType=$meterType';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: _authorizedJsonHeaders(token),
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded['data'] ?? decoded};
    }
    // Include canProceed flag from API response (for postpaid meters)
    return {
      'error': decoded['error'] ??
          _extractErrorMessage(responseBody, response.statusCode),
      'canProceed': decoded['canProceed'] ?? false,
      'status': response.statusCode,
    };
  } catch (e) {
    log('Verify meter failed: $e', name: 'api_service');
    return {'error': 'Unable to verify meter. Please try again.'};
  }
}

/// Verify smart card number
Future<Map<String, dynamic>> verifySmartCard(
    String token, String provider, String smartCardNumber) async {
  try {
    final url =
        '$vtuBaseUrl/verify-smartcard?provider=$provider&smartCardNumber=$smartCardNumber';
    log('Verifying smart card: $url', name: 'api_service');
    log('Token present: ${token.isNotEmpty}', name: 'api_service');

    final response = await http.get(
      Uri.parse(url),
      headers: _authorizedJsonHeaders(token),
    );

    log('Smart card verify response status: ${response.statusCode}',
        name: 'api_service');
    log('Smart card verify response body: ${response.body}',
        name: 'api_service');

    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded['data'] ?? decoded};
    }
    return {
      'error': decoded['error'] ??
          _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Verify smart card failed: $e', name: 'api_service');
    return {'error': 'Unable to verify smart card. Please try again.'};
  }
}

/// Verify JAMB profile ID
Future<Map<String, dynamic>> verifyJambProfile(
    String token, String profileId) async {
  try {
    final response = await http.get(
      Uri.parse('$vtuBaseUrl/verify-jamb?profileId=$profileId'),
      headers: _authorizedJsonHeaders(token),
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded};
    }
    return {
      'error': decoded['error'] ??
          _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Verify JAMB profile failed: $e', name: 'api_service');
    return {'error': 'Unable to verify JAMB profile. Please try again.'};
  }
}

/// Buy airtime
/// Network codes: mtn, glo, airtel, 9mobile
/// BonusType: 01 = MTN Awuf (400%), 02 = MTN Garabasa (1000%)
Future<Map<String, dynamic>> buyAirtime(
  String token, {
  required String network,
  required String phone,
  required double amount,
  String? bonusType,
}) async {
  try {
    final body = {
      'network': network,
      'phone': phone,
      'amount': amount,
    };
    if (bonusType != null) {
      body['bonusType'] = bonusType;
    }

    final bodyJson = jsonEncode(body);
    final response = await http.post(
      Uri.parse('$vtuBaseUrl/buy/airtime'),
      headers: _signedAuthorizedHeaders(token, body: bodyJson),
      body: bodyJson,
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded};
    }
    return {
      'error': decoded['error'] ??
          _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Buy airtime failed: $e', name: 'api_service');
    return {'error': 'Unable to purchase airtime. Please try again.'};
  }
}

/// Buy data bundle
/// Network codes: mtn, glo, airtel, 9mobile
/// planId: The data plan code from fetchDataPlans()
Future<Map<String, dynamic>> buyData(
  String token, {
  required String network,
  required String phone,
  required String planId,
  required double amount,
}) async {
  try {
    final bodyJson = jsonEncode({
      'network': network,
      'phone': phone,
      'planId': planId,
      'amount': amount,
    });
    final response = await http.post(
      Uri.parse('$vtuBaseUrl/buy/data'),
      headers: _signedAuthorizedHeaders(token, body: bodyJson),
      body: bodyJson,
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded};
    }
    return {
      'error': decoded['error'] ??
          _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Buy data failed: $e', name: 'api_service');
    return {'error': 'Unable to purchase data. Please try again.'};
  }
}

/// Buy electricity (prepaid/postpaid meter recharge)
/// disco: Electricity company code (01-12)
/// meterType: 01 = Prepaid, 02 = Postpaid
Future<Map<String, dynamic>> buyElectricity(
  String token, {
  required String disco,
  required String meterType,
  required String meterNumber,
  required double amount,
  String? phone,
}) async {
  try {
    final bodyJson = jsonEncode({
      'disco': disco,
      'meterType': meterType,
      'meterNumber': meterNumber,
      'amount': amount,
      'phone': phone ?? '',
    });
    final response = await http.post(
      Uri.parse('$vtuBaseUrl/buy/electricity'),
      headers: _signedAuthorizedHeaders(token, body: bodyJson),
      body: bodyJson,
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded};
    }
    return {
      'error': decoded['error'] ??
          _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Buy electricity failed: $e', name: 'api_service');
    return {'error': 'Unable to purchase electricity. Please try again.'};
  }
}

/// Buy TV subscription (DStv, GOtv, Startimes)
/// provider: dstv, gotv, startimes
/// packageCode: The package code from fetchTVPackages()
Future<Map<String, dynamic>> buyTVSubscription(
  String token, {
  required String provider,
  required String smartCardNumber,
  required String packageCode,
  required double amount,
  String? phone,
}) async {
  try {
    final bodyJson = jsonEncode({
      'provider': provider,
      'smartcardNumber':
          smartCardNumber, // Note: lowercase 'c' to match backend
      'packageCode': packageCode,
      'amount': amount,
      'phone': phone ?? '',
    });
    final response = await http.post(
      Uri.parse('$vtuBaseUrl/buy/tv'),
      headers: _signedAuthorizedHeaders(token, body: bodyJson),
      body: bodyJson,
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded};
    }
    return {
      'error': decoded['error'] ??
          _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Buy TV subscription failed: $e', name: 'api_service');
    return {'error': 'Unable to purchase TV subscription. Please try again.'};
  }
}

/// Buy education pin (WAEC, JAMB)
/// examType: waec or jamb
/// examCode: The exam code (e.g., waec, waec-registration, utme, de)
Future<Map<String, dynamic>> buyEducationPin(
  String token, {
  required String examType,
  required String examCode,
  required String phone,
  required double amount,
  String? profileId, // For JAMB
}) async {
  try {
    final body = {
      'examType': examType,
      'examCode': examCode,
      'phone': phone,
      'amount': amount,
    };
    if (profileId != null && profileId.isNotEmpty) {
      body['profileId'] = profileId;
    }

    final bodyJson = jsonEncode(body);
    final response = await http.post(
      Uri.parse('$vtuBaseUrl/buy/education'),
      headers: _signedAuthorizedHeaders(token, body: bodyJson),
      body: bodyJson,
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded};
    }
    return {
      'error': decoded['error'] ??
          _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Buy education pin failed: $e', name: 'api_service');
    return {'error': 'Unable to purchase education pin. Please try again.'};
  }
}

/// Query transaction status
Future<Map<String, dynamic>> queryTransaction(String token,
    {String? orderId, String? requestId}) async {
  try {
    final queryParams = <String, String>{};
    if (orderId != null) queryParams['orderId'] = orderId;
    if (requestId != null) queryParams['requestId'] = requestId;

    final uri =
        Uri.parse('$vtuBaseUrl/query').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: _authorizedJsonHeaders(token),
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded};
    }
    return {
      'error': decoded['error'] ??
          _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Query transaction failed: $e', name: 'api_service');
    return {'error': 'Unable to query transaction. Please try again.'};
  }
}

/// Cancel transaction (only ORDER_RECEIVED or ORDER_ONHOLD can be cancelled)
Future<Map<String, dynamic>> cancelTransaction(
    String token, String orderId) async {
  try {
    final response = await http.post(
      Uri.parse('$vtuBaseUrl/cancel'),
      headers: _authorizedJsonHeaders(token),
      body: jsonEncode({'orderId': orderId}),
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded};
    }
    return {
      'error': decoded['error'] ??
          _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Cancel transaction failed: $e', name: 'api_service');
    return {'error': 'Unable to cancel transaction. Please try again.'};
  }
}

/// Fetch VTU transaction history
/// type: Optional filter - 'airtime', 'data', 'electricity', 'tv', 'education'
Future<Map<String, dynamic>> fetchVTUHistory(
  String token, {
  String? type,
  int limit = 20,
}) async {
  try {
    final queryParams = <String, String>{
      'limit': limit.toString(),
    };
    if (type != null) queryParams['type'] = type;

    final uri =
        Uri.parse('$vtuBaseUrl/history').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: _authorizedJsonHeaders(token),
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded['data'] ?? []};
    }
    return {
      'error': decoded['error'] ??
          _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Fetch VTU history failed: $e', name: 'api_service');
    return {'error': 'Unable to fetch transaction history. Please try again.'};
  }
}

// ===================== NOTIFICATIONS =====================

/// Fetch notifications for the authenticated user
Future<Map<String, dynamic>> fetchNotifications(String token,
    {int limit = 50, int offset = 0}) async {
  try {
    final uri = Uri.parse('$baseUrl/notifications').replace(
      queryParameters: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );
    final response = await http.get(
      uri,
      headers: _authorizedJsonHeaders(token),
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {
        'success': true,
        'notifications': decoded['notifications'] ?? [],
        'unreadCount': decoded['unreadCount'] ?? 0,
        'total': decoded['total'] ?? 0,
      };
    }
    return {
      'error': decoded['error'] ??
          _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Fetch notifications failed: $e', name: 'api_service');
    return {'error': 'Unable to fetch notifications. Please try again.'};
  }
}

/// Get unread notification count
Future<Map<String, dynamic>> getUnreadNotificationCount(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/unread-count'),
      headers: _authorizedJsonHeaders(token),
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {
        'success': true,
        'unreadCount': decoded['unreadCount'] ?? 0,
      };
    }
    return {
      'error': decoded['error'] ??
          _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Get unread notification count failed: $e', name: 'api_service');
    return {'error': 'Unable to get notification count.'};
  }
}

/// Mark a notification as read
Future<Map<String, dynamic>> markNotificationAsRead(
    String token, int notificationId) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/notifications/$notificationId/read'),
      headers: _authorizedJsonHeaders(token),
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true};
    }
    return {
      'error': decoded['error'] ??
          _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Mark notification as read failed: $e', name: 'api_service');
    return {'error': 'Unable to mark notification as read.'};
  }
}

/// Mark all notifications as read
Future<Map<String, dynamic>> markAllNotificationsAsRead(String token) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: _authorizedJsonHeaders(token),
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true};
    }
    return {
      'error': decoded['error'] ??
          _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Mark all notifications as read failed: $e', name: 'api_service');
    return {'error': 'Unable to mark notifications as read.'};
  }
}
