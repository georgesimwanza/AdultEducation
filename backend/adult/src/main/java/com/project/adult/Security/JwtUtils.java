package com.project.adult.Security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

/**
 * Handles all JWT operations:
 *   - generateToken()  : creates a signed JWT after successful login
 *   - extractEmail()   : reads the subject (email) out of a token
 *   - isTokenValid()   : checks signature + expiry, then matches against UserDetails
 *
 * Configuration (add these to application.properties):
 *   jwt.secret=your-secret-key-must-be-at-least-32-characters-long
 *   jwt.expiration=86400000
 *
 * The secret must be at least 256 bits (32 chars) for HMAC-SHA256.
 * Use a long random string in production — never commit it to git.
 * Store it as an environment variable or in a secrets manager.
 */
@Component
public class JwtUtils {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.expiration}")
    private long expirationMs;   // milliseconds, e.g. 86400000 = 24 hours

    // -------------------------------------------------------------------------
    // Key
    // -------------------------------------------------------------------------

    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    // -------------------------------------------------------------------------
    // Generate
    // -------------------------------------------------------------------------

    /**
     * Creates a JWT with the user's email as the subject.
     * Called from your AuthController after a successful authenticate() call.
     */
    public String generateToken(UserDetails userDetails) {
        return Jwts.builder()
                .subject(userDetails.getUsername())   // getUsername() returns email in UserPrincipal
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + expirationMs))
                .signWith(getSigningKey())
                .compact();
    }

    // -------------------------------------------------------------------------
    // Extract
    // -------------------------------------------------------------------------

    public String extractEmail(String token) {
        return parseClaims(token).getSubject();
    }

    public Date extractExpiration(String token) {
        return parseClaims(token).getExpiration();
    }

    // -------------------------------------------------------------------------
    // Validate
    // -------------------------------------------------------------------------

    /**
     * Returns true if:
     *   1. The token signature is valid (proves it was issued by us)
     *   2. The token is not expired
     *   3. The email in the token matches the UserDetails we loaded from DB
     */
    public boolean isTokenValid(String token, UserDetails userDetails) {
        try {
            String email = extractEmail(token);
            boolean notExpired = extractExpiration(token).after(new Date());
            return email.equals(userDetails.getUsername()) && notExpired;
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }

    // -------------------------------------------------------------------------
    // Internal parser — throws JwtException on any problem
    // -------------------------------------------------------------------------

    private Claims parseClaims(String token) {
        return Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}