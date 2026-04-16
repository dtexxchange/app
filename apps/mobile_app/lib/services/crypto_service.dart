import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';

class CryptoService {
  static const bool enableE2EE = false;

  static String encrypt(String publicKeyB64, Map<String, dynamic> data) {
    if (!enableE2EE) {
      return base64Encode(utf8.encode(jsonEncode(data)));
    }
    // Wrap the B64 string in PEM format for the parser
    final pem = "-----BEGIN PUBLIC KEY-----\n$publicKeyB64\n-----END PUBLIC KEY-----";
    
    final parser = RSAKeyParser();
    final publicKey = parser.parse(pem) as RSAPublicKey;
    
    final encrypter = Encrypter(RSA(
      publicKey: publicKey,
      encoding: RSAEncoding.OAEP,
    ));

    final jsonStr = jsonEncode(data);
    final encrypted = encrypter.encrypt(jsonStr);
    
    return encrypted.base64;
  }

  static Map<String, dynamic>? decrypt(String encryptedBase64) {
    if (!enableE2EE) {
      try {
        final decoded = utf8.decode(base64Decode(encryptedBase64));
        return jsonDecode(decoded);
      } catch (e) {
        return null;
      }
    }
    // Users can't decrypt RSA in this demo as they lack the private key.
    return null;
  }
}
