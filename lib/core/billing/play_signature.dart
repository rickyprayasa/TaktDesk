import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Google Play signs each purchase's JSON (SHA1withRSA, RSASSA-PKCS1-v1_5) with this app's private key; a purchase
/// that fails this check was not made through Play. The check runs here, in the obfuscated AOT code, rather than in
/// Kotlin, where a decompiler finds it by its algorithm name and one changed line would bypass it.
class PlaySignature {
  /// RSA modulus and public exponent.
  final BigInt modulus;
  final BigInt exponent;

  PlaySignature._(this.modulus, this.exponent);

  /// From a DER SubjectPublicKeyInfo (what Play Console shows base64-encoded under Licensing).
  factory PlaySignature.fromSubjectPublicKeyInfo(List<int> der) {
    final outer = _Der(der).sequence();
    outer.sequence(); // AlgorithmIdentifier (rsaEncryption, NULL)
    final rsaKey = _Der(outer.bitString()).sequence();
    return PlaySignature._(rsaKey.integer(), rsaKey.integer());
  }

  /// The ZYKL key from Play Console (Monetize with Play → Monetization setup → Licensing). Public by design; kept as
  /// masked bytes only so the APK holds no greppable "MIIBIjAN…" string that points at this code.
  static final PlaySignature zykl = PlaySignature.fromSubjectPublicKeyInfo(_unmask(_key));

  /// SHA-1 DigestInfo prefix (RFC 8017 §9.2).
  static const List<int> _sha1DigestInfo = [
    0x30, 0x21, 0x30, 0x09, 0x06, 0x05, 0x2b, 0x0e, 0x03, 0x02, 0x1a, 0x05, 0x00, 0x04, 0x14, //
  ];

  /// Whether [signatureBase64] is this key's signature over [signedData] (UTF-8).
  bool verify(String signedData, String signatureBase64) {
    if (signedData.isEmpty || signatureBase64.isEmpty) return false;
    final List<int> signature;
    try {
      signature = base64.decode(base64.normalize(signatureBase64.replaceAll(RegExp(r'\s'), '')));
    } on FormatException {
      return false;
    }
    final k = (modulus.bitLength + 7) >> 3;
    if (signature.length != k) return false;
    final s = _toBigInt(signature);
    if (s >= modulus) return false;
    final em = _toBytes(s.modPow(exponent, modulus), k);
    final digest = sha1.convert(utf8.encode(signedData)).bytes;
    final t = [..._sha1DigestInfo, ...digest];
    // EM = 0x00 || 0x01 || PS (0xFF, >= 8 bytes) || 0x00 || T
    final psEnd = k - t.length - 1;
    if (psEnd < 10) return false;
    var diff = em[0] | (em[1] ^ 0x01) | em[psEnd];
    for (var i = 2; i < psEnd; i++) {
      diff |= em[i] ^ 0xFF;
    }
    for (var i = 0; i < t.length; i++) {
      diff |= em[psEnd + 1 + i] ^ t[i];
    }
    return diff == 0;
  }

  static BigInt _toBigInt(List<int> bytes) {
    var r = BigInt.zero;
    for (final b in bytes) {
      r = (r << 8) | BigInt.from(b);
    }
    return r;
  }

  static List<int> _toBytes(BigInt v, int length) {
    final out = Uint8List(length);
    var x = v;
    final mask = BigInt.from(0xFF);
    for (var i = length - 1; i >= 0 && x > BigInt.zero; i--) {
      out[i] = (x & mask).toInt();
      x = x >> 8;
    }
    return out;
  }

  static const List<int> _mask = [0x5A, 0xC3, 0x17, 0x9E, 0x6B, 0x21, 0xD4];

  static List<int> _unmask(List<int> masked) => [
        for (var i = 0; i < masked.length; i++) masked[i] ^ _mask[i % _mask.length] ^ (i * 31 & 0xFF),
      ];

  static const List<int> _key = [
    0x6a,
    0x5e,
    0x28,
    0xe1,
    0x27,
    0xb7,
    0x68,
    0x8a,
    0x11,
    0x86,
    0xe0,
    0xb8,
    0xa2,
    0x4a,
    0xe9,
    0x13,
    0xe6,
    0x94,
    0x45,
    0x6f,
    0x3a,
    0xd0,
    0x66,
    0xde,
    0x46,
    0xee,
    0x06,
    0x9b,
    0x3c,
    0xc2,
    0xb4,
    0x5e,
    0x8b,
    0x53,
    0x43,
    0x59,
    0xb0,
    0xdf,
    0xd0,
    0x06,
    0x69,
    0x99,
    0x3a,
    0x51,
    0x16,
    0x3b,
    0xa3,
    0x1a,
    0xa3,
    0x51,
    0xb0,
    0x50,
    0x22,
    0x2e,
    0x18,
    0xa1,
    0x33,
    0xe9,
    0x31,
    0x8d,
    0x97,
    0xc0,
    0x5b,
    0x52,
    0xf4,
    0xd8,
    0xb0,
    0xba,
    0xe9,
    0x63,
    0xdc,
    0x28,
    0x42,
    0x9c,
    0x10,
    0x2a,
    0x17,
    0xe7,
    0x9b,
    0x64,
    0xd4,
    0x6d,
    0x48,
    0x75,
    0xe3,
    0x9c,
    0xcd,
    0x5a,
    0x58,
    0xb7,
    0xfb,
    0xf0,
    0x78,
    0xb8,
    0x17,
    0x12,
    0x92,
    0xdc,
    0x35,
    0x7e,
    0x15,
    0x8b,
    0xff,
    0x9f,
    0xf0,
    0x16,
    0xb0,
    0x71,
    0x1e,
    0x33,
    0xd3,
    0x25,
    0x52,
    0xeb,
    0x67,
    0x2d,
    0x53,
    0x69,
    0xa9,
    0x1e,
    0xe6,
    0x0d,
    0xfb,
    0xe9,
    0x97,
    0xb0,
    0x61,
    0x9c,
    0x57,
    0x9e,
    0xb7,
    0xdc,
    0x8f,
    0x20,
    0xc0,
    0x6d,
    0xce,
    0x6d,
    0x06,
    0xae,
    0x8a,
    0xe6,
    0x04,
    0xbf,
    0xcb,
    0x5d,
    0x0a,
    0xfb,
    0xd1,
    0x3c,
    0xb0,
    0x3d,
    0xa7,
    0xf4,
    0x39,
    0x1e,
    0x10,
    0x5c,
    0xe5,
    0xc0,
    0x58,
    0x45,
    0x09,
    0xcd,
    0xdb,
    0xbd,
    0x36,
    0x77,
    0xb7,
    0x39,
    0x31,
    0x6c,
    0xba,
    0x33,
    0xdf,
    0x0f,
    0x44,
    0x63,
    0x0d,
    0x9f,
    0x1f,
    0x8a,
    0x5b,
    0x84,
    0xe6,
    0xe3,
    0x97,
    0xe5,
    0xfa,
    0xd8,
    0x6e,
    0x53,
    0xd7,
    0x0a,
    0xd1,
    0x3e,
    0xe9,
    0x1a,
    0xd1,
    0x6c,
    0x72,
    0x0e,
    0xf0,
    0x57,
    0x49,
    0x68,
    0xa2,
    0x7e,
    0xe1,
    0xa0,
    0xee,
    0xbe,
    0x8d,
    0x3b,
    0xea,
    0x74,
    0x21,
    0x09,
    0x81,
    0x23,
    0xde,
    0xf3,
    0x25,
    0x42,
    0xc3,
    0x77,
    0x96,
    0x04,
    0xb4,
    0x84,
    0x0f,
    0x49,
    0xc4,
    0x19,
    0xa2,
    0xe9,
    0x66,
    0x50,
    0x11,
    0x4b,
    0x8d,
    0x18,
    0x04,
    0x61,
    0x4d,
    0xd8,
    0xcc,
    0xb7,
    0xcb,
    0x80,
    0x76,
    0x17,
    0x9e,
    0x6e,
    0x9d,
    0xfa,
    0x9c,
    0x7c,
    0x0f,
    0x43,
    0xc6,
    0x4a,
    0x7a,
    0x9c,
    0xdc,
    0x13,
    0x2f,
    0xc2,
    0x50,
    0x6f,
    0x4b,
    0x3e,
    0x94,
    0x27,
    0x46,
    0x4e,
    0x58,
    0x57,
    0x57,
    0x11,
    0x48,
    0x29,
    0xcc,
    0xf3,
    0xea,
    0x0b,
    0x8c,
    0xd7,
    0x6a,
    0xea,
    0x83,
    0x57,
    0x7d,
    0xae,
  ];
}

/// Just enough DER to read an RSA SubjectPublicKeyInfo.
class _Der {
  final List<int> _b;
  int _p = 0;

  _Der(this._b);

  List<int> _read(int tag) {
    if (_p >= _b.length || _b[_p++] != tag) throw const FormatException('Unexpected DER tag');
    var len = _b[_p++];
    if (len & 0x80 != 0) {
      final n = len & 0x7F;
      len = 0;
      for (var i = 0; i < n; i++) {
        len = (len << 8) | _b[_p++];
      }
    }
    if (_p + len > _b.length) throw const FormatException('DER length out of range');
    final v = _b.sublist(_p, _p + len);
    _p += len;
    return v;
  }

  _Der sequence() => _Der(_read(0x30));

  BigInt integer() => PlaySignature._toBigInt(_read(0x02));

  /// BIT STRING contents without the leading "unused bits" byte.
  List<int> bitString() => _read(0x03).sublist(1);
}
