package com.stayhub.api.service.notification;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

@Component
@Slf4j
public class SmsZaloProvider {

    public void sendSms(String phoneNumber, String message) {
        // Mock gửi SMS
        log.info(">>>> [SMS Provider] Gửi tin nhắn tới SĐT {}: {}", phoneNumber, message);
    }

    public void sendZaloMessage(String phoneNumber, String message) {
        // Mock gửi Zalo ZNS
        log.info(">>>> [Zalo Provider] Gửi ZNS tới SĐT {}: {}", phoneNumber, message);
    }
}
