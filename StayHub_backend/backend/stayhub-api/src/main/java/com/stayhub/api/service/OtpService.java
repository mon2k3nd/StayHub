package com.stayhub.api.service;

import com.stayhub.api.dto.request.SendOtpRequest;
import com.stayhub.api.dto.response.SendOtpResponse;
import com.stayhub.api.entity.Otp;
import com.stayhub.api.repository.OtpRepository;
import com.stayhub.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
@RequiredArgsConstructor
@Slf4j
public class OtpService {

    private final OtpRepository otpRepository;
    private final UserRepository userRepository;
    private final EmailService emailService;
    private final com.stayhub.api.config.JwtUtil jwtUtil;

    @Value("${spring.profiles.active:dev}")
    private String activeProfile;

    private static final int OTP_EXPIRY_MINUTES = 10;
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    /** SEC9: Giới hạn số target theo dõi đồng thời — chống OOM khi bị flood. */
    private static final int MAX_TRACKED_TARGETS = 50_000;

    /** Số lần nhập sai OTP tối đa trước khi tạm khoá target (chống brute-force). */
    private static final int MAX_VERIFY_ATTEMPTS = 5;

    /** Thời gian tạm khoá sau khi vượt số lần thử (ms). */
    private static final long VERIFY_LOCKOUT_MS = 15 * 60 * 1000L;

    /** Thời gian cooldown giữa 2 lần gửi OTP (ms). */
    private static final long SEND_COOLDOWN_MS = 60_000L;

    /** Thời điểm gửi OTP gần nhất theo target. */
    private final Map<String, Long> requestTimestamps = new ConcurrentHashMap<>();

    /** Số lần xác thực sai liên tiếp theo target (SEC9 — chống brute-force OTP). */
    private final Map<String, int[]> verifyAttempts = new ConcurrentHashMap<>();

    /** Thời điểm bắt đầu tạm khoá xác thực theo target. */
    private final Map<String, Long> verifyLockUntil = new ConcurrentHashMap<>();

    public SendOtpResponse sendOtp(SendOtpRequest request) {

        long currentTime = System.currentTimeMillis();
        Long lastRequestTime = requestTimestamps.get(request.getTarget());

        if (lastRequestTime != null && (currentTime - lastRequestTime) < SEND_COOLDOWN_MS) { // 60 seconds cooldown
            throw new ResponseStatusException(
                    HttpStatus.TOO_MANY_REQUESTS,
                    "Bạn thao tác quá nhanh, vui lòng đợi 1 phút trước khi yêu cầu lại mã OTP."
            );
        }

        // SEC9: Bảo vệ bộ nhớ — dọn target cũ trước khi thêm mới.
        if (requestTimestamps.size() >= MAX_TRACKED_TARGETS
                && !requestTimestamps.containsKey(request.getTarget())) {
            evictStaleTracking(currentTime);
            if (requestTimestamps.size() >= MAX_TRACKED_TARGETS) {
                log.warn("[OTP] Đã đạt giới hạn theo dõi {} target — từ chối yêu cầu mới.", MAX_TRACKED_TARGETS);
                throw new ResponseStatusException(
                        HttpStatus.TOO_MANY_REQUESTS,
                        "Hệ thống đang quá tải, vui lòng thử lại sau."
                );
            }
        }

        requestTimestamps.put(request.getTarget(), currentTime);

        if (request.getType() == Otp.OtpType.register) {

            if (request.getChannel() == Otp.Channel.email) {

                if (userRepository.existsByEmail(request.getTarget())) {
                    throw new ResponseStatusException(
                            HttpStatus.CONFLICT,
                            "Email này đã được sử dụng"
                    );
                }

            } else {

                if (userRepository.existsByPhoneNumber(request.getTarget())) {
                    throw new ResponseStatusException(
                            HttpStatus.CONFLICT,
                            "Số điện thoại này đã được sử dụng"
                    );
                }
            }
        }

        String code = generateCode();

        otpRepository.save(
                Otp.builder()
                        .target(request.getTarget())
                        .channel(request.getChannel())
                        .type(request.getType())
                        .code(code)
                        .expiresAt(
                                LocalDateTime.now()
                                        .plusMinutes(OTP_EXPIRY_MINUTES)
                        )
                        .build()
        );

        log.info(
                "[OTP] channel={} target={}*** sent",
                request.getChannel(),
                request.getTarget()
                        .substring(
                                0,
                                Math.min(
                                        4,
                                        request.getTarget().length()
                                )
                        )
        );

        if (request.getChannel() == Otp.Channel.email) {
            String subject = "Mã Xác Nhận (OTP) - StayHub";
            String htmlTemplate = """
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Xác thực tài khoản StayHub</title>
</head>
<body style="font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; -webkit-font-smoothing: antialiased;">
    <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%%" style="background-color: #f4f7f6; padding: 40px 10px;">
        <tr>
            <td align="center">
                <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%%" style="max-width: 500px; background-color: #ffffff; border-radius: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.05); overflow: hidden;">
                    
                    <!-- Header with Logo -->
                    <tr>
                        <td align="center" style="background: #0084FF; padding: 40px 20px; text-align: center;">
                            <!-- TODO: Thay url_logo_cua_ban bang link anh that cua StayHub (anh phai duoc up len host online) -->
                            <img src="https://via.placeholder.com/150x50/0084FF/FFFFFF?text=StayHub+Logo" alt="StayHub Logo" height="50" style="display: block; margin: 0 auto; margin-bottom: 15px; border-radius: 8px;">
                            <span style="font-size: 28px; font-weight: 800; color: #ffffff; letter-spacing: -0.5px;">Stay<span style="color: #e0f2fe;">Hub</span></span>
                            <p style="margin: 8px 0 0 0; color: #e0f2fe; font-size: 14px; font-weight: 500;">Chạm nhẹ không gian • Trọn an tâm bước</p>
                        </td>
                    </tr>
                    
                    <!-- Body -->
                    <tr>
                        <td style="padding: 40px 40px 30px 40px;">
                            <h2 style="margin: 0 0 16px 0; font-size: 22px; font-weight: 700; color: #1e293b; text-align: center;">Xác thực tài khoản</h2>
                            <p style="margin: 0 0 32px 0; font-size: 15px; line-height: 1.6; color: #475569; text-align: center;">
                                Chào mừng bạn đến với StayHub! Vui lòng sử dụng mã OTP dưới đây để hoàn tất việc xác thực tài khoản.
                            </p>
                            
                            <!-- OTP Box -->
                            <div style="background-color: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 24px; text-align: center; margin-bottom: 32px;">
                                <div style="font-size: 12px; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 8px;">Mã xác thực của bạn</div>
                                <div style="font-size: 42px; font-weight: 800; color: #0084FF; letter-spacing: 6px; margin: 0; font-family: monospace;">%s</div>
                            </div>

                            <!-- Warning -->
                            <div style="background-color: #fff1f2; border-left: 4px solid #e11d48; border-radius: 4px; padding: 12px 16px; margin-bottom: 20px;">
                                <p style="margin: 0; font-size: 13px; color: #be123c; line-height: 1.5;">
                                    <strong>Lưu ý bảo mật:</strong> Tuyệt đối không chia sẻ mã này. Mã chỉ có hiệu lực trong vòng <strong>%d phút</strong>.
                                </p>
                            </div>
                        </td>
                    </tr>

                    <!-- Footer -->
                    <tr>
                        <td style="background-color: #f8fafc; padding: 24px 40px; border-top: 1px solid #e2e8f0; text-align: center;">
                            <p style="margin: 0 0 8px 0; font-size: 13px; color: #64748b; line-height: 1.5;">
                                Nếu bạn không yêu cầu mã này, vui lòng bỏ qua email.
                            </p>
                            <p style="margin: 0; font-size: 12px; font-weight: 600; color: #94a3b8;">© 2026 StayHub Platform</p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
                """.formatted(code, OTP_EXPIRY_MINUTES);
                
                
            emailService.sendHtmlEmail(request.getTarget(), subject, htmlTemplate);
        }

        SendOtpResponse.SendOtpResponseBuilder builder =
                SendOtpResponse.builder()
                        .success(true)
                        .message(
                                "Mã OTP đã được gửi đến "
                                        + (request.getChannel() == Otp.Channel.email
                                        ? "email"
                                        : "số điện thoại")
                                        + " của bạn"
                        );

        if (!"production".equals(activeProfile)) {
            builder.devOtp(code);
        }

        return builder.build();
    }

    public Otp verifyAndMarkUsed(
            String target,
            String code,
            Otp.OtpType type) {

        long now = System.currentTimeMillis();

        // SEC9: Chặn brute-force — nếu target đang bị tạm khoá thì từ chối ngay.
        Long lockUntil = verifyLockUntil.get(target);
        if (lockUntil != null) {
            if (now < lockUntil) {
                long remainingSec = (lockUntil - now) / 1000;
                throw new ResponseStatusException(
                        HttpStatus.TOO_MANY_REQUESTS,
                        "Bạn đã nhập sai quá nhiều lần. Vui lòng thử lại sau "
                                + (remainingSec / 60 + 1) + " phút."
                );
            }
            // Hết thời gian khoá → reset.
            verifyLockUntil.remove(target);
            verifyAttempts.remove(target);
        }

        Otp otp = otpRepository.findValidOtp(
                        target,
                        code,
                        type,
                        LocalDateTime.now())
                .orElseThrow(() -> {
                    // Ghi nhận 1 lần sai; vượt ngưỡng → tạm khoá target.
                    int[] counter = verifyAttempts.computeIfAbsent(target, k -> new int[]{0});
                    int attempts;
                    synchronized (counter) {
                        counter[0]++;
                        attempts = counter[0];
                    }
                    if (attempts >= MAX_VERIFY_ATTEMPTS) {
                        verifyLockUntil.put(target, System.currentTimeMillis() + VERIFY_LOCKOUT_MS);
                        verifyAttempts.remove(target);
                        log.warn("[OTP] Target {} bị tạm khoá do nhập sai {} lần.", maskTarget(target), attempts);
                    }
                    return new ResponseStatusException(
                            HttpStatus.BAD_REQUEST,
                            "Mã OTP không hợp lệ hoặc đã hết hạn"
                    );
                });

        // Xác thực thành công → xoá bộ đếm sai.
        verifyAttempts.remove(target);
        verifyLockUntil.remove(target);

        otp.setUsedAt(LocalDateTime.now());

        return otpRepository.save(otp);
    }

    /** Dọn các target không hoạt động quá 30 phút để giải phóng bộ nhớ (SEC9). */
    private void evictStaleTracking(long now) {
        long staleThreshold = 30 * 60 * 1000L;
        requestTimestamps.entrySet().removeIf(e -> (now - e.getValue()) > staleThreshold);
        verifyLockUntil.entrySet().removeIf(e -> now > e.getValue());
    }

    /** Che bớt target khi ghi log (bảo vệ PII). */
    private String maskTarget(String target) {
        if (target == null || target.length() <= 4) {
            return "***";
        }
        return target.substring(0, 4) + "***";
    }

    public com.stayhub.api.dto.response.VerifyOtpResponse verifyOtpAndGetToken(
            com.stayhub.api.dto.request.VerifyOtpRequest request) {
        
        verifyAndMarkUsed(request.getTarget(), request.getCode(), request.getType());
        
        String token = jwtUtil.generateRegistrationToken(request.getTarget());
        
        return com.stayhub.api.dto.response.VerifyOtpResponse.builder()
                .success(true)
                .message("Xác thực OTP thành công")
                .registrationToken(token)
                .build();
    }

    private String generateCode() {
        return String.format(
                "%06d",
                SECURE_RANDOM.nextInt(1_000_000)
        );
    }
}