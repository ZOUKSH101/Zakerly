import 'package:flutter/foundation.dart';

import 'models.dart';

// Every external dependency sits behind one of these interfaces. The demo
// wires in mocks; production swaps in Firebase, Canvas and Gemini adapters.

/// Firebase Auth in production.
abstract class AuthService {
  ValueListenable<AppUser?> get user;
  Future<void> signInWithEmail(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> signOut();
}

/// Canvas in production (REST API via a proxy function, since Canvas does not
/// allow browser CORS). Moodle and others implement the same interface.
abstract class LmsProvider {
  String get name;
  String get host;
  Future<List<Course>> listCourses();
  Future<String> fetchFileText(CourseFile file);
}

enum LlmPurpose { summarize, tutor, animation }

class LlmRequest {
  const LlmRequest({
    required this.purpose,
    required this.system,
    required this.prompt,
    this.maxOutputTokens = 1024,
  });
  final LlmPurpose purpose;
  final String system, prompt;
  final int maxOutputTokens;
}

class LlmResponse {
  const LlmResponse({
    required this.text,
    required this.inputTokens,
    required this.outputTokens,
  });
  final String text;
  final int inputTokens, outputTokens;
  int get totalTokens => inputTokens + outputTokens;
}

/// One model backend (Gemini first; OpenAI / Claude later via BYOK).
abstract class LlmProvider {
  Future<LlmResponse> generate(LlmRequest request);
}

/// Shared key-value storage for caches. Firebase Realtime Database in
/// production, so one student's generated animation serves the whole course.
abstract class KeyValueStore {
  Future<String?> get(String key);
  Future<void> put(String key, String value);
}

class MemoryStore implements KeyValueStore {
  final _data = <String, String>{};

  @override
  Future<String?> get(String key) async => _data[key];

  @override
  Future<void> put(String key, String value) async => _data[key] = value;
}
