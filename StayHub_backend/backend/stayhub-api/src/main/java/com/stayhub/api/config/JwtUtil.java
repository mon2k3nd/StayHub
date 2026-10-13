package com.stayhub.api.config;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;

@Component
public class JwtUtil {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.expiration}")
    private Long expiration;

    private SecretKey signingKey;

    @PostConstruct
    private void init() {

        byte[] keyBytes = secret.getBytes();

        if (keyBytes.length < 32) {
            throw new IllegalArgumentException(
                    "jwt.secret phải có ít nhất 32 ký tự"
            );
        }

        this.signingKey = Keys.hmacShaKeyFor(keyBytes);
    }

    public String generateToken(
            Long userId,
            String role,
            String planType) {

        return Jwts.builder()
                .subject(userId.toString())
                .claim("role", role)
                .claim("planType", planType)
                .issuedAt(new Date())
                .expiration(
                        new Date(
                                System.currentTimeMillis() + expiration
                        )
                )
                .signWith(signingKey)
                .compact();
    }

    public String generateRegistrationToken(String emailOrPhone) {
        return Jwts.builder()
                .subject(emailOrPhone)
                .claim("purpose", "registration")
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + 15 * 60 * 1000)) // 15 mins
                .signWith(signingKey)
                .compact();
    }

    public String generateAccessToken(
            Long userId,
            String role,
            String planType) {

        return Jwts.builder()
                .subject(userId.toString())
                .claim("role", role)
                .claim("planType", planType)
                .claim("tokenType", "ACCESS")
                .claim("jti", java.util.UUID.randomUUID().toString())
                .issuedAt(new Date())
                .expiration(
                        new Date(
                                System.currentTimeMillis() + 15 * 60 * 1000L // 15 mins
                        )
                )
                .signWith(signingKey)
                .compact();
    }

    public String generateRefreshToken(
            Long userId,
            String role,
            String planType) {

        return Jwts.builder()
                .subject(userId.toString())
                .claim("role", role)
                .claim("planType", planType)
                .claim("tokenType", "REFRESH")
                .claim("jti", java.util.UUID.randomUUID().toString())
                .issuedAt(new Date())
                .expiration(
                        new Date(
                                System.currentTimeMillis() + 30L * 24 * 60 * 60 * 1000L // 30 days
                        )
                )
                .signWith(signingKey)
                .compact();
    }

    public Claims extractClaims(String token) {

        return Jwts.parser()
                .verifyWith(signingKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public Long extractUserId(String token) {
        return Long.parseLong(
                extractClaims(token).getSubject()
        );
    }

    public String extractUsername(String token) {
        return extractClaims(token).getSubject();
    }

    public String validateAndGetTargetFromRegistrationToken(String token) {
        try {
            Claims claims = extractClaims(token);
            if (!"registration".equals(claims.get("purpose"))) {
                throw new org.springframework.web.server.ResponseStatusException(
                        org.springframework.http.HttpStatus.BAD_REQUEST,
                        "Token không hợp lệ (Sai mục đích)"
                );
            }
            return claims.getSubject();
        } catch (JwtException e) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.BAD_REQUEST,
                    "Registration token không hợp lệ hoặc đã hết hạn"
            );
        }
    }

    public String extractRole(String token) {
        return (String) extractClaims(token)
                .get("role");
    }

    public boolean isTokenValid(String token) {

        try {

            Claims claims = extractClaims(token);

            return claims.getExpiration()
                    .after(new Date());

        } catch (JwtException | IllegalArgumentException e) {

            return false;
        }
    }
}