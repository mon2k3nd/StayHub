package com.stayhub.api.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Cache tạm thời trong bộ nhớ (fallback khi chưa cấu hình Redis thật).
 *
 * <p><b>SEC8</b>: Bản cũ dùng {@link ConcurrentHashMap} không giới hạn và chỉ
 * xoá entry khi {@code get()} được gọi lại — nghĩa là các key hết hạn nhưng
 * không bao giờ được đọc sẽ tồn tại vĩnh viễn → rò rỉ bộ nhớ (OOM) khi có
 * lượng lớn key (ví dụ OTP/blacklist dưới tải cao hoặc bị tấn công).</p>
 *
 * <p>Bản mới bổ sung:</p>
 * <ul>
 *   <li>Giới hạn số entry tối đa ({@link #MAX_ENTRIES}) — chống OOM.</li>
 *   <li>Dọn dẹp định kỳ các entry hết hạn (kể cả không được đọc lại).</li>
 *   <li>Ghi log cảnh báo khi cache đầy.</li>
 * </ul>
 */
@Slf4j
@Service
public class RedisCacheService {

    /** Số entry tối đa — bảo vệ bộ nhớ khi bị tấn công làm ngập key. */
    private static final int MAX_ENTRIES = 100_000;

    /** Chu kỳ dọn dẹp entry hết hạn (ms). */
    private static final long CLEANUP_INTERVAL_MS = 60_000L;

    private final Map<String, CacheEntry> cache = new ConcurrentHashMap<>();
    private final AtomicLong lastCleanup = new AtomicLong(System.currentTimeMillis());

    /** Entry cache kèm thời điểm hết hạn. */
    private record CacheEntry(String value, long expireAt) {
        boolean isExpired(long now) {
            return now > expireAt;
        }
    }

    public void set(String key, String value, long timeoutSeconds) {
        maybeCleanup();

        // Bảo vệ bộ nhớ: nếu đầy, dọn entry hết hạn trước; nếu vẫn đầy thì từ chối.
        if (cache.size() >= MAX_ENTRIES && !cache.containsKey(key)) {
            evictExpired(System.currentTimeMillis());
            if (cache.size() >= MAX_ENTRIES) {
                log.warn("[Cache] Đã đạt giới hạn {} entry — từ chối ghi key mới để bảo vệ bộ nhớ.", MAX_ENTRIES);
                return;
            }
        }

        cache.put(key, new CacheEntry(value, System.currentTimeMillis() + (timeoutSeconds * 1000)));
    }

    public String get(String key) {
        CacheEntry entry = cache.get(key);
        if (entry == null) {
            return null;
        }
        if (entry.isExpired(System.currentTimeMillis())) {
            cache.remove(key);
            return null;
        }
        return entry.value();
    }

    public void delete(String key) {
        cache.remove(key);
    }

    /** Dọn dẹp định kỳ — tối đa 1 lần mỗi {@link #CLEANUP_INTERVAL_MS}. */
    private void maybeCleanup() {
        long now = System.currentTimeMillis();
        long last = lastCleanup.get();
        if (now - last < CLEANUP_INTERVAL_MS) {
            return;
        }
        if (!lastCleanup.compareAndSet(last, now)) {
            return;
        }
        evictExpired(now);
    }

    private void evictExpired(long now) {
        cache.entrySet().removeIf(e -> e.getValue().isExpired(now));
    }
}
