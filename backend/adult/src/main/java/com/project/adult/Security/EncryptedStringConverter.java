package com.project.adult.Security;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * Encrypts personal data columns (phone, date of birth, address) with
 * AES-256-GCM before they reach the database.
 *
 * Stored format: "enc:" + base64(12-byte IV + ciphertext). Values without
 * the prefix are treated as legacy plaintext and returned unchanged, so
 * rows written before encryption was added still load.
 *
 * Key: set app.encryption.key (any string; it is hashed to 256 bits),
 * ideally from the DATA_ENCRYPTION_KEY environment variable. If it is
 * blank, the key is derived from jwt.secret so development still works.
 * Changing the key makes previously encrypted values unreadable.
 */
@Converter
@Component
public class EncryptedStringConverter implements AttributeConverter<String, String> {

    private static final String PREFIX = "enc:";
    private static final int IV_LENGTH = 12;
    private static final int TAG_BITS = 128;
    private static final SecureRandom RANDOM = new SecureRandom();

    // Static because Hibernate may create its own converter instances;
    // Spring sets it once at startup through the instance below.
    private static volatile SecretKeySpec key;

    public EncryptedStringConverter() {
    }

    @Value("${app.encryption.key:}")
    public void setConfiguredKey(String configured) {
        init(configured);
    }

    @Value("${jwt.secret}")
    public void setJwtSecret(String jwtSecret) {
        if (key == null) init(jwtSecret);
    }

    private static synchronized void init(String material) {
        if (material == null || material.isBlank()) return;
        try {
            byte[] hash = MessageDigest.getInstance("SHA-256")
                    .digest(material.getBytes(StandardCharsets.UTF_8));
            key = new SecretKeySpec(hash, "AES");
        } catch (Exception e) {
            throw new IllegalStateException("Could not initialise data encryption key", e);
        }
    }

    @Override
    public String convertToDatabaseColumn(String plain) {
        if (plain == null || plain.isEmpty()) return plain;
        requireKey();
        try {
            byte[] iv = new byte[IV_LENGTH];
            RANDOM.nextBytes(iv);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, key, new GCMParameterSpec(TAG_BITS, iv));
            byte[] encrypted = cipher.doFinal(plain.getBytes(StandardCharsets.UTF_8));
            byte[] out = ByteBuffer.allocate(iv.length + encrypted.length).put(iv).put(encrypted).array();
            return PREFIX + Base64.getEncoder().encodeToString(out);
        } catch (Exception e) {
            throw new IllegalStateException("Failed to encrypt value", e);
        }
    }

    @Override
    public String convertToEntityAttribute(String stored) {
        if (stored == null || !stored.startsWith(PREFIX)) return stored;
        requireKey();
        try {
            byte[] data = Base64.getDecoder().decode(stored.substring(PREFIX.length()));
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE, key, new GCMParameterSpec(TAG_BITS, data, 0, IV_LENGTH));
            byte[] plain = cipher.doFinal(data, IV_LENGTH, data.length - IV_LENGTH);
            return new String(plain, StandardCharsets.UTF_8);
        } catch (Exception e) {
            throw new IllegalStateException("Failed to decrypt value — was app.encryption.key changed?", e);
        }
    }

    private static void requireKey() {
        if (key == null) throw new IllegalStateException("Data encryption key is not configured");
    }
}
