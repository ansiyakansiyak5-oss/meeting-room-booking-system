package com.meetingroom;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/**
 * Utility class for hashing and verifying passwords securely.
 * Uses SHA-256 with fallback to legacy verification for backward compatibility.
 */
public class PasswordUtil {

    /**
     * Hashes a plaintext password using SHA-256.
     */
    public static String hashPassword(String password) {
        if (password == null) return null;
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(password.getBytes(StandardCharsets.UTF_8));
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 algorithm not available", e);
        }
    }

    /**
     * Verifies an input password against stored hash.
     * Supports both SHA-256 hash match and legacy plaintext match for smooth migration.
     */
    public static boolean verifyPassword(String inputPassword, String storedPassword) {
        if (inputPassword == null || storedPassword == null) return false;
        
        String inputHashed = hashPassword(inputPassword);
        // Check SHA-256 hash
        if (inputHashed.equalsIgnoreCase(storedPassword)) {
            return true;
        }
        // Backward compatibility fallback: direct comparison if legacy record was unhashed
        return storedPassword.equals(inputPassword);
    }

    /**
     * Checks if a stored password string is already a valid 64-character SHA-256 hex string.
     */
    public static boolean isHashed(String storedPassword) {
        if (storedPassword == null || storedPassword.length() != 64) {
            return false;
        }
        return storedPassword.matches("^[0-9a-fA-F]{64}$");
    }
}
