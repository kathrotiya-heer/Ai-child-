import 'dart:async';
import 'dart:convert';
import 'dart:io';

// ============================================================
// AUTH RESULT
// ============================================================

class AuthResult {
  final String accessToken;
  final int parentId;
  final String name;

  const AuthResult({
    required this.accessToken,
    required this.parentId,
    required this.name,
  });
}

// ============================================================
// CHILD RESULT
// ============================================================

class ChildResult {
  final int id;
  final int parentId;
  final String name;
  final int age;
  final bool isActive;
  final String createdAt;

  const ChildResult({
    required this.id,
    required this.parentId,
    required this.name,
    required this.age,
    required this.isActive,
    required this.createdAt,
  });

  factory ChildResult.fromJson(Map<String, dynamic> json) {
    return ChildResult(
      id: json['id'] as int,
      parentId: json['parent_id'] as int,
      name: json['name'] as String,
      age: json['age'] as int,
      isActive: json['is_active'] as bool,
      createdAt: json['created_at'] as String,
    );
  }
}

// ============================================================
// AUTH SERVICE
// ============================================================

class AuthService {
  // Android emulator -> host machine
  // Physical phone:
  // Replace with your computer LAN IP.
  static const String baseUrl = 'http://10.223.202.210:8001';

  // ==========================================================
  // REGISTER
  // ==========================================================

  static Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String pin,
  }) async {
    if (name.length < 2) {
      throw Exception('Name must be at least 2 characters.');
    }

    if (!email.contains('@')) {
      throw Exception('Please enter a valid email.');
    }

    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    if (pin.length < 4 || pin.length > 6) {
      throw Exception('PIN must be 4 to 6 digits.');
    }

    final json = await _post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'pin': pin,
    });

    return _parseResult(json);
  }

  // ==========================================================
  // LOGIN
  // ==========================================================

  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    if (!email.contains('@')) {
      throw Exception('Please enter a valid email.');
    }

    if (password.isEmpty) {
      throw Exception('Please enter your password.');
    }

    final json = await _post('/auth/login', {
      'email': email,
      'password': password,
    });

    return _parseResult(json);
  }

  // ==========================================================
  // VERIFY PIN
  // ==========================================================

  static Future<void> verifyPin({
    required String pin,
    required String token,
  }) async {
    await _post('/parent/verify', {'pin': pin}, token: token);
  }

  // ==========================================================
  // CREATE CHILD
  // ==========================================================

  static Future<ChildResult> createChild({
    required String name,
    required int age,
    required String token,
  }) async {
    if (name.trim().isEmpty) {
      throw Exception('Child name cannot be empty.');
    }

    if (age < 5 || age > 13) {
      throw Exception('Child age must be between 5 and 13.');
    }

    final json = await _post('/children/', {
      'name': name.trim(),
      'age': age,
    }, token: token);

    return ChildResult.fromJson(json);
  }

  // ==========================================================
  // GET CHILDREN
  // ==========================================================

  static Future<List<ChildResult>> getChildren({required String token}) async {
    final json = await _get('/children/', token: token);

    if (json is! List) {
      throw Exception('Invalid children response from server.');
    }

    return json
        .map((item) => ChildResult.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // ==========================================================
  // GET ONE CHILD
  // ==========================================================

  static Future<ChildResult> getChild({
    required int childId,
    required String token,
  }) async {
    final json = await _get('/children/$childId', token: token);

    return ChildResult.fromJson(json);
  }

  // ==========================================================
  // ACTIVATE CHILD
  // ==========================================================

  static Future<ChildResult> activateChild({
    required int childId,
    required String token,
  }) async {
    final json = await _post('/children/$childId/activate', {}, token: token);

    return ChildResult.fromJson(json);
  }

  // ==========================================================
  // DELETE CHILD
  // ==========================================================

  static Future<void> deleteChild({
    required int childId,
    required String token,
  }) async {
    await _delete('/children/$childId', token: token);
  }

  // ==========================================================
  // FORGOT PASSWORD
  // ==========================================================

  static Future<String?> forgotPassword(String email) async {
    final json = await _post('/auth/forgot-password', {'email': email});

    final token = json['dev_reset_token'];

    return token is String ? token : null;
  }

  // ==========================================================
  // RESET PASSWORD
  // ==========================================================

  static Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _post('/auth/reset-password', {
      'token': token,
      'new_password': newPassword,
    });
  }

  // ==========================================================
  // FORGOT PIN
  // ==========================================================

  static Future<String?> forgotPin(String email) async {
    final json = await _post('/auth/forgot-pin', {'email': email});

    final token = json['dev_reset_token'];

    return token is String ? token : null;
  }

  // ==========================================================
  // RESET PIN
  // ==========================================================

  static Future<void> resetPin({
    required String token,
    required String newPin,
  }) async {
    await _post('/auth/reset-pin', {'token': token, 'new_pin': newPin});
  }

  // ==========================================================
  // PARSE AUTH RESULT
  // ==========================================================

  static AuthResult _parseResult(Map<String, dynamic> json) {
    final token = json['access_token'];
    final parentId = json['parent_id'];
    final name = json['name'];

    if (token is! String || parentId is! int || name is! String) {
      throw Exception('Invalid response from server.');
    }

    return AuthResult(accessToken: token, parentId: parentId, name: name);
  }

  // ==========================================================
  // POST REQUEST
  // ==========================================================

  static Future<dynamic> _post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final client = HttpClient();

    client.connectionTimeout = const Duration(seconds: 8);

    try {
      final request = await client
          .postUrl(Uri.parse('$baseUrl$path'))
          .timeout(const Duration(seconds: 8));

      request.headers.contentType = ContentType.json;

      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);

      if (token != null && token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }

      request.write(jsonEncode(body));

      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );

      final responseBody = await response.transform(utf8.decoder).join();

      dynamic decoded;

      if (responseBody.isNotEmpty) {
        decoded = jsonDecode(responseBody);
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message = 'Server error (${response.statusCode}).';

        if (decoded is Map && decoded['detail'] is String) {
          message = decoded['detail'];
        }

        throw Exception(message);
      }

      return decoded;
    } on SocketException {
      throw Exception('Cannot connect to SafeLearn server.');
    } on TimeoutException {
      throw Exception('Server is taking too long to respond.');
    } on FormatException {
      throw Exception('Invalid response received from server.');
    } finally {
      client.close(force: true);
    }
  }

  // ==========================================================
  // GET REQUEST
  // ==========================================================

  static Future<dynamic> _get(String path, {String? token}) async {
    final client = HttpClient();

    client.connectionTimeout = const Duration(seconds: 8);

    try {
      final request = await client
          .getUrl(Uri.parse('$baseUrl$path'))
          .timeout(const Duration(seconds: 8));

      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);

      if (token != null && token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }

      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );

      final responseBody = await response.transform(utf8.decoder).join();

      dynamic decoded;

      if (responseBody.isNotEmpty) {
        decoded = jsonDecode(responseBody);
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message = 'Server error (${response.statusCode}).';

        if (decoded is Map && decoded['detail'] is String) {
          message = decoded['detail'];
        }

        throw Exception(message);
      }

      return decoded;
    } on SocketException {
      throw Exception('Cannot connect to SafeLearn server.');
    } on TimeoutException {
      throw Exception('Server is taking too long to respond.');
    } on FormatException {
      throw Exception('Invalid response received from server.');
    } finally {
      client.close(force: true);
    }
  }

  // ==========================================================
  // DELETE REQUEST
  // ==========================================================

  static Future<dynamic> _delete(String path, {String? token}) async {
    final client = HttpClient();

    client.connectionTimeout = const Duration(seconds: 8);

    try {
      final request = await client
          .deleteUrl(Uri.parse('$baseUrl$path'))
          .timeout(const Duration(seconds: 8));

      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);

      if (token != null && token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }

      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );

      final responseBody = await response.transform(utf8.decoder).join();

      dynamic decoded;

      if (responseBody.isNotEmpty) {
        decoded = jsonDecode(responseBody);
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message = 'Server error (${response.statusCode}).';

        if (decoded is Map && decoded['detail'] is String) {
          message = decoded['detail'];
        }

        throw Exception(message);
      }

      return decoded;
    } on SocketException {
      throw Exception('Cannot connect to SafeLearn server.');
    } on TimeoutException {
      throw Exception('Server is taking too long to respond.');
    } on FormatException {
      throw Exception('Invalid response received from server.');
    } finally {
      client.close(force: true);
    }
  }
}
