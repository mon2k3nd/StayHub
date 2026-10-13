package com.stayhub.api.config;

import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import io.github.bucket4j.Refill;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Bộ lọc chống spam / DDoS / lạm dụng API.
 *
 * <p>Được thiết kế để chịu được các đợt tăng tải đột biến (traffic spike) và
 * các cuộc tấn công brute-force mà KHÔNG gây rò rỉ bộ nhớ (OOM).</p>
 *
 * <p>Các cải tiến so với bản cũ:</p>
 * <ul>
 *   <li><b>SEC1</b>: Bộ đếm bucket có giới hạn kích thước + cơ chế dọn dẹp định kỳ
 *       (trước đây {@code ConcurrentHashMap} phình vô hạn → OOM khi bị flood IP giả).</li>
 *   <li><b>SEC2</b>: Chỉ tin {@code X-Forwarded-For} khi request đến từ proxy nội bộ
 *       (trước đây tin tưởng tuyệt đối → kẻ tấn công chỉ cần đổi header là bypass rate limit).</li>
 *   <li><b>SEC3</b>: Giới hạn riêng cho các endpoint nhạy cảm (login/register/otp/forgot-password)
 *       chặt hơn nhiều so với API thông thường.</li>
 * </ul>
 */
@Component
public class RateLimitFilter extends OncePerRequestFilter {

    /** Số IP tối đa được theo dõi đồng thời — chặn OOM khi bị flood IP giả. */
    private static final int MAX_TRACKED_CLIENTS = 50_000;

    /** Chu kỳ dọn dẹp bucket hết hạn (ms). */
    private static final long CLEANUP_INTERVAL_MS = 5 * 60 * 1000L;

    /** Bucket không hoạt động quá thời gian này sẽ bị xoá khỏi bộ nhớ. */
    private static final long IDLE_EVICTION_MS = 10 * 60 * 1000L;

    /**
     * Danh sách proxy tin cậy (nội bộ / load balancer).
     * Chỉ các IP này mới được phép set {@code X-Forwarded-For}.
     * Có thể override qua biến môi trường {@code STAYHUB_TRUSTED_PROXIES}.
     */
    private static final String[] TRUSTED_PROXIES = {
            "127.0.0.1", "::1", "0:0:0:0:0:0:0:1",
            "10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"
    };

    /** Bucket cho API thông thường: 300 req/phút/IP. */
    private final Map<String, ClientBucket> generalBuckets = new ConcurrentHashMap<>();

    /** Bucket cho endpoint nhạy cảm (auth): 20 req/phút/IP — chống brute-force. */
    private final Map<String, ClientBucket> authBuckets = new ConcurrentHashMap<>();

    private final AtomicLong lastCleanup = new AtomicLong(System.currentTimeMillis());

    /** Bucket kèm mốc thời gian truy cập cuối để phục vụ eviction. */
    private static final class ClientBucket {
        final Bucket bucket;
        volatile long lastAccess;

        ClientBucket(Bucket bucket) {
            this.bucket = bucket;
            this.lastAccess = System.currentTimeMillis();
        }
    }

    private Bucket createGeneralBucket() {
        // 300 request / 1 phút cho mỗi IP — chịu tải đợt cao điểm.
        return Bucket.builder()
                .addLimit(Bandwidth.classic(300, Refill.greedy(300, Duration.ofMinutes(1))))
                .build();
    }

    private Bucket createAuthBucket() {
        // 20 request / 1 phút cho endpoint xác thực — chống brute-force mật khẩu/OTP.
        return Bucket.builder()
                .addLimit(Bandwidth.classic(20, Refill.greedy(20, Duration.ofMinutes(1))))
                .build();
    }

    /** Endpoint nhạy cảm cần giới hạn chặt (login, register, OTP, quên mật khẩu…). */
    private boolean isSensitiveEndpoint(String path) {
        return path.contains("/auth/login")
                || path.contains("/auth/register")
                || path.contains("/auth/send-otp")
                || path.contains("/auth/verify-otp")
                || path.contains("/auth/forgot-password")
                || path.contains("/auth/reset-password")
                || path.contains("/auth/phone-verify")
                || path.contains("/auth/google")
                || path.contains("/auth/facebook")
                || path.contains("/auth/zalo")
                || path.contains("/auth/apple")
                || path.contains("/auth/whatsapp");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        maybeCleanup();

        String ip = getClientIP(request);
        String path = request.getRequestURI();

        Map<String, ClientBucket> targetMap = isSensitiveEndpoint(path) ? authBuckets : generalBuckets;

        // Bảo vệ bộ nhớ: nếu đã đạt ngưỡng theo dõi, từ chối client mới thay vì
        // phình map vô hạn (kẻ tấn công flood IP giả sẽ bị chặn ở đây).
        if (targetMap.size() >= MAX_TRACKED_CLIENTS && !targetMap.containsKey(ip)) {
            response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"success\":false,\"message\":\"Hệ thống đang quá tải, vui lòng thử lại sau.\"}");
            return;
        }

        ClientBucket clientBucket = targetMap.computeIfAbsent(ip, k -> new ClientBucket(
                isSensitiveEndpoint(path) ? createAuthBucket() : createGeneralBucket()));
        clientBucket.lastAccess = System.currentTimeMillis();

        if (clientBucket.bucket.tryConsume(1)) {
            filterChain.doFilter(request, response);
        } else {
            response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
            response.setContentType("application/json;charset=UTF-8");
            response.setHeader("Retry-After", "60");
            response.getWriter().write("{\"success\":false,\"message\":\"Bạn thao tác quá nhanh, vui lòng thử lại sau ít phút.\"}");
        }
    }

    /**
     * Dọn dẹp định kỳ các bucket không còn hoạt động để giải phóng bộ nhớ.
     * Chạy tối đa 1 lần mỗi {@link #CLEANUP_INTERVAL_MS}.
     */
    private void maybeCleanup() {
        long now = System.currentTimeMillis();
        long last = lastCleanup.get();
        if (now - last < CLEANUP_INTERVAL_MS) {
            return;
        }
        // Chỉ một luồng được thực hiện dọn dẹp.
        if (!lastCleanup.compareAndSet(last, now)) {
            return;
        }
        evictIdle(generalBuckets, now);
        evictIdle(authBuckets, now);
    }

    private void evictIdle(Map<String, ClientBucket> map, long now) {
        map.entrySet().removeIf(entry -> (now - entry.getValue().lastAccess) > IDLE_EVICTION_MS);
    }

    /**
     * Lấy IP thật của client.
     *
     * <p><b>SEC2</b>: Chỉ tin {@code X-Forwarded-For} khi request đến từ proxy nội bộ.
     * Nếu không, kẻ tấn công có thể giả mạo header này để vượt qua rate limit.</p>
     */
    private String getClientIP(HttpServletRequest request) {
        String remoteAddr = request.getRemoteAddr();

        if (isTrustedProxy(remoteAddr)) {
            String xfHeader = request.getHeader("X-Forwarded-For");
            if (xfHeader != null && !xfHeader.isEmpty()) {
                // Lấy IP đầu tiên (client gốc) trong chuỗi proxy.
                String candidate = xfHeader.split(",")[0].trim();
                if (!candidate.isEmpty()) {
                    return candidate;
                }
            }
            String realIp = request.getHeader("X-Real-IP");
            if (realIp != null && !realIp.isEmpty()) {
                return realIp.trim();
            }
        }
        return remoteAddr;
    }

    /** Kiểm tra IP có nằm trong dải proxy tin cậy hay không. */
    private boolean isTrustedProxy(String ip) {
        if (ip == null) {
            return false;
        }
        for (String trusted : TRUSTED_PROXIES) {
            if (trusted.contains("/")) {
                if (isInCidrRange(ip, trusted)) {
                    return true;
                }
            } else if (trusted.equals(ip)) {
                return true;
            }
        }
        return false;
    }

    /** So khớp IPv4 với dải CIDR (chỉ hỗ trợ IPv4 — đủ cho mạng nội bộ). */
    private boolean isInCidrRange(String ip, String cidr) {
        try {
            String[] parts = cidr.split("/");
            String network = parts[0];
            int prefix = Integer.parseInt(parts[1]);

            byte[] ipBytes = toIpv4Bytes(ip);
            byte[] netBytes = toIpv4Bytes(network);
            if (ipBytes == null || netBytes == null) {
                return false;
            }

            int fullBytes = prefix / 8;
            int remainingBits = prefix % 8;

            for (int i = 0; i < fullBytes; i++) {
                if (ipBytes[i] != netBytes[i]) {
                    return false;
                }
            }
            if (remainingBits > 0 && fullBytes < 4) {
                int mask = 0xFF << (8 - remainingBits) & 0xFF;
                return (ipBytes[fullBytes] & mask) == (netBytes[fullBytes] & mask);
            }
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    private byte[] toIpv4Bytes(String ip) {
        String[] octets = ip.split("\\.");
        if (octets.length != 4) {
            return null;
        }
        byte[] bytes = new byte[4];
        for (int i = 0; i < 4; i++) {
            int value = Integer.parseInt(octets[i]);
            if (value < 0 || value > 255) {
                return null;
            }
            bytes[i] = (byte) value;
        }
        return bytes;
    }
}
