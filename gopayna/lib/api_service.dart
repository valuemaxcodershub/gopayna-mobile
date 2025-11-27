import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

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

const String baseUrl = 'http://localhost:5000/api/auth';
const String paystackBaseUrl = 'http://localhost:5000/api/paystack';

Future<Map<String, dynamic>> registerUser(String firstName, String lastName, String phone, String email, String password, String referralCode) async {
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
      log('Registration error: status ${response.statusCode}, body: ${response.body}', name: 'api_service');
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

Future<Map<String, dynamic>> loginUser(String usernameOrEmail, String password) async {
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
    log('Login error: status ${response.statusCode}, body: ${response.body}', name: 'api_service');
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
      body: jsonEncode(isEmail ? {'email': email, 'otp': otp} : {'phone': email, 'otp': otp}),
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

Future<Map<String, dynamic>> sendPasswordResetOtp(String? email, String? phone) async {
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

Future<Map<String, dynamic>> resetPassword(String email, String otp, String newPassword) async {
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
      log('Wallet fetch error: status ${response.statusCode}, body: ${response.body}', name: 'api_service');
      return null;
    }
    return null;
  } catch (e) {
    log('Failed to fetch wallet balance: $e', name: 'api_service');
    return null;
  }
}

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
      'error': decoded['error'] ?? _extractErrorMessage(response.body, response.statusCode),
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
      'error': decoded['error'] ?? _extractErrorMessage(response.body, response.statusCode),
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
      final data = (decoded['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return {'success': true, 'data': data};
    }
    return {
      'error': decoded['error'] ?? _extractErrorMessage(response.body, response.statusCode),
      'status': response.statusCode,
    };
  } catch (e) {
    log('Fetch wallet transactions failed: $e', name: 'api_service');
    return {'error': 'Unable to fetch wallet transactions. Please try again.'};
  }
}
