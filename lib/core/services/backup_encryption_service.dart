import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../prefs.dart';

/// WhatsApp-style backup encryption service
///
/// Encrypts cloud backups with user password or recovery key
/// Uses AES-256 encryption with PBKDF2 key derivation
class BackupEncryptionService {
  static const int _keyLength = 32; // 256 bits
  static const int _iterations = 100000; // PBKDF2 iterations

  /// Check if cloud backup encryption is enabled
  static Future<bool> isEncryptionEnabled() async {
    return await Prefs.getCloudEncryptionEnabled();
  }

  /// Check if password is set (vs recovery key)
  static Future<bool> hasPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final salt = prefs.getString('backup_encryption_salt');
    final hash = prefs.getString('backup_password_hash');
    return salt != null && hash != null;
  }

  /// Set encryption password
  static Future<void> setPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();

    // Generate random salt
    final saltBytes = encrypt.SecureRandom(16).bytes;
    final salt = base64Encode(saltBytes);

    // Hash password for verification (not for encryption)
    final passwordHash = _hashPassword(password, saltBytes);

    await prefs.setString('backup_encryption_salt', salt);
    await prefs.setString('backup_password_hash', passwordHash);
    await Prefs.setCloudEncryptionEnabled(true);
  }

  /// Generate recovery key (24-character alphanumeric)
  static Future<String> generateRecoveryKey() async {
    final prefs = await SharedPreferences.getInstance();

    // Generate secure random key
    final keyBytes =
        encrypt.SecureRandom(18).bytes; // 18 bytes = 24 chars base64
    final recoveryKey = base64Encode(keyBytes)
        .replaceAll('/', '')
        .replaceAll('+', '')
        .replaceAll('=', '')
        .substring(0, 24)
        .toUpperCase();

    // Store hash for verification
    final salt = encrypt.SecureRandom(16).bytes;
    final keyHash = _hashPassword(recoveryKey, salt);

    await prefs.setString('backup_encryption_salt', base64Encode(salt));
    await prefs.setString('backup_password_hash', keyHash);
    await Prefs.setCloudEncryptionEnabled(true);

    return _formatRecoveryKey(recoveryKey);
  }

  /// Verify password or recovery key
  static Future<bool> verifyPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final saltStr = prefs.getString('backup_encryption_salt');
    final storedHash = prefs.getString('backup_password_hash');

    if (saltStr == null || storedHash == null) return false;

    final salt = base64Decode(saltStr);
    final inputHash = _hashPassword(password, salt);

    return inputHash == storedHash;
  }

  /// Encrypt backup bytes
  static Future<Uint8List> encryptBackup(
    Uint8List data,
    String password,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final saltStr = prefs.getString('backup_encryption_salt');

    if (saltStr == null) {
      throw Exception('Encryption not configured');
    }

    final salt = base64Decode(saltStr);
    final key = _deriveKey(password, salt);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    // Generate random IV
    final iv = encrypt.IV.fromSecureRandom(16);

    // Encrypt data
    final encrypted = encrypter.encryptBytes(data, iv: iv);

    // Combine: IV (16 bytes) + encrypted data
    final result = Uint8List(16 + encrypted.bytes.length);
    result.setRange(0, 16, iv.bytes);
    result.setRange(16, result.length, encrypted.bytes);

    return result;
  }

  /// Decrypt backup bytes
  static Future<Uint8List> decryptBackup(
    Uint8List encryptedData,
    String password,
  ) async {
    if (encryptedData.length < 16) {
      throw Exception('Invalid encrypted backup');
    }

    final prefs = await SharedPreferences.getInstance();
    final saltStr = prefs.getString('backup_encryption_salt');

    if (saltStr == null) {
      throw Exception('Encryption not configured');
    }

    final salt = base64Decode(saltStr);
    final key = _deriveKey(password, salt);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    // Extract IV and encrypted data
    final iv = encrypt.IV(encryptedData.sublist(0, 16));
    final ciphertext = encryptedData.sublist(16);

    try {
      // Decrypt
      final decrypted = encrypter.decryptBytes(
        encrypt.Encrypted(ciphertext),
        iv: iv,
      );
      return Uint8List.fromList(decrypted);
    } catch (e) {
      throw Exception(
          'Decryption failed - incorrect password or corrupted backup');
    }
  }

  /// Check if backup file is encrypted
  static bool isBackupEncrypted(Uint8List data) {
    // Unencrypted ZIP starts with PK (0x50 0x4B)
    // Encrypted backups won't have this header
    if (data.length < 4) return false;
    return !(data[0] == 0x50 && data[1] == 0x4B);
  }

  /// Remove encryption (disable)
  static Future<void> disableEncryption() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('backup_encryption_salt');
    await prefs.remove('backup_password_hash');
    await Prefs.setCloudEncryptionEnabled(false);
  }

  // Private helpers

  static String _hashPassword(String password, List<int> salt) {
    final key = _deriveKey(password, salt);
    return base64Encode(key.bytes);
  }

  static encrypt.Key _deriveKey(String password, List<int> salt) {
    // Use PBKDF2 from pointycastle
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    derivator.init(
        Pbkdf2Parameters(Uint8List.fromList(salt), _iterations, _keyLength));

    final key = derivator.process(Uint8List.fromList(utf8.encode(password)));
    return encrypt.Key(key);
  }

  static String _formatRecoveryKey(String key) {
    // Format: XXXX-XXXX-XXXX-XXXX-XXXX-XXXX
    final parts = <String>[];
    for (int i = 0; i < key.length; i += 4) {
      final endIndex = (i + 4 < key.length) ? i + 4 : key.length;
      parts.add(key.substring(i, endIndex));
    }
    return parts.join('-');
  }
}
