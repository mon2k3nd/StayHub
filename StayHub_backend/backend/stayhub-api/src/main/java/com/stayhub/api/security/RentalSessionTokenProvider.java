package com.stayhub.api.security;

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
public class RentalSessionTokenProvider {

    @Value("${jwt.secret}")
    private String secret;

    private final long EXPIRATION_TIME = 60 * 60 * 1000L; // 1 hour

    private SecretKey signingKey;

    @PostConstruct
    private void init() {
        byte[] keyBytes = secret.getBytes();
        if (keyBytes.length < 32) {
            throw new IllegalArgumentException("jwt.secret phải có ít nhất 32 ký tự");
        }
        this.signingKey = Keys.hmacShaKeyFor(keyBytes);
    }

    public String generateToken(Long roomId) {
        return Jwts.builder()
                .subject(roomId.toString())
                .claim("type", "RENTAL_SESSION")
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + EXPIRATION_TIME))
                .signWith(signingKey)
                .compact();
    }

    public boolean validateToken(String token, Long roomId) {
        try {
            Claims claims = Jwts.parser()
                    .verifyWith(signingKey)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();

            if (!claims.get("type").equals("RENTAL_SESSION")) {
                return false;
            }

            Long tokenRoomId = Long.parseLong(claims.getSubject());
            return tokenRoomId.equals(roomId) && claims.getExpiration().after(new Date());

        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }
}
