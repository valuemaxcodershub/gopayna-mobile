import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

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

const String apiOrigin = 'https://api.gopayna.com';
const String baseUrl = '$apiOrigin/api/auth';
const String paystackBaseUrl = '$apiOrigin/api/paystack';

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
        'referralCode': referralCode, // Include referral code in the request
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
    return {
      'error': _extractErrorMessage(response.body, response.statusCode),
      'status': response.statusCode,
    };
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
      return {'error': 'Failed to verify OTP'};
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
      return {'error': 'Failed to send OTP'};
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
      return {'error': 'Failed to reset password'};
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
      'error': decoded['error'] ?? _extractErrorMessage(body, response.statusCode),
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
      'error': decoded['error'] ?? _extractErrorMessage(body, response.statusCode),
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
      'error': decoded['error'] ?? _extractErrorMessage(body, response.statusCode),
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
      'error': decoded['error'] ?? _extractErrorMessage(body, response.statusCode),
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
      final data = (decoded['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return {'success': true, 'data': data};
    }
    return {
      'error': decoded['error'] ?? _extractErrorMessage(body, response.statusCode),
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
      'error': decoded['error'] ?? _extractErrorMessage(body, response.statusCode),
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
      'error': 'Unable to send message. Please check your connection and try again.'
    };
  }
}
