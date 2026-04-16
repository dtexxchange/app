import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';

class CryptoService {
  static Map<String, dynamic> decrypt(String privateKeyPem, String encryptedB64) {
    // The library expects PEM format with headers
    final pem = privateKeyPem.contains("BEGIN PRIVATE KEY") 
      ? privateKeyPem 
      : "-----BEGIN PRIVATE KEY-----\n$privateKeyPem\n-----END PRIVATE KEY-----";

    final parser = RSAKeyParser();
    final privateKey = parser.parse(pem) as RSAPrivateKey;
    
    final encrypter = Encrypter(RSA(
      privateKey: privateKey,
      encoding: RSAEncoding.OAEP,
    ));

    final decrypted = encrypter.decrypt(Encrypted.fromBase64(encryptedB64));
    return jsonDecode(decrypted);
  }
}
