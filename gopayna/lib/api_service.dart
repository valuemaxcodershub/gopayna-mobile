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

// ===========================
// NelloByte VTU API Methods
// ===========================

const String vtuBaseUrl = '$apiOrigin/api/clubkonnect';

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
      'error': decoded['error'] ?? _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Fetch airtime networks failed: $e', name: 'api_service');
    return {'error': 'Unable to fetch airtime networks. Please try again.'};
  }
}

/// Fetch available data plans for a network
Future<Map<String, dynamic>> fetchDataPlans(String token, String network) async {
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
      'error': decoded['error'] ?? _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Fetch data plans failed: $e', name: 'api_service');
    return {'error': 'Unable to fetch data plans. Please try again.'};
  }
}

/// Fetch available TV subscription packages
Future<Map<String, dynamic>> fetchTVPackages(String token, String provider) async {
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
      'error': decoded['error'] ?? _extractErrorMessage(responseBody, response.statusCode),
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
      'error': decoded['error'] ?? _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Fetch discos failed: $e', name: 'api_service');
    return {'error': 'Unable to fetch electricity providers. Please try again.'};
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
      'error': decoded['error'] ?? _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Fetch exam bodies failed: $e', name: 'api_service');
    return {'error': 'Unable to fetch exam bodies. Please try again.'};
  }
}

/// Verify meter number
Future<Map<String, dynamic>> verifyMeter(String token, String disco, String meterNumber) async {
  try {
    final response = await http.get(
      Uri.parse('$vtuBaseUrl/verify-meter?disco=$disco&meterNumber=$meterNumber'),
      headers: _authorizedJsonHeaders(token),
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded};
    }
    return {
      'error': decoded['error'] ?? _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Verify meter failed: $e', name: 'api_service');
    return {'error': 'Unable to verify meter. Please try again.'};
  }
}

/// Verify smart card number
Future<Map<String, dynamic>> verifySmartCard(String token, String provider, String smartCardNumber) async {
  try {
    final response = await http.get(
      Uri.parse('$vtuBaseUrl/verify-smartcard?provider=$provider&smartCardNumber=$smartCardNumber'),
      headers: _authorizedJsonHeaders(token),
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded};
    }
    return {
      'error': decoded['error'] ?? _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Verify smart card failed: $e', name: 'api_service');
    return {'error': 'Unable to verify smart card. Please try again.'};
  }
}

/// Verify JAMB profile ID
Future<Map<String, dynamic>> verifyJambProfile(String token, String profileId) async {
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
      'error': decoded['error'] ?? _extractErrorMessage(responseBody, response.statusCode),
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
    
    final response = await http.post(
      Uri.parse('$vtuBaseUrl/buy/airtime'),
      headers: _authorizedJsonHeaders(token),
      body: jsonEncode(body),
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded};
    }
    return {
      'error': decoded['error'] ?? _extractErrorMessage(responseBody, response.statusCode),
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
    final response = await http.post(
      Uri.parse('$vtuBaseUrl/buy/data'),
      headers: _authorizedJsonHeaders(token),
      body: jsonEncode({
        'network': network,
        'phone': phone,
        'planId': planId,
        'amount': amount,
      }),
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded};
    }
    return {
      'error': decoded['error'] ?? _extractErrorMessage(responseBody, response.statusCode),
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
    final response = await http.post(
      Uri.parse('$vtuBaseUrl/buy/electricity'),
      headers: _authorizedJsonHeaders(token),
      body: jsonEncode({
        'disco': disco,
        'meterType': meterType,
        'meterNumber': meterNumber,
        'amount': amount,
        'phone': phone ?? '',
      }),
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded};
    }
    return {
      'error': decoded['error'] ?? _extractErrorMessage(responseBody, response.statusCode),
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
    final response = await http.post(
      Uri.parse('$vtuBaseUrl/buy/tv'),
      headers: _authorizedJsonHeaders(token),
      body: jsonEncode({
        'provider': provider,
        'smartCardNumber': smartCardNumber,
        'packageCode': packageCode,
        'amount': amount,
        'phone': phone ?? '',
      }),
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded};
    }
    return {
      'error': decoded['error'] ?? _extractErrorMessage(responseBody, response.statusCode),
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
    
    final response = await http.post(
      Uri.parse('$vtuBaseUrl/buy/education'),
      headers: _authorizedJsonHeaders(token),
      body: jsonEncode(body),
    );
    final responseBody = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(responseBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': decoded};
    }
    return {
      'error': decoded['error'] ?? _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Buy education pin failed: $e', name: 'api_service');
    return {'error': 'Unable to purchase education pin. Please try again.'};
  }
}

/// Query transaction status
Future<Map<String, dynamic>> queryTransaction(String token, {String? orderId, String? requestId}) async {
  try {
    final queryParams = <String, String>{};
    if (orderId != null) queryParams['orderId'] = orderId;
    if (requestId != null) queryParams['requestId'] = requestId;
    
    final uri = Uri.parse('$vtuBaseUrl/query').replace(queryParameters: queryParams);
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
      'error': decoded['error'] ?? _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Query transaction failed: $e', name: 'api_service');
    return {'error': 'Unable to query transaction. Please try again.'};
  }
}

/// Cancel transaction (only ORDER_RECEIVED or ORDER_ONHOLD can be cancelled)
Future<Map<String, dynamic>> cancelTransaction(String token, String orderId) async {
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
      'error': decoded['error'] ?? _extractErrorMessage(responseBody, response.statusCode),
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
    
    final uri = Uri.parse('$vtuBaseUrl/history').replace(queryParameters: queryParams);
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
      'error': decoded['error'] ?? _extractErrorMessage(responseBody, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Fetch VTU history failed: $e', name: 'api_service');
    return {'error': 'Unable to fetch transaction history. Please try again.'};
  }
}
