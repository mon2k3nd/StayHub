package com.stayhub.api.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

import java.io.IOException;
import java.util.concurrent.ConcurrentHashMap;

@Service
@Slf4j
public class WebSocketSessionManager {

    private final ConcurrentHashMap<Long, WebSocketSession> sessions = new ConcurrentHashMap<>();

    public void registerSession(Long userId, WebSocketSession session) {
        sessions.put(userId, session);
        log.info("Registered WS session for user ID: {}", userId);
    }

    public void removeSession(Long userId) {
        sessions.remove(userId);
        log.info("Removed WS session for user ID: {}", userId);
    }

    public void sendEvent(Long userId, String payload) {
        WebSocketSession session = sessions.get(userId);
        if (session != null && session.isOpen()) {
            try {
                session.sendMessage(new TextMessage(payload));
                log.info("Sent WS event to user ID {}: {}", userId, payload);
            } catch (IOException e) {
                log.error("Error sending WS event to user ID {}: {}", userId, e.getMessage());
            }
        } else {
            log.info("WS session for user ID {} is not active or not found.", userId);
        }
    }

    /** Gửi broadcast đến tất cả user đang kết nối WS */
    public void broadcastAll(String payload) {
        sessions.values().forEach(session -> {
            if (session.isOpen()) {
                try {
                    session.sendMessage(new TextMessage(payload));
                } catch (IOException e) {
                    log.error("Broadcast error: {}", e.getMessage());
                }
            }
        });
    }
}
