import 'package:flutter_test/flutter_test.dart';
import 'package:study_flow/services/gemini_service.dart';

void main() {
  group('Gemini API Key Validation', () {
    test('should accept legacy AIza keys', () {
      expect(GeminiService.isValidApiKey('AIzaSyA1b2c3d4e5f6g7h8i9j0'), isTrue);
      expect(GeminiService.isValidApiKey('AIza_some_key-with-dashes'), isTrue);
    });

    test('should accept new AQ. keys', () {
      expect(GeminiService.isValidApiKey('AQ.some_new-key.with.dots'), isTrue);
      expect(GeminiService.isValidApiKey('AQ.1a2b3c4d5e6f7g8h9i0j'), isTrue);
    });

    test('should reject invalid keys', () {
      expect(GeminiService.isValidApiKey('invalid_key'), isFalse);
      expect(GeminiService.isValidApiKey('AIza'), isFalse); // Too short / no trailing chars
      expect(GeminiService.isValidApiKey('AQ.'), isFalse);   // Too short / no trailing chars
      expect(GeminiService.isValidApiKey(''), isFalse);      // Empty key
      expect(GeminiService.isValidApiKey('AIzaSy!@#'), isFalse); // Special characters not allowed
    });
  });
}
