package com.stayhub.api.service;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * Service gửi Push Notification đến thiết bị cụ thể qua FCM.
 * Sử dụng firebase-admin SDK.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PushNotificationService {

    /**
     * Gửi thông báo đến một thiết bị cụ thể (qua fcmToken).
     *
     * @param fcmToken FCM device token của người nhận
     * @param title    Tiêu đề thông báo
     * @param body     Nội dung thông báo
     * @param data     Dữ liệu bổ sung (key-value) để app xử lý điều hướng
     */
    public void sendToDevice(String fcmToken, String title, String body, java.util.Map<String, String> data) {
        if (fcmToken == null || fcmToken.isBlank()) {
            log.warn("FCM token is null or blank, skipping push notification for title: {}", title);
            return;
        }

        try {
            Message.Builder builder = Message.builder()
                    .setToken(fcmToken)
                    .setNotification(Notification.builder()
                            .setTitle(title)
                            .setBody(body)
                            .build());

            if (data != null && !data.isEmpty()) {
                builder.putAllData(data);
            }

            String response = FirebaseMessaging.getInstance().send(builder.build());
            log.info("FCM notification sent successfully to token [{}...], response: {}", 
                     fcmToken.substring(0, Math.min(20, fcmToken.length())), response);
        } catch (Exception e) {
            log.error("Failed to send FCM notification: {}", e.getMessage());
        }
    }

    /**
     * Shorthand: gửi thông báo đơn giản không có data.
     */
    public void sendToDevice(String fcmToken, String title, String body) {
        sendToDevice(fcmToken, title, body, null);
    }
}
