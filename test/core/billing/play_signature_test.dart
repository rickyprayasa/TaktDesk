import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:takt_desk/core/billing/play_signature.dart';

import 'signature_vectors.dart';

/// Play Console → Licensing, as shown there (base64). Only used to check the masked copy in the app.
const _playConsoleKey =
    'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAjYk+L7PU1JC6dqdV1lqKp+R9avAus9yhzSA2uIINqfcQ0Mz07Pxy7dWNHvfuKuL6yYeslRSwTZtRya+f7Ov4E7exQB4uzse8+6WTlGuggJiHvl40Yzctrb2jZ7JHeT7An2Igp2E5IyiRka8kNiFw0PNwbP4gBB/up8UY48GsoOxgVGeZLQ2atY2wRwXhGWTXGx1Z8rULbrkaemHqYa9lCT6Odw8CPOsheFKYPqzOBPA72vA2bmtc3RQkseRb5pe5i9/nQx4B6h85avfTN5l5iqkhLRUpxUldzBGmQA5IhfdC5UR5xl4uBdBDVDNiks6wcqsUqrfcDPrt/SjlqfpMSQIDAQAB';

void main() {
  final key = PlaySignature.fromSubjectPublicKeyInfo(base64.decode(testKey));

  test('a genuine SHA1withRSA signature passes', () {
    expect(key.verify(signedJson, genuineSignature), isTrue);
  });

  test('changed data, another key, or a broken signature fail', () {
    expect(key.verify(signedJson.replaceFirst('GPA.3394', 'GPA.3395'), genuineSignature), isFalse);
    expect(key.verify(' ', genuineSignature), isFalse);
    expect(key.verify(signedJson, signatureByAnotherKey), isFalse);
    expect(key.verify(signedJson, 'bm90LWEtc2lnbmF0dXJl'), isFalse);
    expect(key.verify(signedJson, 'not base64 !!'), isFalse);
    expect(key.verify(signedJson, ''), isFalse);
    expect(key.verify('', genuineSignature), isFalse);
    final flipped = base64.decode(genuineSignature)..[100] ^= 0x01;
    expect(key.verify(signedJson, base64.encode(flipped)), isFalse);
  });

  test('the key built into the app is exactly the Play Console Licensing key', () {
    final fromConsole = PlaySignature.fromSubjectPublicKeyInfo(base64.decode(_playConsoleKey));
    expect(PlaySignature.zykl.modulus, fromConsole.modulus);
    expect(PlaySignature.zykl.exponent, BigInt.from(65537));
    expect(PlaySignature.zykl.modulus.bitLength, 2048);
    expect(PlaySignature.zykl.verify(signedJson, genuineSignature), isFalse,
        reason: 'signed by the test key, not Play');
  });
}
