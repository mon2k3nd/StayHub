package com.stayhub.api.config;

import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.MalformedJwtException;
import io.jsonwebtoken.security.SignatureException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

@Slf4j
@Component
@RequiredArgsConstructor
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain)
            throws ServletException, IOException {

        String authHeader = request.getHeader("Authorization");

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        String token = authHeader.substring(7);

        try {

            if (jwtUtil.isTokenValid(token)) {

                Long userId = jwtUtil.extractUserId(token);
                String role = jwtUtil.extractRole(token);

                if (SecurityContextHolder.getContext().getAuthentication() == null) {

                    UsernamePasswordAuthenticationToken authentication =
                            new UsernamePasswordAuthenticationToken(
                                    userId,
                                    null,
                                    List.of(
                                            new SimpleGrantedAuthority("ROLE_" + role)
                                    )
                            );

                    authentication.setDetails(userId);

                    SecurityContextHolder.getContext()
                            .setAuthentication(authentication);
                }
            }

        } catch (ExpiredJwtException e) {
            // Token hết hạn là luồng bình thường (client sẽ tự refresh) — log ở mức debug.
            log.debug("[JWT] Token hết hạn cho {} {}", request.getMethod(), request.getRequestURI());
        } catch (SignatureException | MalformedJwtException e) {
            // SEC7: Token sai chữ ký / hỏng có thể là dấu hiệu tấn công giả mạo token.
            // Ghi log WARN để có thể phát hiện và điều tra (trước đây bị nuốt im lặng).
            log.warn("[JWT] Token không hợp lệ ({}): {} {}",
                    e.getClass().getSimpleName(), request.getMethod(), request.getRequestURI());
        } catch (Exception e) {
            // SEC7: Không nuốt mọi lỗi một cách im lặng — log để phát hiện bất thường.
            log.warn("[JWT] Lỗi xác thực token: {} {} - {}",
                    request.getMethod(), request.getRequestURI(), e.getMessage());
        }

        filterChain.doFilter(request, response);
    }
}