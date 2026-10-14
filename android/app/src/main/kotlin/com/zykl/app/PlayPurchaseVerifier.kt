package com.zykl.app

import android.util.Base64
import java.security.KeyFactory
import java.security.Signature
import java.security.spec.X509EncodedKeySpec

/**
 * Checks that a Google Play purchase really comes from Google Play: Play signs each purchase's JSON with this app's
 * private key (SHA1withRSA). Tools that fake Play's "purchased" answer on rooted phones can't produce that signature.
 */
object PlayPurchaseVerifier {
    /** Play Console → Monetize with Play → Monetization setup → Licensing. Public by design: it can only check. */
    private const val PLAY_PUBLIC_KEY =
        "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAjYk+L7PU1JC6dqdV1lqKp+R9avAus9yhzSA2uIINqfcQ0Mz07Pxy7dWNHvfuKuL6yYeslRSwTZtRya+f7Ov4E7exQB4uzse8+6WTlGuggJiHvl40Yzctrb2jZ7JHeT7An2Igp2E5IyiRka8kNiFw0PNwbP4gBB/up8UY48GsoOxgVGeZLQ2atY2wRwXhGWTXGx1Z8rULbrkaemHqYa9lCT6Odw8CPOsheFKYPqzOBPA72vA2bmtc3RQkseRb5pe5i9/nQx4B6h85avfTN5l5iqkhLRUpxUldzBGmQA5IhfdC5UR5xl4uBdBDVDNiks6wcqsUqrfcDPrt/SjlqfpMSQIDAQAB"

    fun verify(signedData: String, signature: String): Boolean {
        if (signedData.isEmpty() || signature.isEmpty()) return false
        return try {
            val key = KeyFactory.getInstance("RSA")
                .generatePublic(X509EncodedKeySpec(Base64.decode(PLAY_PUBLIC_KEY, Base64.DEFAULT)))
            Signature.getInstance("SHA1withRSA").run {
                initVerify(key)
                update(signedData.toByteArray(Charsets.UTF_8))
                verify(Base64.decode(signature, Base64.DEFAULT))
            }
        } catch (_: Exception) {
            false
        }
    }
}
