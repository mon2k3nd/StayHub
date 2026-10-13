package com.stayhub.api.config;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.http.HttpMethod;

import java.util.Arrays;
import java.util.List;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;
    private final RateLimitFilter rateLimitFilter;

    /**
     * Danh sách origin được phép CORS (phân tách bằng dấu phẩy).
     * Mặc định chỉ cho phép localhost khi dev. Ở production PHẢI override
     * qua biến môi trường {@code STAYHUB_CORS_ORIGINS} (ví dụ:
     * {@code https://stayhub.vn,https://app.stayhub.vn}).
     */
    @Value("${stayhub.cors.allowed-origins:http://localhost:3000,http://localhost:8080,http://localhost:5173,http://localhost:62686,http://localhost:62687}")
    private String allowedOriginsRaw;

    /** Bật/tắt expose Swagger & Actuator. Production nên đặt false. */
    @Value("${stayhub.security.expose-dev-endpoints:false}")
    private boolean exposeDevEndpoints;

    private static final String[] PUBLIC_ENDPOINTS = {
        "/api/auth/**",
        "/v1/auth/**",
        "/v1/rooms/public/**",
        "/api/branches/public/**",
        "/v1/invoices/webhook-vietqr",
        "/swagger-ui/**",
        "/v3/api-docs/**"
    };

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .csrf(csrf -> csrf.disable())
            .sessionManagement(sm ->
                sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .exceptionHandling(exc -> exc
                .authenticationEntryPoint((request, response, authException) -> {
                    response.setStatus(jakarta.servlet.http.HttpServletResponse.SC_UNAUTHORIZED);
                    response.setContentType("application/json;charset=UTF-8");
                    response.getWriter().write("{\"success\":false,\"message\":\"Vui lòng đăng nhập lại.\"}");
                })
            )
            .authorizeHttpRequests(auth -> auth
                        // SEC5: các endpoint debug/test/system/actuator KHÔNG được public ở
                        // production. Chỉ mở khi cờ exposeDevEndpoints = true (môi trường dev).
                        .requestMatchers("/v1/system/**", "/v1/test/**", "/actuator/**")
                            .access(devEndpointsAccess())
                        .requestMatchers("/v1/auth/**", "/swagger-ui/**", "/v3/api-docs/**").permitAll()
                        .requestMatchers("/v1/auth/forgot-password", "/v1/auth/reset-password").permitAll()
                        .requestMatchers(HttpMethod.GET, "/v1/rooms/**", "/v1/branches/**", "/v1/marketplace/**").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/v1/addresses/**", "/api/v1/reviews/**").permitAll()
                        .requestMatchers("/v1/images/**", "/uploads/**").permitAll()
                        .requestMatchers("/v1/staff/**").hasAnyRole("STAFF", "OWNER")
                .anyRequest().authenticated()
            )
            .headers(headers -> headers
                .xssProtection(xss -> xss.headerValue(org.springframework.security.web.header.writers.XXssProtectionHeaderWriter.HeaderValue.ENABLED_MODE_BLOCK))
                .frameOptions(frame -> frame.deny())
                .httpStrictTransportSecurity(hsts -> hsts.includeSubDomains(true).maxAgeInSeconds(31536000))
                .contentSecurityPolicy(csp -> csp.policyDirectives("script-src 'self'"))
            )
            // Thêm Rate Limit Filter trước JWT Filter để chống spam
            .addFilterBefore(rateLimitFilter, UsernamePasswordAuthenticationFilter.class)
            // FIX: đăng ký JwtAuthFilter vào SecurityFilterChain
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager(
            AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    /**
     * SEC5: Trả về AuthorizationManager cho phép truy cập endpoint dev khi
     * {@code exposeDevEndpoints = true}, ngược lại chặn hoàn toàn (denyAll).
     */
    private org.springframework.security.authorization.AuthorizationManager<org.springframework.security.web.access.intercept.RequestAuthorizationContext> devEndpointsAccess() {
        return (authentication, context) -> new org.springframework.security.authorization.AuthorizationDecision(exposeDevEndpoints);
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();

        // SEC4: KHÔNG dùng allowedOriginPatterns("*") kèm allowCredentials(true).
        // Tổ hợp đó cho phép mọi website đọc dữ liệu đã xác thực của người dùng
        // (credential leak / CSRF qua CORS). Chỉ whitelist origin cụ thể.
        // SEC4: Với localhost (dev), dùng pattern để handle mọi port ngẫu nhiên
        // (Flutter web thường dùng port động như 62686, 62687, v.v.).
        // Với production origin, vẫn whitelist cụ thể để tránh credential leak.
        List<String> origins = Arrays.stream(allowedOriginsRaw.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .toList();
        List<String> localhostOrigins = origins.stream()
                .filter(o -> o.contains("localhost") || o.contains("127.0.0.1"))
                .toList();
        List<String> productionOrigins = origins.stream()
                .filter(o -> !o.contains("localhost") && !o.contains("127.0.0.1"))
                .toList();

        if (!productionOrigins.isEmpty()) {
            config.setAllowedOrigins(productionOrigins);
        }
        // Pattern cho localhost: cho phép mọi port
        List<String> patterns = new java.util.ArrayList<>(localhostOrigins);
        patterns.add("http://localhost:*");
        patterns.add("http://127.0.0.1:*");
        // Cho phép mọi tunnel tạm thời (cloudflared quick tunnel, ngrok) để test
        // trên thiết bị thật / iPhone qua web mà không cần sửa cấu hình mỗi lần
        // URL tunnel đổi. An toàn vì đây là origin công khai, không phải localhost.
        patterns.add("https://*.trycloudflare.com");
        patterns.add("https://*.ngrok-free.app");
        patterns.add("https://*.ngrok.io");
        config.setAllowedOriginPatterns(patterns);

        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"));
        config.setAllowedHeaders(List.of("Authorization", "Content-Type", "X-Request-Timestamp",
                "X-Request-Nonce", "X-Request-Signature", "ngrok-skip-browser-warning"));
        config.setExposedHeaders(List.of("Authorization"));
        config.setAllowCredentials(true);
        config.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
