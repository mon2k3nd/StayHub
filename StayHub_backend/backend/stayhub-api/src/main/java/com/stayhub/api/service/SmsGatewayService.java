package com.stayhub.api.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Service
@Slf4j
public class SmsGatewayService {

    public void sendSms(String phoneNumber, String message) {
        log.info("--------------------------------------------------");
        log.info("[SMS GATEWAY] Sending SMS to: {}", phoneNumber);
        log.info("[SMS GATEWAY] Message: {}", message);
        log.info("--------------------------------------------------");
    }
}
