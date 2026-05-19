import 'package:encrypt/encrypt.dart';

class EncryptionHelper {
  // Use a definitive 32 character key. In production, this should be an environment variable.
  static final _key = Key.fromUtf8('twc1234567890123twc1234567890123');
  // Use a static IV for deterministic encryption so Firestore queries can roughly match, or random for security. 
  // We use a fixed IV here strictly to preserve phone number existence checks without hashing.
  static final _iv = IV.fromUtf8('twccryptoiv12345'); 
  static final _encrypter = Encrypter(AES(_key, mode: AESMode.cbc));

  static String encryptData(String plainText) {
    try {
      if (plainText.isEmpty) return plainText;
      return _encrypter.encrypt(plainText, iv: _iv).base64;
    } catch (e) {
      return plainText;
    }
  }

  static String decryptData(String encryptedText) {
    try {
      if (encryptedText.isEmpty) return encryptedText;
      return _encrypter.decrypt64(encryptedText, iv: _iv);
    } catch (e) {
      return encryptedText; // Fallback if it's not encrypted (e.g. old data)
    }
  }
}
