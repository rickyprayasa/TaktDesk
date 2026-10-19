/// Vectors made with the JDK (KeyPairGenerator RSA 2048, Signature SHA1withRSA): the same algorithm Google Play
/// uses to sign purchases.
const testKey =
    'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuugAhVoCmhMMt6UbnQD72r9hK122ZTD+VcBoEhrdpxHfOvmU+oJXkXrwC4r5GWvl1uZyAS83/1Y303gvCg1RgpHYC7foId5hnEgsxQu6Jb7PdZes1FeMZXhfDPw4KgYoD3QC6atIR14agCaXtyKdSR/6906emMgNkkx8kXmSfPp/KF9W3fkcaAkitLAh+btd3zK2E/DxNRSLcZhSNpbCcg6CjktfstED7zzS4Df+n/SocDZkJ2hczpSQMEEWSNGu7COXMrH3GEt6UrZaPm8qpOfoWD/GSrskIz1+Ptb5FydVcb43mzPpehFiRugYkVzTo+coRvo+kAv5cT3zKNqsoQIDAQAB';
const signedJson =
    '{"orderId":"GPA.3394-1122","packageName":"com.zykl.app","productId":"studio_pro_lifetime","purchaseTime":1792000000000,"purchaseState":0,"purchaseToken":"tok","acknowledged":false}';
const genuineSignature =
    'BWEdaS229tiheXJ+WNuBUT0271TrovoUyjqUVrDZkuv/QbQ1UjQfJQt0iRPflpV7ZfzC5pkw5mvuYuFkTiWMPED4NnXPNF/rL78kBLZswMFIwjP9/pkNmrBK0ATHvMRvhmfoHBrxxURjBG4cn9b/U9dW4Du6qXv8Lyy1jkmN2qREylhRcpc8GHLAUFFrtEVby83yvb+DJnPFO7igF1ZTbt/Ya4dC8uzOiDvwgDzg1ZtqGgCnUzdq4Fxwxpu1Q5FK2wmKceNLVk7arTazUua5LFmgbplS/mx0LrX+P5ysl+QNomHMURw+W8bOGnyRwzgHmFG5e2yDPfUIzPdG1FCftA==';
const signatureByAnotherKey =
    'J0AF/rw1KMuwFBC/M5y46aiSogL+2cU1aw/hsJw/HvnnEmuHLC77YCpz9XRSfuvgTchU2DqdEz054HsOQLG21qjAuWTM1GbRXY+bwM7jtsQaD5/dFkCW2u8fk+8yePbOXIKhA+eApWhF0X2tnU8lp6xwX1T5aaxdirx4pWDk9Touy9pLBNReASEnIz4XBg/4huBLmSHGXTXd2uOpbdxSFcSHEw0gm9lnblP6nIJMEn44LaITw+f0zKrhlXKv2mF8e3YZHpZqfUB1xvjdlWXuEdhOjVlsjwrn1OZyRki4K5jdendDH0e5JoJAVmSZuPAEjG0eQY1BDtH2+5R5KYM3xw==';
